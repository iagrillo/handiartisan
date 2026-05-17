import 'package:flutter/material.dart';

class BlueOnyxTheme {
  BlueOnyxTheme._();

  static const Color primary = Color(0xFF2F6FA3);
  static const Color secondary = Color(0xFF4A90C2);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0A1624);
  static const Color cardColor = Color(0xFF16314D);
  static const Color divider = Color(0xFFE4E7EC);
  static const Color heading = Color(0xFF101828);
  static const Color body = Color(0xFF475467);
  static const Color muted = Color(0xFF98A2B3);
  static const Color primaryDeep = Color(0xFF0F2236);
  static const Color primarySoft = Color(0xFF7FB3D5);
  static const Color primaryLight = Color(0xFFE8F1F8);
  static const Color softSurface = Color(0xFFEFF4FA);
  static const Color categoryBadge = Color(0xFFEAF2F8);
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color error = Color(0xFFD92D20);
  static const Color info = Color(0xFF4A90C2);
  static const Color ratingStar = Color(0xFFFBBF24);
  static const Color whatsapp = Color(0xFF25D366);

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: surface,
    onSurface: heading,
    outline: divider,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primarySoft,
    onPrimary: darkBackground,
    secondary: secondary,
    onSecondary: Colors.white,
    error: Color(0xFFF97066),
    onError: darkBackground,
    surface: cardColor,
    onSurface: Colors.white,
    outline: Color(0xFF284B6A),
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0F2236),
      Color(0xFF2F6FA3),
      Color(0xFF7FB3D5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [
      Color(0xFF2F6FA3),
      Color(0xFF4A90C2),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const String fontFamily = 'Inter';

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: body, fontFamily: fontFamily),
        bodyMedium: TextStyle(color: body, fontFamily: fontFamily),
        bodySmall: TextStyle(color: body, fontFamily: fontFamily),
        labelLarge: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600),
        labelMedium: TextStyle(
            color: heading,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w500),
        labelSmall: TextStyle(
            color: body, fontFamily: fontFamily, fontWeight: FontWeight.w500),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: background,
        cardColor: surface,
        dividerColor: divider,
        textTheme: textTheme,
        primaryColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: heading,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: heading,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
          iconTheme: IconThemeData(color: heading),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: primary.withValues(alpha: 0.24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              color: primary,
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          hintStyle: const TextStyle(color: muted),
          labelStyle: const TextStyle(color: body),
          prefixIconColor: body,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 6,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: muted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: softSurface,
          selectedColor: primaryLight,
          labelStyle: const TextStyle(
            color: heading,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          side: BorderSide.none,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: body,
          indicatorColor: primary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkBackground,
          contentTextStyle:
              const TextStyle(color: Colors.white, fontFamily: fontFamily),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
            color: heading,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
          contentTextStyle:
              const TextStyle(color: body, fontFamily: fontFamily),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(color: divider),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: primary),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return muted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primary.withValues(alpha: 0.28);
            }
            return divider;
          }),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkBackground,
        cardColor: cardColor,
        dividerColor: darkColorScheme.outline,
        textTheme: textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      );
}
