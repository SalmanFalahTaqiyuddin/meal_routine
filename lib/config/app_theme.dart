import 'package:flutter/material.dart';

class AppTheme {
  // ── Warna (Update ke 0xFF285B45) ───────────────────
  static const Color primaryGreen = Color(0xFF285B45);
  static const Color lightGreen = Color(0xFF6B9E8F);
  static const Color backgroundColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color borderColor = Color(0xFFE0E0E0);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
    ),

    // Font Utama
    fontFamily: 'SF Pro',

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryGreen),
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro',
        color: primaryGreen,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen, // Kotak warna Primary Green
        foregroundColor: Colors.white, // Tulisan warna Putih
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // TextField / InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: textHint, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    ),

    // Text Styles
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: primaryGreen,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: primaryGreen,
        height: 1.15,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 14,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'SF Pro',
        fontSize: 13,
        color: textSecondary,
      ),
    ),
  );
}
