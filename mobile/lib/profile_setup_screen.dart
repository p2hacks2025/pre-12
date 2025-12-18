import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/models.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/first_launch.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.username,
    required this.email,
  });

  final String username;
  final String email;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  Uint8List? _iconBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool _canProceed() {
    final displayName = _displayNameCtrl.text.trim();
    if (displayName.isEmpty) return false;
    if (displayName.length > 30) return false;

    final bio = _bioCtrl.text.trim();
    if (bio.length > 200) return false;
    return true;
  }

  String? _blockingReason() {
    final displayName = _displayNameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    if (displayName.isEmpty) return '表示名を入力してください。';
    if (displayName.length > 30) return '表示名は30文字以内にしてください。';
    if (bio.length > 200) return '自己紹介は200文字以内にしてください。';

    return null;
  }

  Future<void> _pickIcon() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      if (!mounted) return;

      setState(() => _iconBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アイコン画像の選択に失敗しました: $e')));
    }
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canProceed()) return;

    setState(() => _isSubmitting = true);
    try {
      await markLaunched();
      ref.invalidate(firstLaunchProvider);

      final displayName = _displayNameCtrl.text.trim();
      await ref
          .read(authControllerProvider.notifier)
          .login(DummyUser(id: widget.username, displayName: displayName));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ホーム画面への遷移に失敗: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                const Text(
                  'プロフィールを作成',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'アイコンと自己紹介を設定しましょう',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Center(
                  child: InkWell(
                    onTap: _isSubmitting ? null : _pickIcon,
                    borderRadius: BorderRadius.circular(999),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: _iconBytes == null
                          ? null
                          : MemoryImage(_iconBytes!),
                      child: _iconBytes == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _pickIcon,
                    child: const Text('アイコンを選択'),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  '表示名',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameCtrl,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    hintText: '例：山田 太郎',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '表示名は必須です。';
                    }
                    if (v.trim().length > 30) {
                      return '表示名は30文字以内にしてください。';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                const Text(
                  '自己紹介',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioCtrl,
                  enabled: !_isSubmitting,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '例：好きな作品や推しポイントを書いてください',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v != null && v.trim().length > 200) {
                      return '自己紹介は200文字以内にしてください。';
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
                    onPressed: _isSubmitting
                        ? null
                        : (_canProceed() ? _next : null),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('次へ'),
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
