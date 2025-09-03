import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:techie/pages/setting.dart';

class SettingsGuard extends StatefulWidget {
  const SettingsGuard({super.key});

  @override
  State<SettingsGuard> createState() => _SettingsGuardState();
}

class _SettingsGuardState extends State<SettingsGuard> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final available = await auth.getAvailableBiometrics();

      bool didAuthenticate = false;
      if (canCheck && available.isNotEmpty) {
        didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to access Settings',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false, // allow device PIN/pattern if biometrics fail
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return const Settings(); // your original settings page
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Authentication failed"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }
  }
}
