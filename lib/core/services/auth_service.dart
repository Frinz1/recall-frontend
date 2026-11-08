import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'study_repository.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}

class AuthResult {
  final bool success;
  final String message;
  final bool deliveredViaSmtp;
  final bool requiresOtpVerification;
  final String? pendingEmail;

  const AuthResult({
    required this.success,
    required this.message,
    this.deliveredViaSmtp = false,
    this.requiresOtpVerification = false,
    this.pendingEmail,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String _tokenKey = 'recall_access_token_v1';
  static const String _refreshTokenKey = 'recall_refresh_token_v1';
  static const String _userKey = 'recall_user_profile_v1';
  static const String _onboardingKey = 'recall_has_seen_onboarding_v1';

  UserProfile? _currentUser;
  String? _refreshToken;
  bool _hasSeenOnboarding = false;
  bool _isLoading = false;
  String? _lastErrorMessage;

  UserProfile? get currentUser => _currentUser;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _currentUser != null && ApiClient.instance.isAuthenticated;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLoading => _isLoading;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Restores persisted session tokens, user profile, onboarding state, and cached study data on startup.
  Future<void> initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

      final savedToken = prefs.getString(_tokenKey);
      final savedRefresh = prefs.getString(_refreshTokenKey);
      final savedUserJson = prefs.getString(_userKey);

      if (savedToken != null &&
          savedToken.isNotEmpty &&
          savedUserJson != null &&
          savedUserJson.isNotEmpty) {
        final decoded = jsonDecode(savedUserJson);
        if (decoded is Map) {
          ApiClient.instance.setAuthToken(savedToken);
          _refreshToken = savedRefresh;
          _currentUser = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
          await StudyRepository.instance.loadFromCache(userId: _currentUser!.id);
          notifyListeners();

          // Sync fresh profile & decks from cloud in the background
          _verifyAndSyncBackground();
        }
      }
    } catch (_) {}
  }

