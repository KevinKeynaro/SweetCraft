import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error API dengan pesan siap tampil dan error per-field dari backend.
/// Bentuk respons backend: { success, message, data }; validasi 400 berisi
/// data: [{ field, message }]. Sumber: docs/DESIGN.md §4.5.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

class ApiService {
  static const String _tokenKey = 'token';
  static const Duration _timeout = Duration(seconds: 15);

  /// Android fisik pada Wi-Fi lokal memakai IP host komputer (saat ini: 10.2.10.7).
  /// Override runtime dengan:
  /// flutter run --dart-define=API_BASE_URL=http://10.2.10.7:5000/api
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.2.10.7:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) {
    return _request(() async {
      return http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
      );
    });
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) {
    return _request(() async {
      return http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
    });
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) {
    return _request(() async {
      return http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
    });
  }

  static Future<dynamic> delete(String endpoint) {
    return _request(() async {
      return http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
      );
    });
  }

  static Future<dynamic> _request(Future<http.Response> Function() send) async {
    late final http.Response response;
    try {
      response = await send().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'Koneksi terlalu lama. Periksa internet lalu coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Koneksi terputus. Periksa internet lalu coba lagi.',
      );
    }

    final decoded = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded['data'] : null;
    }

    final body = decoded is Map<String, dynamic> ? decoded : const {};
    throw ApiException(
      body['message'] as String? ?? 'Terjadi kesalahan. Coba lagi.',
      statusCode: response.statusCode,
      fieldErrors: _readFieldErrors(body['data']),
    );
  }

  static dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static Map<String, String> _readFieldErrors(dynamic data) {
    if (data is! List) return const {};
    final errors = <String, String>{};
    for (final item in data) {
      if (item is Map && item['field'] is String && item['message'] is String) {
        errors[item['field'] as String] = item['message'] as String;
      }
    }
    return errors;
  }
}
