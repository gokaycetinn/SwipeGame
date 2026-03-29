import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF08131E);
  static const panel = Color(0xFF1A2431);
  static const panelSoft = Color(0x991D2735);
  static const hotPink = Color(0xFFFF5E8D);
  static const neonGreen = Color(0xFF31E07F);
  static const amber = Color(0xFFF3D648);
  static const text = Color(0xFFF2F5F7);
  static const textMuted = Color(0xFF93A0AF);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.bebasNeue(
        fontSize: 64,
        letterSpacing: 1.2,
        color: AppColors.text,
      ),
      displayMedium: GoogleFonts.bebasNeue(
        fontSize: 46,
        letterSpacing: 1.0,
        color: AppColors.text,
      ),
      headlineLarge: GoogleFonts.sairaCondensed(
        fontWeight: FontWeight.w800,
        fontSize: 42,
        letterSpacing: 0.8,
        color: AppColors.text,
      ),
      titleLarge: GoogleFonts.sairaCondensed(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: 0.5,
        color: AppColors.text,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.hotPink,
        secondary: AppColors.neonGreen,
      ),
    );
  }
}
