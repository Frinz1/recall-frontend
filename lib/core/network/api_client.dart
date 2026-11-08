import 'dart:convert';
import 'dart:io';
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

  Future<ApiResponse<dynamic>> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final url = Uri.parse('${EnvConfig.baseUrl}$path');
    final client = HttpClient();

    try {
      HttpClientRequest request;
      switch (method) {
        case 'POST':
          request = await client.postUrl(url);
          break;
        case 'PATCH':
          request = await client.patchUrl(url);
          break;
        case 'DELETE':
          request = await client.deleteUrl(url);
          break;
        case 'GET':
        default:
          request = await client.getUrl(url);
          break;
      }

      _headers.forEach((key, val) => request.headers.set(key, val));

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();
      final statusCode = response.statusCode;

      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {
        decoded = {'message': responseBody};
      }

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse(
          success: true,
          data: decoded is Map ? decoded['data'] : decoded,
          statusCode: statusCode,
        );
      } else {
        final message = decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Server error ($statusCode)';
        return ApiResponse(
          success: false,
          message: message,
          statusCode: statusCode,
        );
      }
    } on SocketException catch (_) {
      return const ApiResponse(
        success: false,
        message: 'Unable to reach cloud API. Please check your internet connection.',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
        statusCode: 0,
      );
    } finally {
      client.close();
    }
  }
}
