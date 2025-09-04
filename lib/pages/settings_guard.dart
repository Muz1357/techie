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
  String _debugMessage = "";

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      final available = await auth.getAvailableBiometrics();

      debugPrint("Can check biometrics: $canCheck");
      debugPrint("Device supported: $isDeviceSupported");
      debugPrint("Available biometrics: $available");

      setState(() {
        _debugMessage =
            "canCheck=$canCheck, supported=$isDeviceSupported, available=$available";
      });

      bool didAuthenticate = false;

      didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Settings',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Auth error: $e");
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
          _debugMessage = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return const Settings();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Auth Required")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Authentication failed", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            // Debug info shown on screen
            Text(
              _debugMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
