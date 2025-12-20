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
      throw AuthException('BACKEND_BASE_URL が未設定です');
    }

    final Uri uri;
    try {
      uri = joinBasePath(Uri.parse(_effectiveBaseUrl), '/login');
    } catch (_) {
      throw AuthException('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
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

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw AuthException('メールアドレスまたはパスワードが違います。');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw AuthException('現在サービスに接続できません。時間をおいて再試行してください。');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map || decoded['user_id'] is! String) {
        throw AuthException('サーバーの応答が不正です。時間をおいて再試行してください。');
      }
      final userId = decoded['user_id'] as String;
      return AuthLoginResult(
        user: AuthUser(
          id: userId,
          email: email,
          displayName: _guessDisplayName(email),
        ),
      );
    } on AuthException {
      rethrow;
    } on TimeoutException catch (e) {
      throw AuthException(_commonErrorMessage(e));
    } on SocketException catch (e) {
      throw AuthException(_commonErrorMessage(e));
    } on http.ClientException catch (e) {
      throw AuthException(_commonErrorMessage(e));
    } on FormatException catch (e) {
      throw AuthException(_commonErrorMessage(e));
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
      throw AuthException('BACKEND_BASE_URL が未設定です');
    }

    final Uri uri;
    try {
      uri = joinBasePath(Uri.parse(_effectiveBaseUrl), '/login');
    } catch (_) {
      throw AuthException('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
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

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw AuthException('メールアドレスまたはパスワードが違います。');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw AuthException('現在サービスに接続できません。時間をおいて再試行してください。');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw AuthException('サーバーの応答が不正です。時間をおいて再試行してください。');
      }

      return LoginResult.fromJson(decoded);
    } on AuthException {
      rethrow;
    } on TimeoutException catch (e) {
      throw AuthException(_commonErrorMessage(e));
    } on SocketException catch (e) {
      throw AuthException(_commonErrorMessage(e));
    } on http.ClientException catch (e) {
      throw AuthException(_commonErrorMessage(e));
    } on FormatException catch (e) {
      throw AuthException(_commonErrorMessage(e));
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
      throw SignUpException('BACKEND_BASE_URL が不正です: $_effectiveBaseUrl');
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
          'サーバーの応答が不正です。時間をおいて再試行してください。',
          statusCode: res.statusCode,
          serverMessage: res.body,
        );
      }

      try {
        return SignUpResult.fromJson(decoded);
      } catch (e) {
        throw SignUpException(
          'サーバーの応答が不正です。時間をおいて再試行してください。',
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
        '通信エラーが発生しました。時間をおいて再試行してください。',
        cause: e,
      );
    } on FormatException catch (e) {
      throw SignUpException(
        'サーバーの応答が不正です。時間をおいて再試行してください。',
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

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
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

String _commonErrorMessage(Object error) {
  if (error is TimeoutException) {
    return '通信がタイムアウトしました。時間をおいて再試行してください。';
  }
  if (error is SocketException) {
    return 'ネットワークに接続できません。通信環境を確認してください。';
  }
  if (error is http.ClientException) {
    return '通信エラーが発生しました。時間をおいて再試行してください。';
  }
  if (error is FormatException) {
    return 'サーバーの応答が不正です。時間をおいて再試行してください。';
  }
  return '現在サービスに接続できません。時間をおいて再試行してください。';
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
    return '現在サービスに接続できません。時間をおいて再試行してください。';
  }
  return '現在サービスに接続できません。時間をおいて再試行してください。';
}
