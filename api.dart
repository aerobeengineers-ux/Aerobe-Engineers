import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'session.dart';

class ApiException implements Exception {
  ApiException(this.message, this.status);
  final String message;
  final int status;

  @override
  String toString() => message;
}

/// Thin wrapper around the website API. Every call adds the login token.
class Api {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (session.token != null) 'Authorization': 'Bearer ${session.token}',
      };

  static Map<String, String> get authHeaders =>
      {'Authorization': 'Bearer ${session.token ?? ''}'};

  static String photoUrl(int employeeId) => '$apiBase/employees/$employeeId/photo';

  static Future<http.Response> _request(String method, Uri uri, String? body) {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: _headers);
      case 'POST':
        return http.post(uri, headers: _headers, body: body);
      case 'PUT':
        return http.put(uri, headers: _headers, body: body);
      case 'DELETE':
        return http.delete(uri, headers: _headers);
      default:
        throw ArgumentError('Unknown method $method');
    }
  }

  static dynamic _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    final dynamic data = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (res.statusCode == 401 && session.token != null) {
      session.clear(); // token expired or revoked: back to the login screen
    }
    if (res.statusCode >= 400) {
      final message = (data is Map && data['error'] is String)
          ? data['error'] as String
          : 'Something went wrong (${res.statusCode}).';
      throw ApiException(message, res.statusCode);
    }
    return data;
  }

  static Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final http.Response res;
    try {
      res = await _request(method, Uri.parse('$apiBase$path'), body == null ? null : jsonEncode(body));
    } on ArgumentError {
      rethrow;
    } catch (_) {
      throw ApiException('No connection. Check your internet and try again.', 0);
    }
    return _decode(res);
  }

  static Future<dynamic> get(String path) => _send('GET', path);
  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send('POST', path, body);
  static Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body);
  static Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Sends one file (screenshot or profile photo) as multipart form data.
  static Future<dynamic> upload(String path, String field, Uint8List bytes, String filename) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$apiBase$path'))
        ..headers.addAll(authHeaders)
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      final streamed = await req.send();
      return _decode(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Upload failed. Check your connection and try again.', 0);
    }
  }

  /// Logs in and returns the response. The caller decides whether to keep the session.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('/auth/login', {'email': email, 'password': password});
    return data as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout');
    } catch (_) {
      // Even if the server is unreachable, the phone forgets the login.
    }
    await session.clear();
  }
}