  Future<void> _verifyAndSyncBackground() async {
    final meRes = await ApiClient.instance.get('/auth/me');
    if (meRes.success && meRes.data is Map) {
      final updatedUser = UserProfile.fromJson(Map<String, dynamic>.from(meRes.data as Map));
      _currentUser = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      await StudyRepository.instance.fetchAllFromCloud();
      notifyListeners();
    } else if (meRes.statusCode == 401 && _refreshToken != null) {
      final refreshRes = await ApiClient.instance.post('/auth/refresh', {
        'rc_rt': _refreshToken,
      });
      if (refreshRes.success && refreshRes.data is Map) {
        final newToken = (refreshRes.data as Map)['rc_at']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          ApiClient.instance.setAuthToken(newToken);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
          await StudyRepository.instance.fetchAllFromCloud();
          notifyListeners();
          return;
        }
      }
      // If refresh token is also expired/revoked, log out cleanly
      await logout();
    } else {
      await StudyRepository.instance.fetchAllFromCloud();
    }
  }

  Future<void> markOnboardingCompleted() async {
    _hasSeenOnboarding = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persistAuthSession({
    required String accessToken,
    required String? refreshToken,
    required UserProfile user,
  }) async {
    ApiClient.instance.setAuthToken(accessToken);
    _refreshToken = refreshToken;
    _currentUser = user;
    _hasSeenOnboarding = true;
    StudyRepository.instance.setActiveUser(user.id);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {}
  }

  Future<AuthResult> loginWithDetails({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    final res = await ApiClient.instance.post('/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    _isLoading = false;

    if (res.success && res.data is Map) {
      final dataMap = Map<String, dynamic>.from(res.data as Map);
      final token = dataMap['rc_at']?.toString() ?? dataMap['token']?.toString();
      final rt = dataMap['rc_rt']?.toString() ?? dataMap['refreshToken']?.toString();
      final userMap = dataMap['user'];

      if (token != null && userMap is Map) {
        final user = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
        await _persistAuthSession(
          accessToken: token,
          refreshToken: rt,
          user: user,
        );
        await StudyRepository.instance.fetchAllFromCloud();
        notifyListeners();
        return AuthResult(
          success: true,
          message: res.message ?? 'Welcome back, ${user.name}!',
        );
      }
    }

    final errorMsg = res.message ?? 'Invalid email or password.';
    _lastErrorMessage = errorMsg;
    notifyListeners();
    return AuthResult(success: false, message: errorMsg);
  }

  Future<bool> login({required String email, required String password}) async {
    final result = await loginWithDetails(email: email, password: password);
    return result.success;
  }

  Future<AuthResult> requestRegistrationOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    final res = await ApiClient.instance.post('/auth/register/request-otp', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    _isLoading = false;

    if (res.success) {
      bool deliveredViaSmtp = false;
      if (res.data is Map) {
        final dataMap = Map<String, dynamic>.from(res.data as Map);
        deliveredViaSmtp = dataMap['deliveredViaSmtp'] == true;
      }
      notifyListeners();
      return AuthResult(
        success: true,
        message: res.message ?? 'Verification code sent to your email.',
        deliveredViaSmtp: deliveredViaSmtp,
        requiresOtpVerification: true,
        pendingEmail: email.trim().toLowerCase(),
      );
    }

    final errorMsg = res.message ?? 'Failed to request verification code.';
    _lastErrorMessage = errorMsg;
    notifyListeners();
    return AuthResult(success: false, message: errorMsg);
  }

  Future<AuthResult> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    final res = await ApiClient.instance.post('/auth/register/verify-otp', {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    });

    _isLoading = false;

    if (res.success && res.data is Map) {
      final dataMap = Map<String, dynamic>.from(res.data as Map);
      final token = dataMap['rc_at']?.toString() ?? dataMap['token']?.toString();
      final rt = dataMap['rc_rt']?.toString() ?? dataMap['refreshToken']?.toString();
      final userMap = dataMap['user'];

      if (token != null && userMap is Map) {
        final user = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
        await _persistAuthSession(
          accessToken: token,
          refreshToken: rt,
          user: user,
        );
        await StudyRepository.instance.fetchAllFromCloud();
        notifyListeners();
        return AuthResult(
          success: true,
          message: res.message ?? 'Email verified and account created!',
        );
      }
    }

    final errorMsg = res.message ?? 'Invalid or expired verification code.';
    _lastErrorMessage = errorMsg;
    notifyListeners();
    return AuthResult(success: false, message: errorMsg);
  }

  static String _formatDisplayNameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart
        .replaceAll(RegExp(r'[._\-]+'), ' ')
        .replaceAll(RegExp(r'\d+'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .toList();
    if (words.isEmpty) {
      return localPart.isNotEmpty
          ? localPart[0].toUpperCase() + localPart.substring(1)
          : 'Recall Scholar';
    }
    return words.join(' ');
  }

  Future<AuthResult> signInWithGoogle({
    bool isLogin = true,
  }) async {
    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    String? googleEmail;
    String? googleName;
    String? googleId;

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut().catchError((_) => null);
      final account = await googleSignIn.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return const AuthResult(
          success: false,
          message: 'Google Sign-In was cancelled.',
        );
      }
      googleEmail = account.email.trim().toLowerCase();
      googleName = account.displayName?.trim().isNotEmpty == true
          ? account.displayName!.trim()
          : _formatDisplayNameFromEmail(account.email);
      googleId = account.id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return const AuthResult(
        success: false,
        message:
            'Google Sign-In requires your Android OAuth Client ID (SHA-1) to be registered in Google Cloud Console.',
      );
    }

    final res = await ApiClient.instance.post('/auth/google', {
      'email': googleEmail,
      'name': googleName,
      'mode': isLogin ? 'login' : 'register',
      'googleId': googleId,
    });

    _isLoading = false;

    if (res.success && res.data is Map) {
      final dataMap = Map<String, dynamic>.from(res.data as Map);

      if (dataMap['requiresOtp'] == true) {
        notifyListeners();
        return AuthResult(
          success: true,
          message: res.message ?? 'Verification code sent to $googleEmail.',
          requiresOtpVerification: true,
          pendingEmail: googleEmail,
          deliveredViaSmtp: dataMap['deliveredViaSmtp'] == true,
        );
      }

      final token = dataMap['rc_at']?.toString();
      final rt = dataMap['rc_rt']?.toString();
      final userMap = dataMap['user'];

      if (token != null && userMap is Map) {
        final user = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
        await _persistAuthSession(
          accessToken: token,
          refreshToken: rt,
          user: user,
        );
        await StudyRepository.instance.fetchAllFromCloud();
        notifyListeners();
        return AuthResult(
          success: true,
          message: 'Signed in as ${user.email}',
        );
      }
    }

    final errorMsg = res.message ?? 'Google Sign-In failed. Please try again.';
    _lastErrorMessage = errorMsg;
    notifyListeners();
    return AuthResult(success: false, message: errorMsg);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    final res = await ApiClient.instance.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    _isLoading = false;

    if (res.success && res.data is Map) {
      final dataMap = Map<String, dynamic>.from(res.data as Map);
      final token = dataMap['rc_at']?.toString() ?? dataMap['token']?.toString();
      final rt = dataMap['rc_rt']?.toString() ?? dataMap['refreshToken']?.toString();
      final userMap = dataMap['user'];

      if (token != null && userMap is Map) {
        final user = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
        await _persistAuthSession(
          accessToken: token,
          refreshToken: rt,
          user: user,
        );
        await StudyRepository.instance.fetchAllFromCloud();
        notifyListeners();
        return true;
      }
    }

    _lastErrorMessage = res.message ?? 'Registration failed.';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await ApiClient.instance.post('/auth/logout', {'rc_rt': _refreshToken});
      } catch (_) {}
    }
    ApiClient.instance.clearAuthToken();
    _currentUser = null;
    _refreshToken = null;
    _lastErrorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}

    await StudyRepository.instance.clearLocalState();
    notifyListeners();
  }

  Future<bool> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.length < 2 || _currentUser == null) return false;

    final updatedLocal = UserProfile(
      id: _currentUser!.id,
      email: _currentUser!.email,
      name: trimmed,
    );
    _currentUser = updatedLocal;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedLocal.toJson()));
    } catch (_) {}

    if (ApiClient.instance.isAuthenticated) {
      final res = await ApiClient.instance.patch('/auth/profile', {'name': trimmed});
      return res.success;
    }
    return true;
  }
}
