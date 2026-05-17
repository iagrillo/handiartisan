import 'package:flutter/material.dart';
import 'dart:async';
import '../../ui/app_theme.dart';

class FeaturedEquipmentCarousel extends StatefulWidget {
  final List<String> images;
  const FeaturedEquipmentCarousel({Key? key, required this.images}) : super(key: key);

  @override
  State<FeaturedEquipmentCarousel> createState() => _FeaturedEquipmentCarouselState();
}

class _FeaturedEquipmentCarouselState extends State<FeaturedEquipmentCarousel> {
    late final Timer _timer;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 3) % widget.images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 3) % widget.images.length;
    });
  }

  void _prev() {
    setState(() {
      _currentIndex = (_currentIndex - 3 + widget.images.length) % widget.images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleImages = List<String>.generate(3, (i) => widget.images[(i + _currentIndex) % widget.images.length]);
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...visibleImages.map((img) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    child: _AssetImage(
                      assetPath: img,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          "HANDIHUB GLOBAL | CONMAT's Definitive Voice in Nigeria",
          style: AppTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A custom Image widget that handles asset loading errors gracefully
/// This fixes the "unable to load asset" issue in Chrome
class _AssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const _AssetImage({
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Log the error for debugging
        debugPrint('Failed to load asset: $assetPath - Error: $error');
        
        // Return a fallback container with an icon
        return Container(
          width: width,
          height: height,
          color: AppTheme.inputFill,
          child: Icon(
            Icons.construction,
            size: (width ?? 100) * 0.4,
            color: AppTheme.textTertiary,
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: frame != null
              ? child
              : Container(
                  width: width,
                  height: height,
                  color: AppTheme.chipBackground,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        );
      },
    );
  }
}
