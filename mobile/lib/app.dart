import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/first_launch.dart';

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
                // アプリ起動時は常にログイン画面を表示
                // if (isFirstLaunch) {
                //   return const RegisterScreen();
                // }
                return const LoginPage();
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
