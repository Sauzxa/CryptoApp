import 'package:flutter/material.dart';
import 'package:CryptoApp/onboarding/welcomeScreen.dart';
import 'package:CryptoApp/auth/SingUp.dart';
import 'package:CryptoApp/auth/LoginScreen.dart';
import 'package:CryptoApp/auth/ForgetPass.dart';
import 'package:CryptoApp/auth/VerifyCode.dart';
import 'package:CryptoApp/auth/ResetPassword.dart';
import 'package:CryptoApp/core/HomePage.dart';
import 'package:CryptoApp/core/Messagerie.dart';
import 'package:CryptoApp/core/GestionAppels.dart';
import 'package:CryptoApp/core/Rendez-vous/ReserverRendezVous.dart';
import 'package:CryptoApp/core/Rendez-vous/Visits.dart';
import 'package:CryptoApp/core/AgentTerrain.dart';
import 'package:CryptoApp/core/Profile/ProfileSettings.dart';
import 'package:CryptoApp/core/Suivi/SuiviPage.dart';
import 'package:CryptoApp/core/Suivi/CommercialSuiviPage.dart';
import 'package:CryptoApp/core/Documents/DocumentsPage.dart';

class AppRoutes {
  // Route names
  static const String welcome = '/welcome';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String messagerie = '/messagerie';
  static const String gestionAppels = '/gestion-appels';
  static const String reserverRendezVous = '/reserver-rendez-vous';
  static const String reservations = '/reservations';
  static const String agentTerrain = '/agent-terrain';
  static const String profileSettings = '/profile-settings';
  static const String suivi = '/suivi';
  static const String commercialSuivi = '/commercial-suivi';
  static const String documents = '/documents';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgetPassScreen());
      case verifyCode:
        // Extract email from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email),
        );
      case resetPassword:
        // Extract email from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: email),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case messagerie:
        return MaterialPageRoute(builder: (_) => const MessageriePage());
      case gestionAppels:
        return MaterialPageRoute(builder: (_) => const GestionAppelsPage());
      case reserverRendezVous:
        return MaterialPageRoute(
          builder: (_) => const ReserverRendezVousPage(),
        );
      case reservations:
        return MaterialPageRoute(builder: (_) => const ReservationsPage());
      case agentTerrain:
        return MaterialPageRoute(builder: (_) => const AgentTerrainPage());
      case profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsPage());
      case suivi:
        return MaterialPageRoute(builder: (_) => const SuiviPage());
      case commercialSuivi:
        return MaterialPageRoute(builder: (_) => const CommercialSuiviPage());
      case documents:
        return MaterialPageRoute(builder: (_) => const DocumentsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
