import 'package:CryptoApp/onboarding/welcomeScreen.dart';
import 'package:CryptoApp/utils/Routes.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/providers/messaging_provider.dart';
import 'package:CryptoApp/providers/notification_provider.dart';
import 'package:CryptoApp/providers/rapport_provider.dart';
import 'package:CryptoApp/providers/theme_provider.dart';
import 'package:CryptoApp/core/HomePage.dart';
import 'package:CryptoApp/services/firebase_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('📩 Background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // The native Android service will show the notification
  // This handler is just for logging and processing data
}

// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler BEFORE any other Firebase initialization
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RapportProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          // Initialize Firebase Notification Service once
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await firebaseNotificationService.initialize();
          });

          // Initialize messaging when authenticated
          if (authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messagingProvider = Provider.of<MessagingProvider>(
                context,
                listen: false,
              );
              messagingProvider.initializeMessaging();
            });
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Crypto Immobilier',
            theme: themeProvider.currentTheme,
            navigatorKey: navigatorKey,
            home: _getInitialScreen(authProvider),
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(AuthProvider authProvider) {
    // Show loading while initializing
    if (authProvider.isLoading) {
      print('⏳ App initializing...');
      return Scaffold(
        backgroundColor: Colors.black, // Black background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('lib/assets/CryptoLogo.png', width: 120, height: 120),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    print('🚀 Determining initial route...');
    print('   isAuthenticated: ${authProvider.isAuthenticated}');
    print('   hasToken: ${authProvider.token != null}');
    print('   hasUser: ${authProvider.currentUser != null}');

    // If authenticated, show HomePage
    if (authProvider.isAuthenticated) {
      print('✅ Routing to HomePage (user is authenticated)');
      return const HomePage();
    }

    // If not authenticated, always show WelcomeScreen
    // User can navigate to login/signup from there
    print('🏠 Routing to WelcomeScreen (user not authenticated)');
    return const WelcomeScreen();
  }
}
