import 'package:flutter/material.dart';

import 'profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  static final RegExp _usernameRe = RegExp(r'^[a-z0-9_]+$');

  bool _showPassword = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _canProceed() {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) return false;
    if (username.length < 3 || username.length > 20) return false;
    if (!_usernameRe.hasMatch(username)) return false;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) return false;
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;

    return true;
  }

  String? _blockingReason() {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty) return 'ユーザーネームを入力してください。';
    if (username.length < 3) return 'ユーザーネームは3文字以上にしてください。';
    if (username.length > 20) return 'ユーザーネームは20文字以内にしてください。';
    if (!_usernameRe.hasMatch(username)) {
      return 'ユーザーネームは英小文字/数字/_(アンダースコア)のみ有効です。';
    }

    if (email.isEmpty) return 'メールアドレスを入力してください。';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return '有効なメールアドレスを入力してください。';
    }

    if (password.isEmpty) return 'パスワードを入力してください。';
    if (password.length < 8) return 'パスワードは8文字以上にしてください。';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return 'パスワードは英字と数字をそれぞれ1文字以上含めてください。';
    }

    return null;
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (!_canProceed()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blockingReason = _blockingReason();

    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // タイトル
                const Text(
                  'アカウントを作成',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'P2HAC.KSに参加してレビュー・アップロードを始めましょう',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ユーザーネーム
                const Text(
                  'ユーザーネーム',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    hintText: '例：yamada_taro',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) {
                      return 'ユーザーネームは必須です。';
                    }
                    if (value.length < 3) {
                      return 'ユーザーネームは3文字以上にしてください。';
                    }
                    if (value.length > 20) {
                      return 'ユーザーネームは20文字以内にしてください。';
                    }
                    if (!_usernameRe.hasMatch(value)) {
                      return '英小文字/数字/_(アンダースコア)のみ使用できます。';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // メールアドレス
                const Text(
                  'メールアドレス',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: '例：yamada@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'メールアドレスは必須です。';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                      return '有効なメールアドレスを入力してください。';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // パスワード
                const Text(
                  'パスワード',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '8文字以上の英数字を含むパスワード',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'パスワードは必須です。';
                    }
                    if (v.length < 8) {
                      return 'パスワードは8文字以上にしてください。';
                    }
                    if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
                        !RegExp(r'[0-9]').hasMatch(v)) {
                      return '英字と数字をそれぞれ1文字以上含めてください。';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                if (blockingReason != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      blockingReason,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _canProceed() ? _next : null,
                    child: const Text('次へ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
