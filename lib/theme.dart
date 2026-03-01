import 'package:flutter/material.dart';

class AppTheme {
  // --- BRAND COLORS ---
  static const Color background = Color(0xFF000000); // Pure Black
  
  // ✅ UPDATED: Exact Deep Plum color from your screenshot (#47243C)
  static const Color primaryPlum = Color(0xFF47243C); 

  // Map other colors to Plum so widgets update automatically
  static const Color primaryBlue = primaryPlum; 
  static const Color cardColor = primaryPlum; 

  static const Color accentGreen = Color(0xFF00E676);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E9E9E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryPlum,
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryPlum,
        surface: background, 
        onSurface: textWhite,
        secondary: primaryPlum,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textWhite),
        titleTextStyle: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: textWhite
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor, 
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12, width: 1), 
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: background, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: primaryPlum, width: 2), 
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPlum, 
          foregroundColor: textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryPlum, 
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24, width: 1),
        ),
      ),

      // Bottom Sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        modalBackgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}