import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import 'profile_controller.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  XFile? _pickedIcon;

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

    setState(() => _pickedIcon = image);
  }

  Future<void> _save() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('未ログインです')));
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final username = _usernameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

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

    return SafeArea(
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'ユーザー名'),
                textInputAction: TextInputAction.next,
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
                decoration: const InputDecoration(labelText: '自己紹介'),
                minLines: 3,
                maxLines: 6,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length > 300) return '自己紹介は300文字以内にしてください';
                  return null;
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
              if (state.error != null)
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('ログアウト'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
