import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'env.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notifications setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];
    if (title != null && body != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel_id',
            'Default',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  // When app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!');
    // TODO: Navigate or handle as needed
  });

  // Handle app launch from terminated state via notification
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('App launched from notification: ${initialMessage.messageId}');
    // TODO: Handle navigation or logic here
  }

  // Listen for token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print('FCM Token refreshed: $newToken');
    // TODO: Send newToken to your backend
  });

  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  if (token != null) {
    await sendFcmTokenToBackend(token);
  }

  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'EcoPack',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFF9800), // Orange
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF9800),
              brightness: Brightness.light,
              primary: const Color(0xFFFF9800),
              secondary: const Color(0xFFFFB74D),
              tertiary: const Color(0xFFFFCC80),
              surface: const Color(0xFFFAFAFA),
              background: const Color(0xFFF5F5F5),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            cardTheme: CardThemeData(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFF9800), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
              headlineMedium: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.3,
              ),
              titleLarge: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
              titleMedium: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.1,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF9800),
              titleTextStyle: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFFF9800),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF9800),
              brightness: Brightness.dark,
              primary: const Color(0xFFFF9800),
              secondary: const Color(0xFFFFB74D),
              tertiary: const Color(0xFFFFCC80),
              surface: const Color(0xFF1E1E1E),
              background: const Color(0xFF121212),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardThemeData(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFF9800), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
              headlineMedium: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.3,
              ),
              titleLarge: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: -0.2,
              ),
              titleMedium: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.1,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: const Color(0xFFFF9800),
              titleTextStyle: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              centerTitle: true,
            ),
          ),
          themeMode: mode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en', ''), // English
            Locale('ru', ''), // Russian
            // Add other locales you need
          ],
        );
      },
    ),
  );
}

class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPack',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF9800), // Orange
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9800),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F8E9),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFFFF9800),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF9800),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9800),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF263238),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFFFF9800),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> sendFcmTokenToBackend(String fcmToken) async {
  final storage = FlutterSecureStorage();
  String? authToken;

  try {
    authToken = await storage.read(key: 'auth_token');
  } on PlatformException {
    // This can happen if the app is reinstalled on Android, which might
    // cause the encryption key to be lost. By deleting all stored data,
    // we allow the app to function, although the user will need to
    // re-authenticate.
    await storage.deleteAll();
  }

  if (authToken == null) return;

  final url = Uri.parse('${Env.apiBaseUrl}api/firebase_store');
  await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
    body: '{"fcm_token": "$fcmToken"}',
  );
}
