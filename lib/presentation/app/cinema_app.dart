import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../pages/auth/login_page.dart';
import '../pages/navigation/main_navigation_screen.dart';

class CinemaApp extends StatefulWidget {
  const CinemaApp({super.key});

  @override
  State<CinemaApp> createState() => _CinemaAppState();
}

class _CinemaAppState extends State<CinemaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.instance.openPendingDestinationIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkTheme,
      builder: (context, isDark, child) {
        return MaterialApp(
          navigatorKey: LocalNotificationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Cinema Booking',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                return const MainNavigationScreen();
              }

              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
