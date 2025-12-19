import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:p2hacks_onyx/features/auth/auth_service.dart';
import 'package:p2hacks_onyx/features/auth/models.dart';

void main() {
  test(
    'DummyAuthService.loginWithEmailPassword posts /login and parses user_id',
    () async {
      late http.Request captured;

      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'user_id': 'u-999'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = DummyAuthService(
        client: client,
        baseUrl: 'http://example',
      );

      final result = await service.loginWithEmailPassword(
        const LoginRequest(email: 'a@example.com', password: 'pw'),
      );

      expect(result.userId, 'u-999');
      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'http://example/login');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['email'], 'a@example.com');
      expect(body['password'], 'pw');

      expect(captured.headers['content-type'], 'application/json');
    },
  );
}
