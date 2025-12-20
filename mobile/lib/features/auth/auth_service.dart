import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config.dart';
import '../../uri_helpers.dart';
import 'models.dart';

class AuthService {
  const AuthService({http.Client? client, String? baseUrl})
    : _client = client,
      _baseUrl = baseUrl;

  final http.Client? _client;
  final String? _baseUrl;

  String get _effectiveBaseUrl => _baseUrl ?? backendBaseUrl;

  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    if (_effectiveBaseUrl.trim().isEmpty) {
      if (kDebugMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final displayName = _guessDisplayName(email);
        return AuthLoginResult(
          user: AuthUser(id: email, email: email, displayName: displayName),
        );
      }
      throw Exception('BACKEND_BASE_URL が未設定です');
    }

    final Uri uri;
    try {
      uri = joinBasePath(Uri.parse(_effectiveBaseUrl), '/login');
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
    }

    final client = _client ?? http.Client();
    try {
      final res = await client
          .post(
            uri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('ログイン失敗: ${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map || decoded['user_id'] is! String) {
        throw Exception('ログイン応答が不正です: ${res.body}');
      }
      final userId = decoded['user_id'] as String;
      return AuthLoginResult(
        user: AuthUser(
          id: userId,
          email: email,
          displayName: _guessDisplayName(email),
        ),
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<LoginResult> loginWithEmailPassword(LoginRequest request) async {
    if (_effectiveBaseUrl.trim().isEmpty) {
      if (kDebugMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return LoginResult(userId: request.email);
      }
      throw Exception('BACKEND_BASE_URL が未設定です');
    }

    final Uri uri;
    try {
      uri = joinBasePath(Uri.parse(_effectiveBaseUrl), '/login');
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
    if (_effectiveBaseUrl.trim().isEmpty) {
      if (kDebugMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return SignUpResult(userId: request.username);
      }
      throw SignUpException('BACKEND_BASE_URL が未設定です');
    }

    final Uri uri;
    try {
      uri = joinBasePath(Uri.parse(_effectiveBaseUrl), '/sign-up');
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
        final serverError = _extractErrorMessage(res.body);
        final userMessage = _signupErrorMessage(res.statusCode, serverError);
        throw SignUpException(
          userMessage,
          statusCode: res.statusCode,
          serverMessage: serverError,
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw SignUpException(
          'サーバーの応答形式が不正です。',
          statusCode: res.statusCode,
          serverMessage: res.body,
        );
      }

      try {
        return SignUpResult.fromJson(decoded);
      } catch (e) {
        throw SignUpException(
          'サーバーの応答形式が不正です。',
          statusCode: res.statusCode,
          serverMessage: res.body,
          cause: e,
        );
      }
    } on TimeoutException catch (e) {
      throw SignUpException(
        '通信がタイムアウトしました。時間をおいて再試行してください。',
        cause: e,
      );
    } on SocketException catch (e) {
      throw SignUpException(
        'ネットワークに接続できません。通信環境を確認してください。',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw SignUpException(
        'ネットワークエラーが発生しました。',
        cause: e,
      );
    } on FormatException catch (e) {
      throw SignUpException(
        'サーバーの応答形式が不正です。',
        cause: e,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  String _guessDisplayName(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf('@');
    if (at <= 0) return trimmed;
    return trimmed.substring(0, at);
  }
}

class SignUpException implements Exception {
  SignUpException(
    this.userMessage, {
    this.statusCode,
    this.serverMessage,
    this.cause,
  });

  final String userMessage;
  final int? statusCode;
  final String? serverMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}

String? _extractErrorMessage(String body) {
  if (body.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['error'] is String) {
      return decoded['error'] as String;
    }
  } catch (_) {
    // ignore parse errors and fall back to raw body.
  }
  return body;
}

String _signupErrorMessage(int statusCode, String? serverError) {
  final normalized = serverError?.toLowerCase();
  if (statusCode == 409 ||
      (normalized != null && normalized.contains('email already registered'))) {
    return 'このメールアドレスは既に使用されています。';
  }
  if (statusCode == 400 ||
      (normalized != null && normalized.contains('invalid request'))) {
    return '入力内容を確認してください。';
  }
  if (statusCode >= 500 ||
      (normalized != null &&
          (normalized.contains('database error') ||
              normalized.contains('failed to create user')))) {
    return 'サーバーで問題が発生しました。時間をおいて再度お試しください。';
  }
  return '新規登録に失敗しました。時間をおいて再度お試しください。';
}
