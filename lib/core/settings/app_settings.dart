import 'package:flutter/material.dart';

class AppSettings {
  static final ValueNotifier<bool> isDarkTheme = ValueNotifier(true);
  static final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  static final ValueNotifier<String> language = ValueNotifier('Русский');

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