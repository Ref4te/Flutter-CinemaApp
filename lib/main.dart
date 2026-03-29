import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Импорт для проверки состояния пользователя
import 'firebase_options.dart';
import 'authentification/login_page.dart';
import 'navigation/main_navigation_screen.dart'; // Убедись, что путь верный

void main() async {
  // Гарантируем инициализацию связей с нативной платформой
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.red,

        // Настройка AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),

        // Настройка текстовых полей
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

      // ИСПОЛЬЗУЕМ STREAMBUILDER ДЛЯ АВТОМАТИЧЕСКОГО ВХОДА
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Если Firebase еще проверяет состояние (загрузка)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFE50B14)),
              ),
            );
          }

          // Если пользователь уже авторизован — показываем главный экран
          if (snapshot.hasData) {
            return const MainNavigationScreen();
          }

          // Если пользователь не вошел — показываем экран логина
          return const LoginPage();
        },
      ),

      // Настраиваем именованные маршруты для удобного перехода при выходе
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}