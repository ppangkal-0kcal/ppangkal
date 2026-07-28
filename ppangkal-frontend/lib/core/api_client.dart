import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Thin HTTP wrapper enforcing the backend's response contract
/// (FRONTEND_API_GUIDE.md §0/§5): unwrapped snake_case JSON on success,
/// `{ error: { code, message } }` on failure. Callers get back the decoded
/// success body directly, or an [ApiException] thrown for any 4xx/5xx.
class ApiClient {
  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    String? token,
  }) {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    return _send(() => _http.get(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    final uri = Uri.parse('$apiBaseUrl$path');
    return _send(
      () => _http.post(uri, headers: _headers(token), body: jsonEncode(body ?? {})),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    final uri = Uri.parse('$apiBaseUrl$path');
    return _send(
      () => _http.patch(uri, headers: _headers(token), body: jsonEncode(body ?? {})),
    );
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    final decoded = response.bodyBytes.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw ApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
      );
    }
    return decoded;
  }
}
