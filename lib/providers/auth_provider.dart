import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/payment_service.dart';
import '../services/user_profile_service.dart';

class AuthProvider extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  User? _user;
  String? _userEmail;
  bool _authenticated = false;
  bool _loading = false;
  bool _initialized = false;
  bool _walletPinSet = false;
  String? _error;

  AuthProvider() {
    _bootstrap();
  }

  Session? get session => _session;
  User? get user => _user;
  String? get userId => _user?.id;
  String? get userEmail => _userEmail;
  bool get authenticated => _authenticated;
  bool get loading => _loading;
  bool get initialized => _initialized;
  bool get walletPinSet => _walletPinSet;
  String? get error => _error;

  Future<void> _bootstrap() async {
    final client = Supabase.instance.client;
    await _applySession(client.auth.currentSession);

    _authSubscription = client.auth.onAuthStateChange.listen((data) async {
      await _applySession(data.session);
    });
  }

  Future<void> _applySession(Session? session) async {
    _session = session;
    _user = session?.user;
    _userEmail = _user?.email;
    _authenticated = _user != null;
    _error = null;

    if (_user != null) {
      await UserProfileService.ensureProfileForUser(_user!);
      _walletPinSet = await UserProfileService.isWalletPinSet(_user!.id);
    } else {
      _walletPinSet = false;
      PaymentService.clearWalletAccessCredentials();
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user == null) return;

    await UserProfileService.ensureProfileForUser(_user!);
    _walletPinSet = await UserProfileService.isWalletPinSet(_user!.id);
    notifyListeners();
  }

  void markWalletPinSet(bool value) {
    _walletPinSet = value;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _error = 'Invalid email or password.';
        _authenticated = false;
      }
    } catch (e) {
      _error = 'Authentication failed. Please try again.';
      _authenticated = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    PaymentService.clearWalletAccessCredentials();
    _session = null;
    _user = null;
    _userEmail = null;
    _authenticated = false;
    _walletPinSet = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
