import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/core/HomePage.dart';
import 'package:cryptoimmobilierapp/core/Messagerie.dart';
import 'package:cryptoimmobilierapp/core/GestionAppels.dart';
import 'package:cryptoimmobilierapp/core/Rendez-vous/ReserverRendezVous.dart';
import 'package:cryptoimmobilierapp/core/AgentTerrain.dart';
import 'package:cryptoimmobilierapp/core/Profile/ProfileSettings.dart';

class AppRoutes {
  // Route names
  static const String home = '/home';
  static const String messagerie = '/messagerie';
  static const String gestionAppels = '/gestion-appels';
  static const String reserverRendezVous = '/reserver-rendez-vous';
  static const String agentTerrain = '/agent-terrain';
  static const String profileSettings = '/profile-settings';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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
      case agentTerrain:
        return MaterialPageRoute(builder: (_) => const AgentTerrainPage());
      case profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
