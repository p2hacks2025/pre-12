import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import 'profile_controller.dart';
import '../../widgets/inline_error_banner.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  XFile? _pickedIcon;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(profileControllerProvider.notifier).refresh();
      _syncControllers();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final authUser = ref.read(authControllerProvider).user;
    final profile = ref.read(profileControllerProvider).profile;

    _usernameCtrl.text = (profile?.username.isNotEmpty ?? false)
        ? profile!.username
        : (authUser?.displayName ?? '');
    _bioCtrl.text = profile?.bio ?? '';
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _pickedIcon = image;
      _submitError = null;
    });
  }

  Future<void> _save() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      if (!mounted) return;
      setState(() => _submitError = 'ログインが必要です。再度ログインしてください。');
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final username = _usernameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    final profile = ref.read(profileControllerProvider).profile;
    // 変更がない場合は送信しない
    final isUsernameChanged = username != (profile?.username ?? '');
    final isBioChanged = bio != (profile?.bio ?? '');
    final isIconChanged = _pickedIcon != null;

    if (!isUsernameChanged && !isBioChanged && !isIconChanged) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('変更がありません')));
      return;
    }

    try {
      setState(() => _submitError = null);
      final updated = await ref
          .read(profileControllerProvider.notifier)
          .update(username: username, bio: bio, icon: _pickedIcon);

      if (updated != null) {
        ref
            .read(authControllerProvider.notifier)
            .updateDisplayName(updated.username);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));

      // 保存後に前の画面に戻る
      Navigator.of(context).pop();
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = '保存に失敗しました。時間をおいて再試行してください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;
    final inlineError = _submitError ?? state.error;

    ref.listen<ProfileState>(profileControllerProvider, (prev, next) {
      if (prev?.profile != next.profile && next.profile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncControllers();
        });
      }
    });

    final avatar = _pickedIcon != null
        ? CircleAvatar(
            radius: 44,
            backgroundImage: FileImage(File(_pickedIcon!.path)),
          )
        : (profile?.iconUrl.isNotEmpty ?? false)
        ? CircleAvatar(
            radius: 44,
            backgroundImage: NetworkImage(profile!.iconUrl),
          )
        : const CircleAvatar(radius: 44, child: Icon(Icons.person));

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: avatar),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: state.isLoading ? null : _pickIcon,
                    icon: const Icon(Icons.photo),
                    label: const Text('アイコンを変更'),
                  ),
                ),
                if (inlineError != null) ...[
                  const SizedBox(height: 12),
                  InlineErrorBanner(message: inlineError),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ユーザー名',
                    border: OutlineInputBorder(),
                    enabled: false,
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: false,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'ユーザー名を入力してください';
                    if (t.length > 30) return 'ユーザー名は30文字以内にしてください';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioCtrl,
                  decoration: const InputDecoration(
                    labelText: '自己紹介',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 6,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length > 300) return '自己紹介は300文字以内にしてください';
                    return null;
                  },
                  onChanged: (_) {
                    if (_submitError != null) {
                      setState(() => _submitError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.isLoading ? null : _save,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
