import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../../services/artisan_service.dart';

class SetPasswordPage extends StatefulWidget {
  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String error = '';
  bool isLoading = false;

  Future<void> handleSetPassword() async {
    setState(() { isLoading = true; error = ''; });
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    if (phone.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() { error = 'All fields required.'; isLoading = false; });
      return;
    }
    if (password != confirm) {
      setState(() { error = 'Passwords do not match.'; isLoading = false; });
      return;
    }
    // IMPORTANT: This stores passwords in plaintext - should be migrated to Supabase Auth
    // For now, this is a legacy flow - use Supabase Auth for password management instead
    final artisans = await ArtisanService().fetchArtisans(search: phone);
    final artisan = artisans.firstWhere(
      (a) => a.phone == phone && a.email == email,
      orElse: () => throw Exception('No matching artisan'),
    );
    if (artisan == null) {
      setState(() { error = 'No matching artisan or password already set.'; isLoading = false; });
      return;
    }
    final success = await ArtisanService().updateArtisan(artisan.id!, {'password': password});
    if (success) {
      setState(() { error = ''; isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Password set successfully!'), backgroundColor: AppTheme.success),
      );
      Navigator.of(context).pop();
    } else {
      setState(() { error = 'Failed to set password.'; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Password')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: AppTheme.spaceBase),
            if (error.isNotEmpty)
              Text(error, style: AppTheme.bodyMedium.copyWith(color: AppTheme.error)),
            const SizedBox(height: AppTheme.spaceBase),
            ElevatedButton(
              onPressed: isLoading ? null : handleSetPassword,
              child: Text(isLoading ? 'Setting...' : 'Set Password'),
            ),
          ],
        ),
      ),
    );
  }
}
