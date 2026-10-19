import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ReCircleApi {
  ReCircleApi({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'recircle_access_token';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _configuredBaseUrl.trim().isNotEmpty
      ? _configuredBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '')
      : (kDebugMode ? 'http://10.0.2.2:3000/api/v1' : '');

  static String? get configurationError {
    final value = baseUrl;
    if (value.isEmpty) {
      return 'Production API URL is missing. Build with '
          '--dart-define=API_BASE_URL=https://your-api-host/api/v1.';
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return 'API_BASE_URL must be a valid API URL ending in /api/v1.';
    }
    if (uri.path.replaceFirst(RegExp(r'/+$'), '') != '/api/v1') {
      return 'API_BASE_URL must end in /api/v1.';
    }
    final host = uri.host.toLowerCase();
    final privateIpv4 =
        RegExp(r'^(10\.|127\.|192\.168\.|169\.254\.)').hasMatch(host) ||
        RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(host);
    if (kReleaseMode &&
        (host == 'localhost' ||
            host.endsWith('.localhost') ||
            host == '::1' ||
            host == '0.0.0.0' ||
            privateIpv4)) {
      return 'Release API_BASE_URL must use a publicly reachable host, not '
          'localhost or a private network address.';
    }
    if (kReleaseMode && uri.scheme != 'https') {
      return 'Release builds require an HTTPS API_BASE_URL.';
    }
    if (!kReleaseMode && !{'http', 'https'}.contains(uri.scheme)) {
      return 'API_BASE_URL must use HTTP or HTTPS.';
    }
    return null;
  }
  String? _token;
  bool get hasSessionToken => _token != null;

  Future<void> restoreToken() async =>
      _token = await _storage.read(key: _tokenKey);
  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body);

  Future<dynamic> getAnalysisHistory({int page = 1, int limit = 20}) =>
      get('/analysis/history?page=$page&limit=$limit');

  Future<dynamic> getAnalysisDetail(String id) =>
      get('/analysis/history/${Uri.encodeComponent(id)}');

  Future<dynamic> analyzeImage({
    required Uint8List image,
    required String mimeType,
    String? manualCategory,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': mimeType,
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    if (manualCategory != null) {
      headers['X-ReCircle-Category'] = manualCategory;
    }
    try {
      final request = http.Request('POST', Uri.parse('${baseUrl}/analysis'))
        ..headers.addAll(headers)
        ..bodyBytes = image;
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 40));
      return await _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        'Image analysis timed out. Check the connection and retry.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach ReCircle server. Check the API address and network.',
      );
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('${baseUrl}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 15));
      return await _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Check the connection and retry.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach ReCircle server. Check the API address and network.',
      );
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }

  Future<dynamic> _decodeResponse(http.Response response) async {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 401) await clearToken();
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] != true) {
      final error = decoded['error'];
      throw ApiException(
        error is Map
            ? '${error['message'] ?? 'Request failed'}'
            : 'Request failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return decoded['data'] ?? decoded;
  }

  Future<dynamic> register(String name, String email, String password) => post(
    '/auth/register',
    {'name': name, 'email': email, 'password': password},
  );
  Future<dynamic> login(String email, String password) =>
      post('/auth/login', {'email': email, 'password': password});
}
