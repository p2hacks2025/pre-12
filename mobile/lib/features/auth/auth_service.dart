import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';
import 'models.dart';

class DummyAuthService {
  const DummyAuthService({http.Client? client, String? baseUrl})
    : _client = client,
      _baseUrl = baseUrl;

  final http.Client? _client;
  final String? _baseUrl;

  String get _effectiveBaseUrl => _baseUrl ?? backendBaseUrl;

  Future<DummyLoginResult> login(DummyUser user) async {
    // backendが未完成な間は、URL未指定なら成功扱いにする。
    if (_effectiveBaseUrl.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return DummyLoginResult(user: user);
    }

    final Uri uri;
    try {
      uri = Uri.parse(_effectiveBaseUrl).resolve('/login');
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
    }

    final client = _client ?? http.Client();
    try {
      final res = await client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(user.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('ログイン失敗: ${res.statusCode} ${res.body}');
      }

      return DummyLoginResult(user: user);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<LoginResult> loginWithEmailPassword(LoginRequest request) async {
    // backendが未完成な間は、URL未指定なら成功扱いにする。
    if (_effectiveBaseUrl.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return LoginResult(userId: request.email);
    }

    final Uri uri;
    try {
      uri = Uri.parse(_effectiveBaseUrl).resolve('/login');
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
    }

    final client = _client ?? http.Client();
    try {
      final res = await client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('ログイン失敗: ${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('ログインの応答が不正です');
      }

      return LoginResult.fromJson(decoded);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<SignUpResult> signUp(SignUpRequest request) async {
    // backendが未完成な間は、URL未指定なら成功扱いにする。
    if (_effectiveBaseUrl.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return SignUpResult(userId: request.username);
    }

    final Uri uri;
    try {
      uri = Uri.parse(_effectiveBaseUrl).resolve('/sign-up');
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
    }

    final client = _client ?? http.Client();
    try {
      final res = await client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('新規登録に失敗: ${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('新規登録の応答が不正です');
      }

      return SignUpResult.fromJson(decoded);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}
