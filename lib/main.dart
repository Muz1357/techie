import 'package:flutter/material.dart';
import 'package:techie/cart.dart';
import 'package:techie/dashboard.dart';
import 'package:techie/login.dart';
import 'package:techie/setting.dart';
import 'package:techie/masterdetail.dart';
import 'package:techie/orders.dart';

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
        '/masterdetail': (context) => MasterDetailScreen(),
        '/orders': (context) => OrdersScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF6BC6E4),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6BC6E4),
          secondary: Color(0xFF0A5D73),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6BC6E4),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0A5D73),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF0A5D73),
          secondary: Color(0xFF6BC6E4),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A5D73),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
      ),

      themeMode: ThemeMode.system,
      home: LoginPage(),
    );
  }
}
