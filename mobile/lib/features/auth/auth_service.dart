import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';
import 'models.dart';

class DummyAuthService {
  const DummyAuthService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<DummyLoginResult> login(DummyUser user) async {
    // backendが未完成な間は、URL未指定なら成功扱いにする。
    if (backendBaseUrl.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return DummyLoginResult(user: user);
    }

    final Uri uri;
    try {
      uri = Uri.parse(backendBaseUrl).resolve('/login');
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $backendBaseUrl');
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
}
