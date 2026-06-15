import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Colors.blue;
  static const Color error = Colors.red;
  static const Color textSecondary = Colors.black54;
  static const double spaceXXS = 2;
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double radiusFull = 100;
  static const List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  static const TextStyle caption = TextStyle(fontSize: 12);
  static const TextStyle titleLarge =
      TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  static const TextStyle bodyMedium = TextStyle(fontSize: 16);
}
