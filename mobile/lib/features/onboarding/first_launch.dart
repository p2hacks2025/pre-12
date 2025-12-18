import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hasLaunchedKey = 'has_launched_v1';

final firstLaunchProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_hasLaunchedKey) ?? false);
});

Future<void> markLaunched() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_hasLaunchedKey, true);
}
