import 'package:CryptoApp/onboarding/welcomeScreen.dart';
import 'package:CryptoApp/utils/Routes.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/providers/messaging_provider.dart';
import 'package:CryptoApp/providers/notification_provider.dart';
import 'package:CryptoApp/providers/theme_provider.dart';
import 'package:CryptoApp/core/HomePage.dart';
import 'package:CryptoApp/services/firebase_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Notification Service
  await firebaseNotificationService.initialize();

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
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
