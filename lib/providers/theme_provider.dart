import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ← IMPORT INI WAJIB
import '../utils/shared_pref_helper.dart';

// Provider sederhana untuk theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final savedMode = SharedPrefHelper.getThemeMode();
  return savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
});

// Function untuk toggle theme (panggil di UI)
Future<void> toggleTheme(WidgetRef ref) async {
  final currentMode = ref.read(themeModeProvider);
  final newMode = currentMode == ThemeMode.light ? 'dark' : 'light';
  await SharedPrefHelper.setThemeMode(newMode);
  ref.read(themeModeProvider.notifier).state = 
      newMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
}