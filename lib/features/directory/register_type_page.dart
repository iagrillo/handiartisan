import 'package:flutter/material.dart';
import '../services/post_service_form_page.dart';
import 'post_store_form_page.dart';
import '../ui/app_theme.dart';

class RegisterTypePage extends StatelessWidget {
  const RegisterTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Register As'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                decoration: BoxDecoration(
                  gradient: AppTheme.subtleGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      ),
                      child: const Icon(Icons.app_registration, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: AppTheme.spaceBase),
                    Text(
                      'What would you like to register as?',
                      style: AppTheme.headline3.copyWith(color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Choose the option that best fits your business so customers can find you faster.',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceXL),
              // Store Button
              _buildOptionCard(
                context,
                icon: Icons.store,
                title: 'Store',
                subtitle: 'Register a physical or online store',
                color: AppTheme.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostStoreFormPage(initialType: 'store')),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),
              // Supplier Button
              _buildOptionCard(
                context,
                icon: Icons.local_shipping,
                title: 'Supplier',
                subtitle: 'Supply goods or materials',
                color: AppTheme.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostStoreFormPage(initialType: 'supplier')),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),
              // Services Button
              _buildOptionCard(
                context,
                icon: Icons.build,
                title: 'Services',
                subtitle: 'Equipment repair, maintenance & servicing',
                color: AppTheme.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostServiceFormPage()),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),
              // Artisan Button
              _buildOptionCard(
                context,
                icon: Icons.handyman,
                title: 'Artisan',
                subtitle: 'Register as a skilled artisan',
                color: AppTheme.info,
                onTap: () {
                  Navigator.pushNamed(context, '/artisan-register');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.shadowSM,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceBase),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: color, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
