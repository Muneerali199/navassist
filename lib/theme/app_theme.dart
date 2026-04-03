import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Neon Colors
  static const Color primaryBlue = Color(0xFF00F0FF); // Cyan Cyber
  static const Color accentPurple = Color(0xFFBD00FF); // Vivid Purple
  static const Color dangerRed = Color(0xFFFF0055); // Neon Pink-Red
  static const Color safeGreen = Color(0xFF00FF73); // Matrix Green
  static const Color warningYellow = Color(0xFFFFD600);
  
  // Sleek Dark Backgrounds
  static const Color backgroundBlack = Color(0xFF070709); // Near Black
  static const Color surfaceDark = Color(0xFF141419);
  static const Color glassPanel = Color(0x331E1E28); // Translucent
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundBlack,
      primaryColor: primaryBlue,
      cardColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentPurple,
        surface: surfaceDark,
        error: dangerRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.2),
        displayMedium: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
        bodyLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: backgroundBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 36),
          textStyle: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          elevation: 12,
          shadowColor: primaryBlue.withOpacity(0.5),
        ),
      ),
    );
  }
}
