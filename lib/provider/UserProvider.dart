// lib/provider/UserProvider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  int? _userId;
  bool _isLoading = false;
  bool _hasLoaded = false;

  // Track if we're in a build phase
  bool _inBuildPhase = false;

  Map<String, dynamic>? get user => _user;
  int? get userId => _userId;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  // Safe notification that never triggers during build
  void _safeNotifyListeners() {
    if (_disposed) return;

    if (_inBuildPhase) {
      // If we're in build phase, schedule notification for later
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } else {
      // If not in build phase, notify immediately
      notifyListeners();
    }
  }

  // Call this when entering build methods
  void markBuildStart() {
    _inBuildPhase = true;
  }

  // Call this when exiting build methods
  void markBuildEnd() {
    _inBuildPhase = false;
  }

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchProfile() async {
    if (_isLoading || _hasLoaded) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final profile = await ApiService.getProfile();
      _user = profile;
      _userId = profile['id'] as int?;
      _hasLoaded = true;
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching profile: $error');
      }
      // Mark as loaded even on error to prevent infinite retries
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void setUser(Map<String, dynamic> userData) {
    _user = userData;
    _userId = userData['id'] as int?;
    _hasLoaded = true;
    _safeNotifyListeners();
  }

  void clearUser() {
    _user = null;
    _userId = null;
    _hasLoaded = false;
    _safeNotifyListeners();
  }
}
