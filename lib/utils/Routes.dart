import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/core/HomePage.dart';
import 'package:cryptoimmobilierapp/core/Messagerie.dart';
import 'package:cryptoimmobilierapp/core/GestionAppels.dart';
import 'package:cryptoimmobilierapp/core/Rendez-vous/ReserverRendezVous.dart';

class AppRoutes {
  // Route names
  static const String home = '/home';
  static const String messagerie = '/messagerie';
  static const String gestionAppels = '/gestion-appels';
  static const String reserverRendezVous = '/reserver-rendez-vous';

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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
