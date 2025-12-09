// lib/services/notification_service.dart — FINAL & FULLY WORKING (Dec 2025)
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/event_detail_screen.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Store the message that launched the app
  static RemoteMessage? initialMessage;

  // Private instance
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize everything
  static Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iOSSettings);

    // NEW PARAMETER NAME (v10+)
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handlePayload(response.payload!);
        }
      },
    );

    // Background / terminated tap handlers
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // Get the message that launched the app and store it
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  }

  /// Show local notification — WORKS PERFECTLY
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance',
      'High Importance Notifications',
      channelDescription: 'Event & geofence alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle tap on notification
  static void _handlePayload(String payload) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: payload)),
        (route) => route.isFirst,
      );
    }
  }

  /// Handle Firebase RemoteMessage navigation
  static void _handleMessage(RemoteMessage message) {
    final eventId = message.data['event_id'] ?? message.data['eventId'];
    if (eventId != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: eventId.toString())),
        (route) => route.isFirst,
      );
    }
  }
}
