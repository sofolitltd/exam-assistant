import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF005C53);
  static const Color secondaryColor = Color(0xFF1A237E);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFC62828);

  static TextStyle get _googleSans => GoogleFonts.getFont('Google Sans');

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: _googleSans.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      textTheme: TextTheme(
        displayLarge: _googleSans,
        displayMedium: _googleSans,
        displaySmall: _googleSans,
        headlineLarge: _googleSans,
        headlineMedium: _googleSans,
        headlineSmall: _googleSans,
        titleLarge: _googleSans.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: _googleSans,
        titleSmall: _googleSans,
        bodyLarge: _googleSans.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: _googleSans,
        bodySmall: _googleSans,
        labelLarge: _googleSans,
        labelMedium: _googleSans,
        labelSmall: _googleSans,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: _googleSans.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: _googleSans.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: primaryColor),
          textStyle: _googleSans.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: _googleSans,
        hintStyle: _googleSans,
        errorStyle: _googleSans,
      ),
      chipTheme: ChipThemeData(
        labelStyle: _googleSans,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
