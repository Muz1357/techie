import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:techie/pages/cart.dart';
import 'package:techie/pages/dashboard.dart';
import 'package:techie/pages/masterdetail.dart';
import 'package:techie/pages/orders.dart';
import 'package:techie/pages/settings_guard.dart';

class MainAppWrapper extends StatefulWidget {
  final Widget child;

  const MainAppWrapper({super.key, required this.child});

  @override
  State<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends State<MainAppWrapper> {
  Light? _light;
  int _luxValue = 100;
  Brightness _brightness = Brightness.light;

  @override
  void initState() {
    super.initState();
    _light = Light();
    _startListening();
  }

  void _startListening() {
    _light?.lightSensorStream.listen((luxValue) {
      setState(() {
        _luxValue = luxValue;

        // Adjust thresholds as needed
        if (_luxValue < 20) {
          _brightness = Brightness.dark;
        } else {
          _brightness = Brightness.light;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/dashboard': (context) => ProductsPage(),
        '/cart': (context) => Cart(),
        '/setting': (context) => const SettingsGuard(),
        '/masterdetail': (context) => MasterDetailScreen(),
        '/orders': (context) => OrdersScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      themeMode:
          _brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,

      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF6BC6E4),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6BC6E4),
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
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A5D73),
          secondary: Color(0xFF6BC6E4),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A5D73),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
      ),

      home: widget.child,
    );
  }
}
