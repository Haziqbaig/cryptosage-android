import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0A0E17);
  static const surface = Color(0xFF111827);
  static const card = Color(0xFF151C2C);
  static const cyan = Color(0xFF22D3EE);
  static const violet = Color(0xFF8B5CF6);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);
  static const yellow = Color(0xFFFBBF24);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.cyan,
    brightness: brightness,
    primary: AppColors.cyan,
    secondary: AppColors.violet,
    surface: dark ? AppColors.surface : Colors.white,
  );
  final textTheme = GoogleFonts.interTextTheme(
    dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: base,
    scaffoldBackgroundColor: dark ? AppColors.bg : const Color(0xFFF4F6FA),
    textTheme: textTheme.copyWith(
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        color: dark ? AppColors.textPrimary : Colors.black87,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        color: dark ? AppColors.textPrimary : Colors.black87,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: dark ? AppColors.textPrimary : Colors.black87,
      ),
    ),
    cardTheme: CardThemeData(
      color: dark ? AppColors.card.withOpacity(0.7) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? Colors.white.withOpacity(0.06) : Colors.black12,
        ),
      ),
    ),
    dividerColor: Colors.white10,
  );
}
