import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/app_theme.dart';
import '../models/artisan.dart';
import '../../services/artisan_service.dart';
import 'artisan_login_page.dart';

class ArtisanRegisterPage extends StatefulWidget {
  const ArtisanRegisterPage({super.key});

  @override
  State<ArtisanRegisterPage> createState() => _ArtisanRegisterPageState();
}

class _ArtisanRegisterPageState extends State<ArtisanRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isLoading = false;
  String _error = '';

  final List<String> _categories = [
    'General',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mechanic',
    'Welder',
    'AC Technician',
    'Appliance Repair',
    'Mason',
    'Roofer',
    'Landscaper',
    'Interior Designer',
    'Other',
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final phone = _phoneController.text.trim();

      // Step 1: Create Supabase Auth account (sends verification email)
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        setState(() {
          _error = 'Registration failed. Please try again.';
        });
        return;
      }

      // Step 2: Insert artisan profile row linked to the auth user
      final artisan = Artisan(
        id: authResponse.user!.id,
        fullName: _fullNameController.text.trim(),
        phone: phone,
        email: email,
        category: _selectedCategory,
        status: 'pending',
        isAvailable: false,
      );

      await ArtisanService().addArtisan(artisan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Please check your email to verify your account before logging in.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ArtisanLoginPage(
              phone: phone,
              email: email,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceXL,
          AppTheme.spaceXL,
          AppTheme.spaceXL,
          AppTheme.space3XL,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand header
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    boxShadow: AppTheme.shadowMD,
                  ),
                  child: const Icon(Icons.engineering,
                      color: AppTheme.surface, size: 32),
                ),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              Text(
                'Join as an Artisan',
                style: AppTheme.headline3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Create your profile and start getting jobs',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceXL),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Skill Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceXL),

              // Error banner
              if (_error.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: Text(
                          _error,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceBase),
              ],

              // Register Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surface,
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
