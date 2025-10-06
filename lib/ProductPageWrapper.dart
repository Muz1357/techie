// lib/screens/ProductPageWrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techie/pages/dashboard.dart';
import '../provider/UserProvider.dart';

class ProductsPageWrapper extends StatefulWidget {
  const ProductsPageWrapper({super.key});

  @override
  State<ProductsPageWrapper> createState() => _ProductsPageWrapperState();
}

class _ProductsPageWrapperState extends State<ProductsPageWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Don't fetch profile here - wait for first build to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  Future<void> _initializeUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchProfile();
    } catch (e) {
      // Ignore errors - app should work without profile
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mark build start/end for UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.markBuildStart();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.markBuildEnd();
    });

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const ProductsPage();
  }
}
