import 'package:flutter_test/flutter_test.dart';

import 'package:p2hacks_onyx/features/onboarding/register_validation.dart';

void main() {
  group('RegisterValidation.blockingReason', () {
    test('空のユーザーネーム', () {
      expect(
        RegisterValidation.blockingReason(
          username: '',
          email: 'a@b.com',
          password: 'abc12345',
        ),
        'ユーザーネームを入力してください。',
      );
    });

    test('ユーザーネームが短い', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'ab',
          email: 'a@b.com',
          password: 'abc12345',
        ),
        'ユーザーネームは3文字以上にしてください。',
      );
    });

    test('ユーザーネームが長い', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'a' * 21,
          email: 'a@b.com',
          password: 'abc12345',
        ),
        'ユーザーネームは20文字以内にしてください。',
      );
    });

    test('ユーザーネームに無効文字', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'Abc',
          email: 'a@b.com',
          password: 'abc12345',
        ),
        'ユーザーネームは英小文字/数字/_(アンダースコア)のみ有効です。',
      );
    });

    test('メールが空', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'abc',
          email: '',
          password: 'abc12345',
        ),
        'メールアドレスを入力してください。',
      );
    });

    test('メールが不正', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'abc',
          email: 'not-an-email',
          password: 'abc12345',
        ),
        '有効なメールアドレスを入力してください。',
      );
    });

    test('パスワードが空', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'abc',
          email: 'a@b.com',
          password: '',
        ),
        'パスワードを入力してください。',
      );
    });

    test('パスワードが短い', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'abc',
          email: 'a@b.com',
          password: 'a1b2c3',
        ),
        'パスワードは8文字以上にしてください。',
      );
    });

    test('パスワードに英字/数字が揃っていない', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'abc',
          email: 'a@b.com',
          password: 'abcdefgh',
        ),
        'パスワードは英字と数字をそれぞれ1文字以上含めてください。',
      );
      expect(
        RegisterValidation.blockingReason(
          username: 'abc',
          email: 'a@b.com',
          password: '12345678',
        ),
        'パスワードは英字と数字をそれぞれ1文字以上含めてください。',
      );
    });

    test('すべてOKならnull', () {
      expect(
        RegisterValidation.blockingReason(
          username: 'abc_123',
          email: 'a@b.com',
          password: 'abc12345',
        ),
        isNull,
      );
      expect(
        RegisterValidation.canProceed(
          username: 'abc_123',
          email: 'a@b.com',
          password: 'abc12345',
        ),
        isTrue,
      );
    });
  });

  group('RegisterValidation.*FieldError', () {
    test('usernameFieldError', () {
      expect(RegisterValidation.usernameFieldError(''), isNotNull);
      expect(RegisterValidation.usernameFieldError('ab'), isNotNull);
      expect(RegisterValidation.usernameFieldError('a' * 21), isNotNull);
      expect(RegisterValidation.usernameFieldError('Abc'), isNotNull);
      expect(RegisterValidation.usernameFieldError('abc_123'), isNull);
    });

    test('emailFieldError', () {
      expect(RegisterValidation.emailFieldError(''), isNotNull);
      expect(RegisterValidation.emailFieldError('nope'), isNotNull);
      expect(RegisterValidation.emailFieldError('a@b.com'), isNull);
    });

    test('passwordFieldError', () {
      expect(RegisterValidation.passwordFieldError(''), isNotNull);
      expect(RegisterValidation.passwordFieldError('a1b2c3'), isNotNull);
      expect(RegisterValidation.passwordFieldError('abcdefgh'), isNotNull);
      expect(RegisterValidation.passwordFieldError('12345678'), isNotNull);
      expect(RegisterValidation.passwordFieldError('abc12345'), isNull);
    });
  });
}
