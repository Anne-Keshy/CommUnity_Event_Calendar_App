// lib/main.dart — FINAL & FULLY WORKING VERSION (Dec 2025)
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// Import for kReleaseMode
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:community/models/event.dart';
import 'package:community/adapters/latlng_adapter.dart';

// Services & Screens
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/geofence_service.dart';
import 'event_repository.dart';

/// Top-level background message handler (MUST be outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling background message: ${message.messageId}");

  // --- FIX: Extract the eventId for the payload ---
  final eventId = message.data['event_id'] ?? message.data['eventId'];
  NotificationService.showNotification(
    title: message.notification?.title ?? "New Message",
    body: message.notification?.body ?? "",
    payload: eventId?.toString(),
  );
}

// A Future that completes when all services are initialized.
late final Future<void> _initialization;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start all initializations but don't wait for them here.
  // The SplashScreen will handle the waiting.
  _initialization = _initAllServices();

  runApp(const CommUnityApp());
}

/// Initializes Hive DB, registers adapters, and opens boxes.
Future<void> _initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(LatLngAdapter());
  Hive.registerAdapter(EventAdapter());
  await Hive.openBox<Event>('eventsBox');
  await Hive.openBox<Map>('offlineQueue'); // Box to store failed requests
}

/// Initializes Firebase and sets up background/foreground message handlers.
Future<void> _initFirebase() async {
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.subscribeToTopic('all_users');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    // --- FIX: Extract the eventId for the payload ---
    final eventId = message.data['event_id'] ?? message.data['eventId'];
    NotificationService.showNotification(
      title: message.notification?.title ?? "New Message",
      body: message.notification?.body ?? "",
      payload: eventId?.toString(),
    );
  });
}

/// Sets up local notification channels and initializes the service.
Future<void> _initNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance',
    'High Importance Notifications',
    description: 'Used for important event and geofence alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await NotificationService.initialize();
}

/// Initializes the geofence service.
Future<void> _initGeofenceService() async {
  await GeofenceService.initialize();
}

/// Sets up a listener to retry queued API calls when network is restored.
Future<void> _initConnectivityListener() async {
  // Attempt to retry any queued requests on app start (non-blocking)
    ApiService().retryQueuedRequests().then((_) {
    debugPrint("Queued requests retry completed");
  }).catchError((e) {
    debugPrint("Queued requests retry failed: $e");
  });

  // Listen for connectivity changes to trigger retries automatically.
  Connectivity()
      .onConnectivityChanged
      .listen((_) => ApiService().retryQueuedRequests());
}

/// A single function to run all initialization logic.
Future<void> _initAllServices() async {
  // Run core initializations that don't depend on each other in parallel.
  await Future.wait([
    _initHive(),
    _initFirebase(),
    _initNotifications(),
    _initConnectivityListener(),
  ]);

  // Now, initialize services that depend on the core setup.
  // Make geofence initialization non-blocking
  _initGeofenceService().then((_) {
    debugPrint("Geofence service initialized in background");
  }).catchError((e) {
    debugPrint("Geofence service initialization failed: $e");
  });

  // Fetch events and sync geofences asynchronously (don't block splash screen)
  EventRepository.fetchAndCacheEvents().then((_) {
    debugPrint("Event fetching completed in background");
  }).catchError((e) {
    debugPrint("Event fetching failed in background: $e");
  });
}

// ================== MAIN APP ==================
class CommUnityApp extends StatefulWidget {
  const CommUnityApp({super.key});

  @override
  State<CommUnityApp> createState() => _CommUnityAppState();
}

class _CommUnityAppState extends State<CommUnityApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'CommUnity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      // Pass the initial message from Firebase to the SplashScreen
      home: SplashScreen(
        initialMessage: NotificationService.initialMessage,
        initialization: _initialization,
      ),
    );
  }
}
