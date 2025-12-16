import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ---- 設定 ----
  static const String registerEndpoint =
      'https://example.com/api/auth/register'; // TODO: 自分のAPIへ
  // ---------------

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showPasswordConfirm = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  bool _canSubmit() {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final passwordConfirm = _passwordConfirmCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) return false;
    if (password != passwordConfirm) return false;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) return false;
    if (password.length < 8) return false;

    return true;
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
      };

      final res = await http.post(
        Uri.parse(registerEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録完了しました')),
        );
        // 登録後に前の画面に戻るか、ログイン画面へ遷移
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録失敗: ${res.statusCode}\n${res.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通信エラー: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新規登録'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // タイトル
                const Text(
                  'アカウントを作成',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'P2HAC.KSに参加してレビュー・アップロードを始めましょう',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    hintText: '例：yamada_taro',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'ユーザーネームは必須です。';
                    }
                    if (v.trim().length < 3) {
                      return 'ユーザーネームは3文字以上にしてください。';
                    }
                    if (v.trim().length > 20) {
                      return 'ユーザーネームは20文字以内にしてください。';
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
                  enabled: !_isSubmitting,
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
                  enabled: !_isSubmitting,
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
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // パスワード確認
                const Text(
                  'パスワード（確認）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordConfirmCtrl,
                  enabled: !_isSubmitting,
                  obscureText: !_showPasswordConfirm,
                  decoration: InputDecoration(
                    hintText: 'パスワードをもう一度入力',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPasswordConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(
                          () => _showPasswordConfirm = !_showPasswordConfirm,
                        );
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'パスワード確認は必須です。';
                    }
                    if (v != _passwordCtrl.text) {
                      return 'パスワードが一致しません。';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                // 登録ボタン
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_canSubmit() ? _submitRegister : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit() && !_isSubmitting
                        ? Colors.blue
                        : null,
                    foregroundColor: _canSubmit() && !_isSubmitting
                        ? Colors.white
                        : null,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _canSubmit()
                              ? '登録する'
                              : '入力内容を確認してください',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 16),

                // ログインリンク
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('すでにアカウントをお持ちですか？ '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'ログイン',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
