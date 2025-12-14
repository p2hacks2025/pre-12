import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/dummy_login_page.dart';
import 'features/home/home_page.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'p2hacks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: auth.user == null ? const DummyLoginPage() : const HomePage(),
    );
  }
}
