import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import '../ui/app_theme.dart';
import '../auth/password_recovery_flow.dart';

class AdminPasswordGate extends StatefulWidget {
  const AdminPasswordGate({Key? key}) : super(key: key);

  @override
  State<AdminPasswordGate> createState() => _AdminPasswordGateState();
}

class _AdminPasswordGateState extends State<AdminPasswordGate> {
  final TextEditingController _controller = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkPassword() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    const adminPassword =
        String.fromEnvironment('ADMIN_PASSWORD', defaultValue: '');
    if (_controller.text.trim() == adminPassword && adminPassword.isNotEmpty) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
    } else {
      setState(() {
        _error = 'Incorrect admin password';
      });
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),
                    Text(
                      'Enter Admin Password',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    TextField(
                      controller: _controller,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: _error,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscure = !_obscure;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (_) => _checkPassword(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => PasswordRecoveryFlow.show(context),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _checkPassword,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
