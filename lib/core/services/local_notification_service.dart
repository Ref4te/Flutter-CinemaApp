import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../presentation/pages/navigation/main_navigation_screen.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _openTicketsOnStart = false;
  bool _timezoneInitialized = false;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    await _configureLocalTimezone();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true && launchPayload == 'open_tickets') {
      _openTicketsOnStart = true;
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> openPendingDestinationIfNeeded() async {
    if (!_openTicketsOnStart) return;
    _openTicketsOnStart = false;
    _openTickets();
  }

  Future<void> scheduleTicketReminder({
    required int ticketId,
    required String movieTitle,
    required DateTime sessionStart,
    required String cinemaAddress,
  }) async {
    final scheduledAt = sessionStart.subtract(const Duration(hours: 1));
    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      ticketId,
      'Скоро сеанс: $movieTitle',
      'Через час начало. Время: ${_formatTime(sessionStart)} • Адрес: $cinemaAddress',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_reminders',
          'Напоминания о билетах',
          channelDescription: 'Напоминания за час до начала фильма',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'open_tickets',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }


  Future<void> _configureLocalTimezone() async {
    if (_timezoneInitialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _timezoneInitialized = true;
  }
  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'open_tickets') {
      _openTickets();
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    if (response.payload == 'open_tickets') {
      instance._openTicketsOnStart = true;
    }
  }

  void _openTickets() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _openTicketsOnStart = true;
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 2)),
      (route) => false,
    );
  }
}
