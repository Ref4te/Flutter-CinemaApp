import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/local_notification_service.dart';
import 'core/settings/app_settings.dart';
import 'firebase_options.dart';
import 'presentation/app/cinema_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppSettings.load();
  await LocalNotificationService.instance.initialize();

  runApp(const CinemaApp());
}
