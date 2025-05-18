import 'package:flutter/material.dart';
import 'package:techie/cart.dart';
import 'package:techie/dashboard.dart';
import 'package:techie/login.dart';
import 'package:techie/setting.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/cart': (context) => Cart(),
        '/setting': (context) => Settings(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginPage(),
    );
  }
}
