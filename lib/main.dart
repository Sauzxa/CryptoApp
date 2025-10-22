import 'package:cryptoimmobilierapp/onboarding/welcomeScreen.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:cryptoimmobilierapp/providers/messaging_provider.dart';
import 'package:cryptoimmobilierapp/core/HomePage.dart';
import 'package:cryptoimmobilierapp/services/firebase_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
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
            theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
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
