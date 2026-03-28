import 'package:flutter/material.dart';
import 'authentification/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cinema Booking',

      // НАСТРОЙКА ТЕМНОЙ ТЕМЫ
      theme: ThemeData(
        brightness: Brightness.dark, // Включает темный режим для всех стандартных виджетов
        scaffoldBackgroundColor: const Color(0xFF121212), // Глубокий черный/серый фон
        primarySwatch: Colors.red, // Основной акцентный цвет (кнопки, индикаторы)

        // Настройка AppBar (верхней панели)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),

        // Настройка текстовых полей (чтобы они хорошо смотрелись на темном фоне)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),

      home: const LoginPage(),
    );
  }
}