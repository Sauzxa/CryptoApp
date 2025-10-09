import 'package:cryptoimmobilierapp/core/HomePage.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// setup for linux
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Immobilier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // Modern font
      ),
      home: const HomePage(),
      onGenerateRoute: AppRoutes.generateRoute,
    ); //
  }
}
