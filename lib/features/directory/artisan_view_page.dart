import 'package:provider/provider.dart';
import 'artisan_provider.dart';
import '../models/category.dart';
import 'package:flutter/material.dart';
import '../models/artisan.dart';
import '../ui/app_theme.dart';

class ArtisanViewPage extends StatelessWidget {
  final Artisan artisan;
  const ArtisanViewPage({required this.artisan, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<ArtisanProvider>(context, listen: false).categories ?? [];
    final category = categories.firstWhere(
      (cat) => cat.name == artisan.category,
      orElse: () => Category(id: 0, slug: '', name: 'No Category', icon: ''),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Artisan Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: (artisan.profileImageUrl != null && artisan.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(artisan.profileImageUrlWithCache ?? artisan.profileImageUrl!)
                      : null,
                  child: (artisan.profileImageUrl == null || artisan.profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: AppTheme.spaceBase),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(artisan.fullName, style: AppTheme.headline3),
                      if (artisan.businessName != null && artisan.businessName!.isNotEmpty)
                        Text(artisan.businessName!, style: AppTheme.bodyLarge),
                      Text(category.name, style: AppTheme.labelMedium.copyWith(color: AppTheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            if (artisan.bio != null && artisan.bio!.isNotEmpty)
              Text(artisan.bio!, style: AppTheme.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: AppTheme.spaceSM),
            if (artisan.address != null && artisan.address!.isNotEmpty)
              Text('Address: ${artisan.address!}', style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spaceSM),
            if (artisan.phone.isNotEmpty)
              Text('Phone: ${artisan.phone}', style: AppTheme.bodyMedium),
            if (artisan.whatsapp != null && artisan.whatsapp!.isNotEmpty)
              Text('WhatsApp: ${artisan.whatsapp}', style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spaceBase),
            if (artisan.galleryImageUrls != null && artisan.galleryImageUrls!.isNotEmpty) ...[
              Text('Gallery:', style: AppTheme.titleSmall),
              const SizedBox(height: AppTheme.spaceSM),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artisan.galleryImageUrls!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSM),
                  itemBuilder: (context, idx) => InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: InteractiveViewer(
                            child: Image.network(
                              artisan.galleryImageUrls![idx],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      child: Image.network(artisan.galleryImageUrls![idx], width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
