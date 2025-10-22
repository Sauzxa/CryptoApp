import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/onboarding/welcomeScreen.dart';
import 'package:cryptoimmobilierapp/auth/SingUp.dart';
import 'package:cryptoimmobilierapp/auth/LoginScreen.dart';
import 'package:cryptoimmobilierapp/core/HomePage.dart';
import 'package:cryptoimmobilierapp/core/Messagerie.dart';
import 'package:cryptoimmobilierapp/core/GestionAppels.dart';
import 'package:cryptoimmobilierapp/core/Rendez-vous/ReserverRendezVous.dart';
import 'package:cryptoimmobilierapp/core/Rendez-vous/Reservations.dart';
import 'package:cryptoimmobilierapp/core/AgentTerrain.dart';
import 'package:cryptoimmobilierapp/core/Profile/ProfileSettings.dart';
import 'package:cryptoimmobilierapp/core/Suivi/SuiviPage.dart';
import 'package:cryptoimmobilierapp/core/Suivi/CommercialSuiviPage.dart';

class AppRoutes {
  // Route names
  static const String welcome = '/welcome';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String home = '/home';
  static const String messagerie = '/messagerie';
  static const String gestionAppels = '/gestion-appels';
  static const String reserverRendezVous = '/reserver-rendez-vous';
  static const String reservations = '/reservations';
  static const String agentTerrain = '/agent-terrain';
  static const String profileSettings = '/profile-settings';
  static const String suivi = '/suivi';
  static const String commercialSuivi = '/commercial-suivi';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
