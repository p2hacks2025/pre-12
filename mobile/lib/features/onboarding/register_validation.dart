class RegisterValidation {
  // 仕様: username は英小文字・数字・_（アンダースコア）のみ許可する。
  static final RegExp usernameRe = RegExp(r'^[a-z0-9_]+$');
  static final RegExp emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp hasLetterRe = RegExp(r'[A-Za-z]');
  static final RegExp hasDigitRe = RegExp(r'[0-9]');

  static bool canProceed({
    required String username,
    required String email,
    required String password,
  }) {
    return blockingReason(
          username: username,
          email: email,
          password: password,
        ) ==
        null;
  }

  static String? blockingReason({
    required String username,
    required String email,
    required String password,
  }) {
    final u = username.trim();
    final e = email.trim();

    if (u.isEmpty) return 'ユーザーネームを入力してください。';
    if (u.length < 3) return 'ユーザーネームは3文字以上にしてください。';
    if (u.length > 20) return 'ユーザーネームは20文字以内にしてください。';
    if (!usernameRe.hasMatch(u)) {
      return 'ユーザーネームは英小文字/数字/_(アンダースコア)のみ有効です。';
    }

    if (e.isEmpty) return 'メールアドレスを入力してください。';
    if (!emailRe.hasMatch(e)) return '有効なメールアドレスを入力してください。';

    if (password.isEmpty) return 'パスワードを入力してください。';
    if (password.length < 8) return 'パスワードは8文字以上にしてください。';
    if (!hasLetterRe.hasMatch(password) || !hasDigitRe.hasMatch(password)) {
      return 'パスワードは英字と数字をそれぞれ1文字以上含めてください。';
    }

    return null;
  }

  static String? usernameFieldError(String? value) {
    final u = (value ?? '').trim();
    if (u.isEmpty) return 'ユーザーネームは必須です。';
    if (u.length < 3) return 'ユーザーネームは3文字以上にしてください。';
    if (u.length > 20) return 'ユーザーネームは20文字以内にしてください。';
    if (!usernameRe.hasMatch(u)) return '英小文字/数字/_(アンダースコア)のみ使用できます。';
    return null;
  }

  static String? emailFieldError(String? value) {
    final e = (value ?? '').trim();
    if (e.isEmpty) return 'メールアドレスは必須です。';
    if (!emailRe.hasMatch(e)) return '有効なメールアドレスを入力してください。';
    return null;
  }

  static String? passwordFieldError(String? value) {
    final p = value ?? '';
    if (p.isEmpty) return 'パスワードは必須です。';
    if (p.length < 8) return 'パスワードは8文字以上にしてください。';
    if (!hasLetterRe.hasMatch(p) || !hasDigitRe.hasMatch(p)) {
      return '英字と数字をそれぞれ1文字以上含めてください。';
    }
    return null;
  }
}
