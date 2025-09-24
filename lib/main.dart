import 'package:flutter/material.dart';
import 'call_log_test_page.dart';

void main() {
  runApp(const MyApp());
}

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
      ),
      home: const CallLogTestPage(),
    );
  }
}
