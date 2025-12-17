import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'models.dart';

class DummyLoginPage extends ConsumerWidget {
  const DummyLoginPage({super.key});

  static const List<DummyUser> users = <DummyUser>[
    DummyUser(id: 'tanaka-taro', displayName: '田中 太郎'),
    DummyUser(id: 'suzuki-hanako', displayName: '鈴木 花子'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ダミーログイン'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.error != null)
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (state.error != null) const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .login(user),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            user.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
