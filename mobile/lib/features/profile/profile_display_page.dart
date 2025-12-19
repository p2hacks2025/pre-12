import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'profile_controller.dart';
import 'profile_edit_page.dart';

class ProfileDisplayPage extends ConsumerStatefulWidget {
  const ProfileDisplayPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  ConsumerState<ProfileDisplayPage> createState() => _ProfileDisplayPageState();
}

class _ProfileDisplayPageState extends ConsumerState<ProfileDisplayPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(profileControllerProvider.notifier).refresh();
    });
  }

  void _navigateToEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(
          onSave: () {
            // 編集画面から戻ってきたらプロフィールを再読み込み
            ref.read(profileControllerProvider.notifier).refresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final authUser = ref.watch(authControllerProvider).user;
    final profile = state.profile;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'エラー: ${state.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(profileControllerProvider.notifier).refresh();
              },
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    final displayName = profile?.username ?? authUser?.displayName ?? '';
    final bio = profile?.bio ?? '';
    final iconUrl = profile?.iconUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        //title: const Text('プロフィール'),
        actions: [
          TextButton.icon(
            onPressed: _navigateToEdit,
            icon: const Text('プロフィールを編集'),
            label: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // アイコン
                    iconUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 64,
                            backgroundImage: NetworkImage(iconUrl),
                          )
                        : const CircleAvatar(
                            radius: 64,
                            child: Icon(Icons.person, size: 64),
                          ),
                    const SizedBox(height: 24),
                    // ユーザー名
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // 自己紹介
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '自己紹介',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio.isEmpty ? '自己紹介が設定されていません' : bio,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: bio.isEmpty
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ログアウトボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('ログアウト'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
