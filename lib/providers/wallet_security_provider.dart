import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/user_profile_service.dart';
import 'auth_provider.dart';

class WalletSecurityProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration walletTimeout = Duration(minutes: 5);
  static const Duration failedAttemptLockDuration = Duration(minutes: 5);
  static const int maxFailedAttempts = 5;

  AuthProvider? _authProvider;
  Timer? _timeoutTimer;

  bool _walletUnlocked = false;
  DateTime? _lastWalletActivity;
  bool _busy = false;
  int _failedAttempts = 0;
  DateTime? _lockedOutUntil;
  String? _error;

  WalletSecurityProvider() {
    WidgetsBinding.instance.addObserver(this);
    _timeoutTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkTimeout();
    });
  }

  bool get walletUnlocked => _walletUnlocked;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLockedOut =>
      _lockedOutUntil != null && DateTime.now().isBefore(_lockedOutUntil!);
  DateTime? get lastWalletActivity => _lastWalletActivity;

  String? get lockoutMessage {
    if (!isLockedOut) return null;
    final remaining = _lockedOutUntil!.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return 'Too many failed PIN attempts. Try again in ${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void attachAuthProvider(AuthProvider authProvider) {
    final previousUserId = _authProvider?.userId;
    _authProvider = authProvider;

    if (!authProvider.authenticated || previousUserId != authProvider.userId) {
      _walletUnlocked = false;
      _lastWalletActivity = null;
      _failedAttempts = 0;
      _lockedOutUntil = null;
      _error = null;
      notifyListeners();
    }
  }

  Future<void> setWalletPin({
    required String pin,
    required String confirmPin,
  }) async {
    final authProvider = _authProvider;
    if (authProvider == null || !authProvider.authenticated) {
      throw Exception('Sign in to set your wallet PIN.');
    }

    final cleanedPin = pin.trim();
    if (cleanedPin.length < 4 || cleanedPin.length > 6) {
      throw Exception('Wallet PIN must be 4 to 6 digits.');
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(cleanedPin)) {
      throw Exception('Wallet PIN must contain digits only.');
    }
    if (cleanedPin != confirmPin.trim()) {
      throw Exception('PIN confirmation does not match.');
    }

    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final userId = authProvider.userId!;
      final pinHash = UserProfileService.hashWalletPin(
        userId: userId,
        pin: cleanedPin,
      );

      await UserProfileService.setWalletPin(
        userId: userId,
        pinHash: pinHash,
        email: authProvider.userEmail,
      );

      await authProvider.refreshProfile();
      _walletUnlocked = true;
      _lastWalletActivity = DateTime.now();
      _failedAttempts = 0;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> unlockWallet(String pin) async {
    final authProvider = _authProvider;
    if (authProvider == null || !authProvider.authenticated) {
      throw Exception('Sign in to unlock your wallet.');
    }

    if (isLockedOut) {
      throw Exception(lockoutMessage ?? 'Wallet temporarily locked.');
    }

    final cleanedPin = pin.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(cleanedPin)) {
      throw Exception('Enter your 4 to 6 digit wallet PIN.');
    }

    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final isValid = await UserProfileService.verifyWalletPin(
        userId: authProvider.userId!,
        pin: cleanedPin,
      );

      if (!isValid) {
        _failedAttempts += 1;
        if (_failedAttempts >= maxFailedAttempts) {
          _lockedOutUntil = DateTime.now().add(failedAttemptLockDuration);
          _failedAttempts = 0;
        }
        throw Exception('Invalid wallet PIN.');
      }

      _walletUnlocked = true;
      _lastWalletActivity = DateTime.now();
      _lockedOutUntil = null;
      _failedAttempts = 0;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void recordActivity() {
    if (_walletUnlocked) {
      _lastWalletActivity = DateTime.now();
    }
  }

  void checkTimeout() {
    if (_walletUnlocked &&
        _lastWalletActivity != null &&
        DateTime.now().difference(_lastWalletActivity!) > walletTimeout) {
      lockWallet();
    }
  }

  void lockWallet() {
    if (!_walletUnlocked && _lastWalletActivity == null) {
      return;
    }
    _walletUnlocked = false;
    _lastWalletActivity = null;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      lockWallet();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      checkTimeout();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
