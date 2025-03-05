import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF2C2C2C);
  static const backgroundColor = Color(0xFF1E1E1E);

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
    ),
    cardTheme: const CardTheme(
      color: primaryColor,
    ),
  );
}