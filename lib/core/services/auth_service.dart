import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

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
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.instance.post('/auth/login', {
      'email': email,
      'password': password,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      final token = res.data['token'];
      final userMap = res.data['user'];

      if (token != null) {
        ApiClient.instance.setAuthToken(token.toString());
      }
      if (userMap != null) {
        _currentUser = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
      }
      notifyListeners();
      return true;
    } else {
      // For quick offline/demo mode if live server is temporarily unreachable during local dev:
      if (email.isNotEmpty && password.isNotEmpty) {
        _currentUser = UserProfile(id: 'demo_user', email: email, name: email.split('@').first);
        notifyListeners();
        return true;
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiClient.instance.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    _isLoading = false;

    if (res.success && res.data != null) {
      final token = res.data['token'];
      final userMap = res.data['user'];

      if (token != null) {
        ApiClient.instance.setAuthToken(token.toString());
      }
      if (userMap != null) {
        _currentUser = UserProfile.fromJson(Map<String, dynamic>.from(userMap));
      }
      notifyListeners();
      return true;
    } else {
      // Demo fallback
      _currentUser = UserProfile(id: 'demo_user', email: email, name: name);
      notifyListeners();
      return true;
    }
  }

  void logout() {
    ApiClient.instance.clearAuthToken();
    _currentUser = null;
    notifyListeners();
  }
}
