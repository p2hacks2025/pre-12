import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
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
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700), // Yellow/Gold
          primary: const Color(0xFFFFD700),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFE6C200), // Darker Yellow for visibility
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: auth.user == null
          ? isFirstLaunchAsync.when(
              data: (isFirstLaunch) {
                if (isFirstLaunch) {
                  return const RegisterScreen();
                }
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
