import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin wrapper around package:http that every service in
/// lib/data/services uses. Centralizes auth-header injection, JSON
/// decoding, and consistent error surfacing so screens only ever deal
/// with real Dart objects or a thrown ApiException.
class ApiClient {
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('${AppConfig.apiBaseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {
      ...base.queryParameters,
      ...query.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final res = await http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data = {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        // Non-JSON body (e.g. an HTML error page from a proxy) — fall through.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    final message = data['error'] as String? ?? 'Something went wrong (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }
}
