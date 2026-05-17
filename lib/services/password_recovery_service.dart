import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum PasswordRecoveryMethod { emailOtp, whatsappInbound }

enum EmailRecoveryDelivery { otp, resetLink, whatsappLink }

class PasswordRecoverySession {
  const PasswordRecoverySession({
    required this.method,
    required this.email,
    required this.phone,
    required this.token,
    required this.expiresAt,
    this.launchUrl,
    this.businessNumber,
  });

  final PasswordRecoveryMethod method;
  final String email;
  final String? phone;
  final String token;
  final DateTime expiresAt;
  final String? launchUrl;
  final String? businessNumber;
}

class EmailRecoveryDispatchResult {
  const EmailRecoveryDispatchResult({
    required this.delivery,
    required this.message,
  });

  final EmailRecoveryDelivery delivery;
  final String message;
}

class PasswordRecoveryService {
  PasswordRecoveryService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final SupabaseClient _client = Supabase.instance.client;
  final FlutterSecureStorage _storage;

  static const String _emailKey = 'password_recovery_email';
  static const String _phoneKey = 'password_recovery_phone';
  static const String _tokenKey = 'password_recovery_token';
  static const String _expiresKey = 'password_recovery_expires_at';
  static const String _methodKey = 'password_recovery_method';

  static const String _defaultBusinessNumber = String.fromEnvironment(
    'HANDIHUB_WHATSAPP_BUSINESS_NUMBER',
    defaultValue: '2349139106323',
  );
  static const String _mobileRecoveryRedirect =
      'handihubglobal://login-callback/';
  static const String _whatsAppRecoveryFunction = 'whatsappRecovery';

  bool get isWhatsAppBusinessNumberConfigured =>
      _cleanPhoneNumber(_defaultBusinessNumber) == '2349139106323' ||
      _cleanPhoneNumber(_defaultBusinessNumber).isNotEmpty;

  String get businessNumber => _cleanPhoneNumber(_defaultBusinessNumber);

