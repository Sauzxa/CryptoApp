import 'package:cryptoimmobilierapp/onboarding/welcomeScreen.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:cryptoimmobilierapp/core/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If authenticated, show HomePage
    if (authProvider.isAuthenticated) {
      return const HomePage();
    }

    // If not authenticated, always show WelcomeScreen
    // User can navigate to login/signup from there
    return const WelcomeScreen();
  }
}

// Remove the AuthWrapper class - no longer needed
