import 'package:flutter/material.dart';
import '../models/artisan.dart';
import '../ui/app_theme.dart';

class ArtisanDetail extends StatelessWidget {
  final Artisan artisan;
  final String? currentUserEmail;

  const ArtisanDetail({Key? key, required this.artisan, this.currentUserEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artisan Detail')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: artisan.profileImageUrl != null
                      ? NetworkImage(artisan.profileImageUrlWithCache ?? artisan.profileImageUrl!)
                      : null,
                  child: artisan.profileImageUrl == null ? const Icon(Icons.person, size: 32) : null,
                ),
                const SizedBox(width: AppTheme.spaceBase),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(artisan.fullName, style: AppTheme.headline3),
                    if (artisan.businessName != null) Text(artisan.businessName!, style: AppTheme.bodyMedium),
                    Text(artisan.category, style: AppTheme.labelMedium.copyWith(color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceBase),
            if (artisan.bio != null) ...[
              Text('Bio:', style: AppTheme.titleSmall),
              Text(artisan.bio!, style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceSM),
            ],
            if (artisan.address != null) ...[
              Text('Address:', style: AppTheme.titleSmall),
              Text(artisan.address!, style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spaceSM),
            ],
            Text('Phone: ${artisan.phone}', style: AppTheme.bodyMedium),
            if (artisan.whatsapp != null) Text('WhatsApp: ${artisan.whatsapp}', style: AppTheme.bodyMedium),
            if (currentUserEmail != null && artisan.email == currentUserEmail)
              Text('Email: ${artisan.email}', style: AppTheme.bodyMedium),
            if (artisan.galleryImageUrls != null && artisan.galleryImageUrls!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceBase),
              Text('Gallery:', style: AppTheme.titleSmall),
              const SizedBox(height: AppTheme.spaceSM),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artisan.galleryImageUrls!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSM),
                  itemBuilder: (context, idx) => GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: StatefulBuilder(
                            builder: (context, setStateDialog) {
                              int currentIndex = idx;
                              return SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.height * 0.8,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: PageView.builder(
                                        controller: PageController(initialPage: currentIndex),
                                        itemCount: artisan.galleryImageUrls!.length,
                                        onPageChanged: (newIdx) {
                                          setStateDialog(() {
                                            currentIndex = newIdx;
                                          });
                                        },
                                        itemBuilder: (context, pageIdx) {
                                          return InteractiveViewer(
                                            child: Image.network(
                                              artisan.galleryImageUrls![pageIdx],
                                              fit: BoxFit.contain,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: AppTheme.spaceSM,
                                      right: AppTheme.spaceSM,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
