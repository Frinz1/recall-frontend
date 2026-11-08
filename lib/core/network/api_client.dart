import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  String? _authToken;

  String? get authToken => _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  bool get isAuthenticated => _authToken != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<ApiResponse<dynamic>> get(String path) async {
    return _send('GET', path);
  }

  Future<ApiResponse<dynamic>> post(String path, Map<String, dynamic> body) async {
    return _send('POST', path, body);
  }

  Future<ApiResponse<dynamic>> patch(String path, Map<String, dynamic> body) async {
    return _send('PATCH', path, body);
  }

  Future<ApiResponse<dynamic>> delete(String path) async {
    return _send('DELETE', path);
  }

  Future<ApiResponse<dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final url = Uri.parse('${EnvConfig.baseUrl}$path');

    try {
      http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;
      const timeoutDuration = Duration(seconds: 15);

      switch (method) {
        case 'POST':
          response = await http
              .post(url, headers: _headers, body: encodedBody)
              .timeout(timeoutDuration);
          break;
        case 'PATCH':
          response = await http
              .patch(url, headers: _headers, body: encodedBody)
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: _headers)
              .timeout(timeoutDuration);
          break;
        case 'GET':
        default:
          response = await http
              .get(url, headers: _headers)
              .timeout(timeoutDuration);
          break;
      }

      final statusCode = response.statusCode;
      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = {'message': response.body};
      }

      if (statusCode >= 200 && statusCode < 300) {
        final msg = decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : null;
        return ApiResponse(
          success: true,
          message: msg,
          data: decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded,
          statusCode: statusCode,
        );
      } else {
        String message = 'Server error ($statusCode)';
        if (decoded is Map) {
          if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
            message = decoded['message'].toString();
          } else if (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
            final firstError = (decoded['errors'] as List).first;
            if (firstError is Map && firstError['message'] != null) {
              message = firstError['message'].toString();
            }
          }
        }
        return ApiResponse(
          success: false,
          message: message,
          statusCode: statusCode,
        );
      }
    } catch (e) {
      return const ApiResponse(
        success: false,
        message: 'Unable to reach cloud server. Please check your internet connection.',
        statusCode: 0,
      );
    }
  }
}
