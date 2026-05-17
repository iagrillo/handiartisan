import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

/// A custom Image widget that handles asset loading errors gracefully.
/// This fixes the "unable to load asset" issue in Chrome/web builds.
class AssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final Color? fallbackBackgroundColor;

  const AssetImage({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
    this.fallbackIcon = Icons.construction,
    this.fallbackIconColor,
    this.fallbackBackgroundColor,
  }) : super(key: key);

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
          color: fallbackBackgroundColor ?? AppTheme.inputFill,
          child: Center(
            child: Icon(
              fallbackIcon,
              size: (width ?? height ?? 100) * 0.4,
              color: fallbackIconColor ?? AppTheme.textTertiary,
            ),
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
                  color: fallbackBackgroundColor ?? AppTheme.primaryLight,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        );
      },
    );
  }
}

/// A simpler wrapper that just adds error handling to Image.asset
/// Use this for quick fixes without changing the API
class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const SafeAssetImage({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Failed to load asset: $assetPath - Error: $error');
        return Container(
          width: width,
          height: height,
          color: AppTheme.inputFill,
          child: Icon(
            Icons.image_not_supported,
            size: (width ?? height ?? 50) * 0.4,
            color: AppTheme.textTertiary,
          ),
        );
      },
    );
  }
}