  Future<EmailRecoveryDispatchResult> sendEmailOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid registered email address.');
    }

    final redirectTo = _buildRecoveryRedirectTo();

    try {
      await _client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: redirectTo,
      );

      return const EmailRecoveryDispatchResult(
        delivery: EmailRecoveryDelivery.otp,
        message:
            'If an account exists for that email, a recovery code has been sent. Check your inbox (and spam folder).',
      );
    } on AuthApiException catch (error) {
      final authMessage = '${error.message} ${error.code ?? ''}'.toLowerCase();
      if (authMessage.contains('rate limit') ||
          authMessage.contains('over_email_send_rate_limit')) {
        throw Exception(
          'Too many recovery emails were requested. Please wait a few minutes before trying again.',
        );
      }
      rethrow;
    }
  }

  Future<void> verifyEmailOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedOtp = otp.replaceAll(RegExp(r'\s+'), '');

    if (normalizedOtp.length < 6) {
      throw Exception('Enter the OTP code sent to your email.');
    }

    AuthApiException? lastAuthError;

    for (final otpType in const [
      OtpType.recovery,
      OtpType.email,
      OtpType.magiclink,
    ]) {
      try {
        await _client.auth.verifyOTP(
          email: normalizedEmail,
          token: normalizedOtp,
          type: otpType,
        );
        lastAuthError = null;
        break;
      } on AuthApiException catch (error) {
        lastAuthError = error;
        final authMessage =
            '${error.message} ${error.code ?? ''}'.toLowerCase();
        final shouldTryNextType = otpType != OtpType.magiclink &&
            (authMessage.contains('otp_expired') ||
                authMessage.contains('token has expired') ||
                authMessage.contains('invalid'));
        if (shouldTryNextType) {
          continue;
        }
        break;
      }
    }

    if (lastAuthError != null) {
      final authMessage =
          '${lastAuthError.message} ${lastAuthError.code ?? ''}'.toLowerCase();
      if (authMessage.contains('otp_expired') ||
          authMessage.contains('token has expired')) {
        throw Exception(
          'This recovery code is invalid or expired. Please request one fresh OTP and use it immediately.',
        );
      }
      if (authMessage.contains('invalid')) {
        throw Exception(
          'This recovery code is invalid. Request a new code and enter the latest one sent to your email.',
        );
      }
      throw Exception(
        'We could not verify that recovery code right now. Please request a new OTP and try again.',
      );
    }

    await updateRecoveredPassword(
      newPassword: newPassword,
      email: normalizedEmail,
    );
  }

  Future<void> updateRecoveredPassword({
    required String newPassword,
    String? email,
  }) async {
    final trimmedPassword = newPassword.trim();
    if (trimmedPassword.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    await _client.auth.updateUser(
      UserAttributes(password: trimmedPassword),
    );

    final resolvedEmail =
        (email ?? _client.auth.currentUser?.email ?? '').trim().toLowerCase();
    if (resolvedEmail.isNotEmpty) {
      await _syncLegacyArtisanPassword(
        email: resolvedEmail,
        newPassword: trimmedPassword,
      );
    }

    await clearWhatsAppRecoverySession();
    await _client.auth.signOut();
  }

  Future<PasswordRecoverySession> startWhatsAppRecovery({
    required String email,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _cleanPhoneNumber(phone);

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid registered email address.');
    }

    if (normalizedPhone.length < 10) {
      throw Exception('Enter your registered phone or WhatsApp number.');
    }

    await _verifyRegisteredPhone(
      email: normalizedEmail,
      phone: normalizedPhone,
    );

    final remote = await _invokeWhatsAppRecovery(
      'start',
      payload: {
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'redirectTo': _buildRecoveryRedirectTo(),
      },
    );

    final token = remote?['token']?.toString() ?? _generateWhatsAppToken();
    final expiresAt =
        DateTime.tryParse(remote?['expiresAt']?.toString() ?? '') ??
            DateTime.now().add(const Duration(minutes: 10));
    final remoteLaunchUrl = remote?['whatsappUrl']?.toString();
    final resolvedBusinessNumber = _cleanPhoneNumber(
      remote?['businessNumber']?.toString() ?? businessNumber,
    );

    await _storage.write(
      key: _methodKey,
      value: PasswordRecoveryMethod.whatsappInbound.name,
    );
    await _storage.write(key: _emailKey, value: normalizedEmail);
    await _storage.write(key: _phoneKey, value: normalizedPhone);
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiresKey, value: expiresAt.toIso8601String());

    return PasswordRecoverySession(
      method: PasswordRecoveryMethod.whatsappInbound,
      email: normalizedEmail,
      phone: normalizedPhone,
      token: token,
      expiresAt: expiresAt,
      launchUrl: remoteLaunchUrl,
      businessNumber:
          resolvedBusinessNumber.isEmpty ? null : resolvedBusinessNumber,
    );
  }

  Future<void> openWhatsAppRecovery({
    required String token,
    String? whatsappUrl,
    String? phoneNumber,
  }) async {
    final resolvedBusinessNumber =
        _cleanPhoneNumber(phoneNumber ?? businessNumber);
    final hasLaunchUrl = whatsappUrl != null && whatsappUrl.trim().isNotEmpty;

    if (resolvedBusinessNumber.isEmpty && !hasLaunchUrl) {
      throw Exception(
        'WhatsApp support number is not configured yet. '
        'Add HANDIHUB_WHATSAPP_BUSINESS_NUMBER to enable one-tap opening.',
      );
    }

    final message = 'Reset my HandiHub password ID: $token';
    final nativeUri = Uri.parse(
      'whatsapp://send?phone=$resolvedBusinessNumber&text=${Uri.encodeComponent(message)}',
    );
    final webUri = Uri.parse(
      hasLaunchUrl
          ? whatsappUrl.trim()
          : 'https://wa.me/$resolvedBusinessNumber?text=${Uri.encodeComponent(message)}',
    );

    final preferredMode =
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
    final nativeOpened = await launchUrl(nativeUri, mode: preferredMode);
    if (nativeOpened) return;

    final webOpened = await launchUrl(webUri, mode: preferredMode);
    if (webOpened) return;

    final fallbackOpened =
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
    if (!fallbackOpened) {
      throw Exception('Could not open WhatsApp on this device.');
    }
  }

  Future<EmailRecoveryDispatchResult> verifyWhatsAppTokenAndSendEmailOtp({
    required String email,
    required String phone,
    required String token,
  }) async {
    final session = await getActiveWhatsAppRecoverySession();
    if (session == null) {
      throw Exception('Start the WhatsApp recovery flow again.');
    }

    if (session.expiresAt.isBefore(DateTime.now())) {
      await clearWhatsAppRecoverySession();
      throw Exception('This recovery token has expired. Request a new one.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _cleanPhoneNumber(phone);
    final normalizedToken = token.trim().toUpperCase();

    if (session.email != normalizedEmail ||
        session.phone != normalizedPhone ||
        session.token != normalizedToken) {
      throw Exception(
        'Token mismatch. Please confirm the recovery token and try again.',
      );
    }

    final remote = await _invokeWhatsAppRecovery(
      'status',
      payload: {
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'token': normalizedToken,
        'redirectTo': _buildRecoveryRedirectTo(),
      },
    );

    if (remote != null) {
      final verified = remote['verified'] == true;
      if (!verified) {
        final fallback = await sendEmailOtp(normalizedEmail);
        return EmailRecoveryDispatchResult(
          delivery: fallback.delivery,
          message:
              'WhatsApp verification is still pending, so a recovery email has been sent to help you continue now.',
        );
      }

      final delivery = switch (remote['delivery']?.toString()) {
        'otp' => EmailRecoveryDelivery.otp,
        'whatsappLink' => EmailRecoveryDelivery.whatsappLink,
        _ => EmailRecoveryDelivery.resetLink,
      };

      if (delivery == EmailRecoveryDelivery.otp) {
        final emailDispatch = await sendEmailOtp(normalizedEmail);
        return EmailRecoveryDispatchResult(
          delivery: emailDispatch.delivery,
          message: remote['message']?.toString() ?? emailDispatch.message,
        );
      }

      return EmailRecoveryDispatchResult(
        delivery: delivery,
        message: remote['message']?.toString() ??
            'Verified. Continue with the next recovery step.',
      );
    }

    return sendEmailOtp(normalizedEmail);
  }

  Future<PasswordRecoverySession?> getActiveWhatsAppRecoverySession() async {
    final email = await _storage.read(key: _emailKey);
    final phone = await _storage.read(key: _phoneKey);
    final token = await _storage.read(key: _tokenKey);
    final expiresRaw = await _storage.read(key: _expiresKey);
    final methodRaw = await _storage.read(key: _methodKey);

    if (email == null || token == null || expiresRaw == null) {
      return null;
    }

    final expiresAt = DateTime.tryParse(expiresRaw);
    if (expiresAt == null) return null;

    final method = methodRaw == PasswordRecoveryMethod.whatsappInbound.name
        ? PasswordRecoveryMethod.whatsappInbound
        : PasswordRecoveryMethod.emailOtp;

    return PasswordRecoverySession(
      method: method,
      email: email,
      phone: phone,
      token: token,
      expiresAt: expiresAt,
      businessNumber: businessNumber,
    );
  }

  Future<void> clearWhatsAppRecoverySession() async {
    await _storage.delete(key: _methodKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresKey);
  }

  Future<Map<String, dynamic>?> _invokeWhatsAppRecovery(
    String action, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final response = await _client.functions.invoke(
        _whatsAppRecoveryFunction,
        body: {
          'action': action,
          ...?payload,
        },
      );

      if (response.data == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['success'] == false) {
        throw Exception(
          (data['error'] ?? data['message'] ?? 'WhatsApp recovery failed')
              .toString(),
        );
      }
      return data;
    } catch (error) {
      final message = error.toString().toLowerCase();
      final isMissingFunction = message.contains('failed to fetch') ||
          message.contains('404') ||
          (message.contains('function') && message.contains('not found'));
      if (isMissingFunction) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _verifyRegisteredPhone({
    required String email,
    required String phone,
  }) async {
    try {
      final artisanResponse = await _client
          .from('artisans')
          .select('id,phone')
          .eq('email', email)
          .limit(10);
      final storeResponse = await _client
          .from('stores')
          .select('id,phone_number,whatsapp_number,contact')
          .eq('email', email)
          .limit(10);

      final artisanRows = (artisanResponse as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final storeRows = (storeResponse as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

      if (artisanRows.isEmpty && storeRows.isEmpty) {
        throw Exception('No account was found for that email address.');
      }

      final artisanMatch = artisanRows.any(
        (row) => _cleanPhoneNumber(row['phone']?.toString() ?? '') == phone,
      );
      final storeMatch = storeRows.any(
        (row) =>
            _cleanPhoneNumber(
              row['phone_number']?.toString() ??
                  row['whatsapp_number']?.toString() ??
                  row['contact']?.toString() ??
                  '',
            ) ==
            phone,
      );

      if (!artisanMatch && !storeMatch) {
        throw Exception(
          'The phone number does not match the registered account for that email.',
        );
      }
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception(
          'Unable to verify the registered phone number right now.');
    }
  }

  String? _buildRecoveryRedirectTo() {
    const configuredRedirect = String.fromEnvironment(
      'HANDIHUB_PASSWORD_RECOVERY_URL',
      defaultValue: '',
    );
    if (configuredRedirect.trim().isNotEmpty) {
      return configuredRedirect.trim();
    }

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      final isLocalDev =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';

      if (isLocalDev) {
        return _mobileRecoveryRedirect;
      }

      return Uri.base
          .replace(path: '/password-reset', queryParameters: {}, fragment: '')
          .toString();
    }

    return _mobileRecoveryRedirect;
  }

  Future<void> _syncLegacyArtisanPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _client.from('artisans').update({
        'password': newPassword,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('email', email);

      await _client.from('stores').update({
        'password_hash': newPassword,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('email', email);
    } catch (_) {
      // Keep Supabase Auth reset successful even if the legacy rows are
      // not writable in the current session.
    }
  }

  String _generateWhatsAppToken() {
    final random = Random.secure().nextInt(9000) + 1000;
    return 'HB-$random';
  }

  String _cleanPhoneNumber(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = '234${digits.substring(1)}';
    } else if (digits.length == 10) {
      digits = '234$digits';
    }
    return digits;
  }
}
