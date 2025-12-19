import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_controller.dart';
import 'models.dart';

final _loginEmailProvider = StateProvider.autoDispose<String>((ref) => '');
final _loginPasswordProvider = StateProvider.autoDispose<String>((ref) => '');
final _loginShowPasswordProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class DummyLoginPage extends ConsumerWidget {
  const DummyLoginPage({super.key});

  static const List<DummyUser> users = <DummyUser>[
    DummyUser(id: 'tanaka-taro', displayName: '田中 太郎'),
    DummyUser(id: 'suzuki-hanako', displayName: '鈴木 花子'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final users = DummyLoginPage.users;
    final showPassword = ref.watch(_loginShowPasswordProvider);
    final email = ref.watch(_loginEmailProvider);
    final password = ref.watch(_loginPasswordProvider);

    Future<void> login() async {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メールアドレスは必須です。')));
        return;
      }
      if (password.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('パスワードは必須です。')));
        return;
      }

      await ref
          .read(authControllerProvider.notifier)
          .loginWithEmailPassword(email: trimmedEmail, password: password);
    }

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
              const Text(
                'メールアドレスでログイン',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: '例：yamada@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                onChanged: (v) =>
                    ref.read(_loginEmailProvider.notifier).state = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: !state.isLoading,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  hintText: 'パスワード',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () =>
                              ref
                                      .read(_loginShowPasswordProvider.notifier)
                                      .state =
                                  !showPassword,
                  ),
                ),
                onChanged: (v) =>
                    ref.read(_loginPasswordProvider.notifier).state = v,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.isLoading ? null : login,
                child: const Text('ログイン'),
              ),
              const SizedBox(height: 16),
              if (state.error != null)
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (state.error != null) const SizedBox(height: 12),
              const Text(
                'ダミーログイン',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
