import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

class SettingsLocalDataSource {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  Map<String, dynamic>? _session;
  Future<void> Function(String)? onServerChanged;
  SettingsLocalDataSource(this._prefs, {FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();
  static Future<SettingsLocalDataSource> create() async {
    final result = SettingsLocalDataSource(
      await SharedPreferences.getInstance(),
    );
    await result.initialize();
    return result;
  }

  Future<void> initialize() async {
    final encoded = await _secureStorage.read(key: 'auth_session');
    if (encoded != null) {
      try {
        final candidate = jsonDecode(encoded) as Map<String, dynamic>;
        if (candidate['token'] is! String ||
            candidate['userId'] is! int ||
            candidate['username'] is! String ||
            candidate['email'] is! String) {
          throw const FormatException('Invalid session');
        }
        _session = candidate;
      } catch (_) {
        await _secureStorage.delete(key: 'auth_session');
      }
    } else {
      final token =
          await _secureStorage.read(key: 'auth_token') ??
          _prefs.getString('auth_token');
      final userId = _prefs.getInt('auth_user_id');
      final username = _prefs.getString('auth_username');
      final email = _prefs.getString('auth_email');
      if (token != null &&
          userId != null &&
          username != null &&
          email != null) {
        await saveAuthData(
          token: token,
          userId: userId,
          username: username,
          email: email,
        );
      }
    }
    await _secureStorage.delete(key: 'auth_token');
    await _clearLegacyAuth();
  }

  Future<void> _clearLegacyAuth() async {
    for (final key in [
      'auth_token',
      'auth_user_id',
      'auth_username',
      'auth_email',
    ]) {
      await _prefs.remove(key);
    }
  }

  String getDefaultNoteStatus() {
    final status = _prefs.getString('default_note_status');
    return ['DRAFT', 'IN_PROGRESS', 'COMPLETED', 'PENDING'].contains(status)
        ? status!
        : 'DRAFT';
  }

  Future<void> setDefaultNoteStatus(String status) async {
    if (!['DRAFT', 'IN_PROGRESS', 'COMPLETED', 'PENDING'].contains(status)) {
      throw ArgumentError('Invalid status');
    }
    await _prefs.setString('default_note_status', status);
  }

  String getBaseUrl() {
    final saved = _prefs.getString('base_url');
    if (saved != null && saved.isNotEmpty) {
      if (kIsWeb &&
          (saved.contains('localhost') ||
              saved.contains('127.0.0.1') ||
              saved.contains('vercel.app'))) {
        return ApiConstants.defaultBaseUrl;
      }
      return saved;
    }
    return (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? ApiConstants.emulatorBaseUrl
        : ApiConstants.defaultBaseUrl;
  }
  Future<void> setBaseUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw ArgumentError(
        'Use a server origin, such as https://notes.example.com, without /api',
      );
    }
    if (url != getBaseUrl() && getUserId() != null) {
      throw StateError('Sign out before changing servers');
    }
    final normalized = uri.origin;
    await onServerChanged?.call(normalized);
    await _prefs.setString('base_url', normalized);
  }

  String? getToken() => _session?['token'] as String?;
  int? getUserId() => _session?['userId'] as int?;
  int requireUserId() =>
      getUserId() ?? (throw StateError('Sign in to access records'));
  String get accountKey => '${getBaseUrl()}|${requireUserId()}';
  String? getUsername() => _session?['username'] as String?;
  String? getEmail() => _session?['email'] as String?;
  Future<void> saveAuthData({
    required String token,
    required int userId,
    required String username,
    required String email,
  }) async {
    final next = <String, dynamic>{
      'token': token,
      'userId': userId,
      'username': username,
      'email': email,
    };
    // One secure write and one in-memory assignment: token and identity never diverge.
    await _secureStorage.write(key: 'auth_session', value: jsonEncode(next));
    _session = next;
    await _clearLegacyAuth();
  }

  Future<void> clearAuthData() async {
    _session = null;
    await _secureStorage.delete(key: 'auth_session');
    await _secureStorage.delete(key: 'auth_token');
    await _clearLegacyAuth();
  }

  int getLastSyncTime() => _prefs.getInt('sync_$accountKey') ?? 0;
  Future<void> setLastSyncTime(int timestamp) async =>
      _prefs.setInt('sync_$accountKey', timestamp);
}
