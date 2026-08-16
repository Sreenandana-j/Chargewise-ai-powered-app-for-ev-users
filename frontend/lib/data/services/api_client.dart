import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_service.dart';

/// Thrown for known, user-displayable API errors (HTTP 4xx with a detail message).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Central HTTP client for all backend calls.
///
/// Works across Web (Chrome), Desktop (Windows), and Mobile (Android/iOS).
/// Does not depend on `dart:io` so Web builds execute without runtime errors.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Dynamic base URL:
  /// - Web / Windows Desktop: `http://127.0.0.1:8000`
  /// - Android Emulator: `http://10.0.2.2:8000`
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const Duration _timeout = Duration(seconds: 20);

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await SessionService.instance.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _parseBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  List<dynamic> _parseListBody(http.Response response) {
    return jsonDecode(response.body) as List<dynamic>;
  }

  void _checkForErrors(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String detail = 'Unexpected error (${response.statusCode})';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = (body['detail'] ?? body['message'] ?? detail).toString();
    } catch (_) {}

    throw ApiException(detail, statusCode: response.statusCode);
  }

  // ── HTTP Methods ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    _checkForErrors(response);
    return _parseBody(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    _checkForErrors(response);
    return _parseListBody(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final response = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    _checkForErrors(response);
    return _parseBody(response);
  }
}
