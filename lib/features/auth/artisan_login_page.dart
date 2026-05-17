import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/app_theme.dart';
import '../../services/artisan_service.dart';
import '../directory/artisan_profile_page.dart';
import 'password_recovery_flow.dart';

class ArtisanLoginPage extends StatefulWidget {
  final String? phone;
  final String? email;
  const ArtisanLoginPage({Key? key, this.phone, this.email}) : super(key: key);

  @override
  State<ArtisanLoginPage> createState() => _ArtisanLoginPageState();
}

class _ArtisanLoginPageState extends State<ArtisanLoginPage> {
  late TextEditingController phoneController;
  late TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.phone ?? '');
    emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (phone.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Phone, email, and password required.';
        isLoading = false;
      });
      return;
    }
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final artisans = await ArtisanService().fetchArtisans();
        final artisan = artisans.firstWhere(
          (a) => a.email == email && a.phone == phone,
          orElse: () => throw Exception('Artisan profile not found'),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppTheme.slideRoute(ArtisanProfilePage(artisan: artisan)),
        );
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      setState(() {
        if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
          error = 'Please verify your email before logging in. Check your inbox for a confirmation link.';
        } else if (msg.contains('invalid') || msg.contains('credentials')) {
          error = 'Invalid email or password.';
        } else {
          error = 'Login failed. Please try again.';
        }
      });
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Artisan Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXL,
              vertical: AppTheme.space2XL,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      boxShadow: AppTheme.shadowMD,
                    ),
                    child: const Icon(Icons.engineering,
                        color: AppTheme.surface, size: 36),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                  Text('Artisan Login', style: AppTheme.headline2),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Access your artisan dashboard',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.space2XL),

                  // Error banner
                  if (error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spaceMD),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppTheme.error, size: 18),
                          const SizedBox(width: AppTheme.spaceSM),
                          Expanded(
                            child: Text(
                              error,
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceBase),
                  ],

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceBase),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceBase),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => PasswordRecoveryFlow.show(
                                context,
                                initialEmail: emailController.text.trim(),
                                initialPhone: phoneController.text.trim(),
                              ),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleLogin,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.surface,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
