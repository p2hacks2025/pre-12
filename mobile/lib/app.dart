import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/dummy_login_page.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/first_launch.dart';
import 'register_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isFirstLaunchAsync = ref.watch(firstLaunchProvider);

    return MaterialApp(
      title: 'p2hacks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: auth.user == null
          ? isFirstLaunchAsync.when(
              data: (isFirstLaunch) {
                if (isFirstLaunch) {
                  return const RegisterScreen();
                }
                return const DummyLoginPage();
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  Scaffold(body: Center(child: Text('初期化エラー: $e'))),
            )
          : const HomePage(),
    );
  }
}
