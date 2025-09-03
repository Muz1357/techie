import 'package:flutter/material.dart';
import 'package:techie/pages/login.dart';
import 'MainAppWrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainAppWrapper(child: LoginPage());
  }
}
