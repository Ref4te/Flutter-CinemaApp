import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _keyDarkTheme = 'app_dark_theme';
  static const _keyNotifications = 'app_notifications_enabled';
  static const _keyLanguage = 'app_language';

  static final ValueNotifier<bool> isDarkTheme = ValueNotifier(true);
  static final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  static final ValueNotifier<String> language = ValueNotifier('Русский');

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkTheme.value = prefs.getBool(_keyDarkTheme) ?? true;
    notificationsEnabled.value = prefs.getBool(_keyNotifications) ?? true;
    language.value = prefs.getString(_keyLanguage) ?? 'Русский';
  }

  static Future<void> setDarkTheme(bool value) async {
    isDarkTheme.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkTheme, value);
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  static Future<void> setLanguage(String value) async {
    language.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, value);
  }

  static String get tmdbLanguageCode {
    switch (language.value) {
      case 'English':
        return 'en-US';
      case 'Қазақша':
        return 'kk-KZ';
      default:
        return 'ru-RU';
    }
  }
}
