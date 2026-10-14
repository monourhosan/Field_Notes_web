import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../local/settings_local_data_source.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  void requireSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message = response.statusCode == 401
        ? "Session expired. Sign in again; offline changes are preserved."
        : "Server request failed (${response.statusCode})";
    try {
      final body = jsonDecode(response.body);
      message = body["message"] as String? ?? message;
      if (body["validationErrors"] is Map) {
        message = (body["validationErrors"] as Map).values.join("; ");
      }
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }

  void close() => _client.close();
  final SettingsLocalDataSource _settingsDataSource;
  final http.Client _client;

  ApiClient(this._settingsDataSource, [http.Client? client])
    : _client = client ?? http.Client();

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _settingsDataSource.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    var baseUrl = _settingsDataSource.getBaseUrl().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    if (kIsWeb &&
        (baseUrl.contains('localhost') ||
            baseUrl.contains('127.0.0.1') ||
            baseUrl.contains('vercel.app'))) {
      baseUrl = ApiConstants.defaultBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      )..removeWhere((key, value) => value.isEmpty);
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }
    return Uri.parse(fullUrl);
  }

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? ifNoneMatch,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return await _client
        .get(uri, headers: {..._buildHeaders(), 'If-None-Match': ?ifNoneMatch})
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> post(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    return await _client
        .post(uri, headers: _buildHeaders(), body: encodedBody)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> put(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    return await _client
        .put(uri, headers: _buildHeaders(), body: encodedBody)
        .timeout(const Duration(seconds: 30));
  }

  Future<http.Response> delete(String path) async {
    final uri = _buildUri(path);
    return await _client
        .delete(uri, headers: _buildHeaders())
        .timeout(const Duration(seconds: 20));
  }
}
