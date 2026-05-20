import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    notificationsEnabled.value = prefs.getBool('notificationsEnabled') ?? true;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
      await prefs.setBool('isDarkMode', true);
    } else {
      themeMode.value = ThemeMode.light;
      await prefs.setBool('isDarkMode', false);
    }
  }

  Future<void> toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled.value = !notificationsEnabled.value;
    await prefs.setBool('notificationsEnabled', notificationsEnabled.value);
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
