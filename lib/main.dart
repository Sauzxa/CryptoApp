import 'package:cryptoimmobilierapp/onboarding/welcomeScreen.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// setup for linux
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Crypto Immobilier',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto', // Modern font
        ),
        home: const WelcomeScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    ); //
  }
}
