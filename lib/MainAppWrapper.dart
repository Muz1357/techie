// MainAppWrapper.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:techie/ProductPageWrapper.dart' as wrapper;
import 'package:techie/pages/cart.dart';
import 'package:techie/pages/masterdetail.dart';
import 'package:techie/pages/orders.dart';
import 'package:techie/pages/settings_guard.dart';
import 'pages/login.dart';
import 'provider/UserProvider.dart';

class MainAppWrapper extends StatefulWidget {
  const MainAppWrapper({super.key});

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
    try {
      _light?.lightSensorStream.listen((luxValue) {
        if (mounted) {
          setState(() {
            _luxValue = luxValue;
            _brightness = _luxValue < 20 ? Brightness.dark : Brightness.light;
          });
        }
      });
    } catch (e) {
      debugPrint("Light sensor error: $e");
    }
  }

  @override
  void dispose() {
    _light = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // REMOVED: CartProvider - we'll handle cart directly in CartScreen
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          // Show loading spinner while profile is being fetched
          if (userProvider.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Techie App',
            themeMode:
                _brightness == Brightness.light
                    ? ThemeMode.light
                    : ThemeMode.dark,
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
              useMaterial3: true,
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
              useMaterial3: true,
            ),
            initialRoute: userProvider.userId != null ? '/dashboard' : '/login',
            routes: {
              '/login': (context) => const LoginPage(),
              '/dashboard': (context) => const wrapper.ProductsPageWrapper(),
              '/cart': (context) => const CartScreen(),
              '/setting': (context) => const SettingsGuard(),
              '/masterdetail': (context) => const MasterDetailScreen(),
              '/orders': (context) => const OrdersScreen(),
            },
          );
        },
      ),
    );
  }
}
