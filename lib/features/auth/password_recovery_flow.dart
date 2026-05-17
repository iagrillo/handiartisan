import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import '../../services/password_recovery_service.dart';

class PasswordRecoveryFlow {
  PasswordRecoveryFlow._();

  static final PasswordRecoveryService _service = PasswordRecoveryService();

  static Future<void> _openNextStep(
    BuildContext sheetContext,
    Future<void> Function() nextStep,
  ) async {
    Navigator.of(sheetContext, rootNavigator: true).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await nextStep();
  }

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
    String initialPhone = '',
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLG,
              AppTheme.spaceSM,
              AppTheme.spaceLG,
              AppTheme.spaceLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recover your password', style: AppTheme.headline3),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Choose a secure recovery method below.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF3FF),
                    child: Icon(Icons.email_outlined),
                  ),
                  title: const Text('Reset via Email OTP'),
                  subtitle: const Text(
                    'Receive a verification code in your inbox.',
                  ),
                  onTap: () => _openNextStep(
                    sheetContext,
                    () => _showEmailRequestDialog(
                      context,
                      initialEmail: initialEmail,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAFBF0),
                    child: Icon(Icons.chat_outlined, color: AppTheme.whatsapp),
                  ),
                  title: const Text('Reset via WhatsApp Inbound Verification'),
                  subtitle: const Text(
                    'Send a free pre-filled WhatsApp recovery message.',
                  ),
                  onTap: () => _openNextStep(
                    sheetContext,
                    () => _showWhatsAppStartDialog(
                      context,
                      initialEmail: initialEmail,
                      initialPhone: initialPhone,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showEmailRequestDialog(
    BuildContext context, {
    String initialEmail = '',
  }) async {
    final emailController = TextEditingController(text: initialEmail);
    var isLoading = false;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => AlertDialog(
          title: const Text('Reset via Email OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your registered email address. We will send a verification code to help you reset your password.',
                style: AppTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spaceBase),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Registered email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim().toLowerCase();
                      if (email.isEmpty || !email.contains('@')) {
                        _showSnackBar(
                          context,
                          'Please enter a valid email address.',
                          isError: true,
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final dispatch = await _service.sendEmailOtp(email);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (!context.mounted) return;
                        _showSnackBar(context, dispatch.message);
                        if (dispatch.delivery == EmailRecoveryDelivery.otp) {
                          await _showEmailOtpVerificationDialog(
                            context,
                            email: email,
                          );
                        } else {
                          await _showResetLinkInstructionsDialog(
                            context,
                            email: email,
                          );
                        }
                      } catch (error) {
                        final errMsg = error.toString().replaceFirst('Exception: ', '');
                        if (errMsg.toLowerCase().contains('rate limit')) {
                          _showSnackBar(
                            context,
                            'Too many requests. Please wait a few minutes before trying again.',
                            isError: true,
                          );
                        } else if (errMsg.toLowerCase().contains('not found')) {
                          _showSnackBar(
                            context,
                            'No account found for that email. Please check and try again.',
                            isError: true,
                          );
                        } else {
                          _showSnackBar(
                            context,
                            'Failed to send OTP: $errMsg',
                            isError: true,
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showEmailOtpVerificationDialog(
    BuildContext context, {
    required String email,
  }) async {
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isLoading = false;
    var obscurePassword = true;
    var obscureConfirm = true;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => AlertDialog(
          title: const Text('Verify OTP & Reset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the OTP code sent to $email, then choose a new password.',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Use the most recent code. Requesting a new OTP invalidates the previous one.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OTP code',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final dispatch = await _service.sendEmailOtp(email);
                        otpController.clear();
                        if (!context.mounted) return;
                        _showSnackBar(context, dispatch.message);
                        if (dispatch.delivery ==
                            EmailRecoveryDelivery.resetLink) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          await _showResetLinkInstructionsDialog(
                            context,
                            email: email,
                          );
                        }
                      } catch (error) {
                        _showSnackBar(
                          context,
                          error.toString().replaceFirst('Exception: ', ''),
                          isError: true,
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: const Text('Resend OTP'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final otp = otpController.text.trim();
                      final newPassword = newPasswordController.text.trim();
                      final confirmPassword =
                          confirmPasswordController.text.trim();

                      if (otp.length < 6) {
                        _showSnackBar(
                          context,
                          'Please enter the OTP code from your email.',
                          isError: true,
                        );
                        return;
                      }

                      if (newPassword.length < 6) {
                        _showSnackBar(
                          context,
                          'Password must be at least 6 characters long.',
                          isError: true,
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        _showSnackBar(
                          context,
                          'Passwords do not match.',
                          isError: true,
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        await _service.verifyEmailOtpAndResetPassword(
                          email: email,
                          otp: otp,
                          newPassword: newPassword,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (!context.mounted) return;
                        _showSnackBar(
                          context,
                          'Password reset successful. Please sign in with your new password.',
                        );
                      } catch (error) {
                        _showSnackBar(
                          context,
                          error.toString().replaceFirst('Exception: ', ''),
                          isError: true,
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showWhatsAppStartDialog(
    BuildContext context, {
    String initialEmail = '',
    String initialPhone = '',
  }) async {
    final emailController = TextEditingController(text: initialEmail);
    final phoneController = TextEditingController(text: initialPhone);
    var isLoading = false;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => AlertDialog(
          title: const Text('Reset via WhatsApp'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use your registered phone number to send a free password recovery message on WhatsApp.',
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spaceBase),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Registered email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Registered WhatsApp number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final session = await _service.startWhatsAppRecovery(
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (!context.mounted) return;
                        await _showWhatsAppLaunchDialog(context, session);
                      } catch (error) {
                        _showSnackBar(
                          context,
                          error.toString().replaceFirst('Exception: ', ''),
                          isError: true,
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate Token'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showWhatsAppLaunchDialog(
    BuildContext context,
    PasswordRecoverySession session,
  ) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('WhatsApp Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send the message below from your registered WhatsApp number. Once received, HandiHub will verify it and reply on WhatsApp with your secure reset link.',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.whatsapp.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: AppTheme.whatsapp.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recovery ID', style: AppTheme.labelMedium),
                  const SizedBox(height: AppTheme.spaceXS),
                  SelectableText(
                    session.token,
                    style: AppTheme.headline3.copyWith(
                      color: AppTheme.whatsapp,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Message: Reset my HandiHub password ID: ${session.token}',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'This token expires at ${session.expiresAt.hour.toString().padLeft(2, '0')}:${session.expiresAt.minute.toString().padLeft(2, '0')}.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await _service.openWhatsAppRecovery(
                  token: session.token,
                  whatsappUrl: session.launchUrl,
                  phoneNumber: session.businessNumber,
                );
              } catch (error) {
                _showSnackBar(
                  context,
                  error.toString().replaceFirst('Exception: ', ''),
                  isError: true,
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open WhatsApp'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              await _showWhatsAppTokenVerificationDialog(context, session);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showWhatsAppTokenVerificationDialog(
    BuildContext context,
    PasswordRecoverySession session,
  ) async {
    var isLoading = false;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuilderContext, setDialogState) => AlertDialog(
          title: const Text('Confirm WhatsApp Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'After sending the WhatsApp message from your registered number, tap Check Status below. We will confirm the inbound message and continue securely.',
                style: AppTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spaceBase),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.whatsapp.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(
                    color: AppTheme.whatsapp.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recovery ID', style: AppTheme.labelMedium),
                    const SizedBox(height: AppTheme.spaceXS),
                    SelectableText(
                      session.token,
                      style: AppTheme.headline3.copyWith(
                        color: AppTheme.whatsapp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      try {
                        await _service.openWhatsAppRecovery(
                          token: session.token,
                          whatsappUrl: session.launchUrl,
                          phoneNumber: session.businessNumber,
                        );
                      } catch (error) {
                        _showSnackBar(
                          context,
                          error.toString().replaceFirst('Exception: ', ''),
                          isError: true,
                        );
                      }
                    },
              child: const Text('Open WhatsApp'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final dispatch =
                            await _service.verifyWhatsAppTokenAndSendEmailOtp(
                          email: session.email,
                          phone: session.phone ?? '',
                          token: session.token,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (!context.mounted) return;
                        _showSnackBar(context, dispatch.message);
                        if (dispatch.delivery == EmailRecoveryDelivery.otp) {
                          await _showEmailOtpVerificationDialog(
                            context,
                            email: session.email,
                          );
                        } else if (dispatch.delivery ==
                            EmailRecoveryDelivery.whatsappLink) {
                          await _showWhatsAppResetLinkInstructionsDialog(
                            context,
                          );
                        } else {
                          await _showResetLinkInstructionsDialog(
                            context,
                            email: session.email,
                          );
                        }
                      } catch (error) {
                        _showSnackBar(
                          context,
                          error.toString().replaceFirst('Exception: ', ''),
                          isError: true,
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check Status'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showResetLinkInstructionsDialog(
    BuildContext context, {
    required String email,
  }) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check your email'),
        content: Text(
          'A password reset link has been sent to $email. Open the email, tap the reset link, and the app will let you choose a new password.',
          style: AppTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showWhatsAppResetLinkInstructionsDialog(
    BuildContext context,
  ) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check your WhatsApp'),
        content: Text(
          'Your WhatsApp message has been verified. Open your chat with HandiHub and use the newest secure reset link sent there.',
          style: AppTheme.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }
}
