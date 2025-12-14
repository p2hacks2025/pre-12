import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ホーム'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('ログアウト'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          user == null ? '未ログイン' : 'ログインユーザー: ${user.displayName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
