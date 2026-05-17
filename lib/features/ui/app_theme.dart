import 'package:flutter/material.dart';

import '../../theme/blue_onyx_theme.dart';

class AppTheme {
  AppTheme._();

  // ─── Colors ───────────────────────────────────────────────
  static const Color primary = BlueOnyxTheme.primary;
  static const Color primaryDark = BlueOnyxTheme.primaryDeep;
  static const Color primaryLight = BlueOnyxTheme.primaryLight;
  static const Color secondary = BlueOnyxTheme.secondary;
  static const Color background = BlueOnyxTheme.background;
  static const Color surface = BlueOnyxTheme.surface;
  static const Color textPrimary = BlueOnyxTheme.heading;
  static const Color textSecondary = BlueOnyxTheme.body;
  static const Color textTertiary = BlueOnyxTheme.muted;
  static const Color divider = BlueOnyxTheme.divider;
  static const Color error = BlueOnyxTheme.error;
  static const Color success = BlueOnyxTheme.success;
  static const Color warning = BlueOnyxTheme.warning;
  static const Color info = BlueOnyxTheme.info;

  // Semantic aliases
  static const Color appBarBackground = surface;
  static const Color appBarForeground = textPrimary;
  static const Color cardBackground = surface;
  static const Color scaffoldBackground = background;
  static const Color inputFill = BlueOnyxTheme.background;
  static const Color inputBorder = BlueOnyxTheme.divider;
  static const Color inputFocusBorder = BlueOnyxTheme.primary;
  static const Color chipBackground = BlueOnyxTheme.softSurface;
  static const Color shadowColor = BlueOnyxTheme.darkBackground;

  // Status colors
  static const Color statusAvailable = success;
  static const Color statusBusy = error;
  static const Color statusOpen = success;
  static const Color statusClosed = error;
  static const Color statusPending = warning;
  static const Color statusVerified = primary;

  // Category badge
  static const Color categoryBadgeBg = BlueOnyxTheme.categoryBadge;
  static const Color categoryBadgeText = BlueOnyxTheme.primary;

  // Rating
  static const Color ratingStar = BlueOnyxTheme.ratingStar;

  // WhatsApp
  static const Color whatsapp = BlueOnyxTheme.whatsapp;

  // ─── Spacing (8px grid) ───────────────────────────────────
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceBase = 16.0;
  static const double spaceLG = 20.0;
  static const double spaceXL = 24.0;
  static const double space2XL = 32.0;
  static const double space3XL = 40.0;
  static const double space4XL = 48.0;

  // ─── Border Radius ────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 9999.0;

  // ─── Shadows ──────────────────────────────────────────────
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // ─── Typography ───────────────────────────────────────────
  static const String fontFamily = BlueOnyxTheme.fontFamily;

  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.3,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    fontFamily: fontFamily,
    height: 1.4,
  );

  // ─── ThemeData ────────────────────────────────────────────
  static ThemeData get lightTheme => BlueOnyxTheme.lightTheme;
  static ThemeData get darkTheme => BlueOnyxTheme.darkTheme;

  // ─── Gradient Helpers ─────────────────────────────────────
  static LinearGradient get primaryGradient => BlueOnyxTheme.primaryGradient;
  static LinearGradient get ctaGradient => BlueOnyxTheme.ctaGradient;

  static LinearGradient get subtleGradient => BlueOnyxTheme.subtleGradient;

  // ─── Status Badge Helper ──────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'arrival_confirmed':
        return success;
      case 'estimate_pending':
      case 'outcall_confirmed':
        return primary;
      case 'pending':
        return warning;
      case 'cancelled':
      case 'rejected':
        return error;
      case 'pending_completion':
      case 'pending_completion_confirmation':
        return info;
      default:
        return textSecondary;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'arrival_confirmed':
        return 'Arrived';
      case 'estimate_pending':
      case 'outcall_confirmed':
        return 'Outcall Confirmed';
      case 'pending_completion':
      case 'pending_completion_confirmation':
        return 'Finishing Up';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return status
            .split('_')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
            .join(' ');
    }
  }

  // ─── Page Transition ──────────────────────────────────────
  static PageRouteBuilder<T> fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
