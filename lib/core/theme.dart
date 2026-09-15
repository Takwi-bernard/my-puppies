import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette pulled from the reference design: punchy orange accent, near-black
/// bars/footer, warm cream section backgrounds. Distinct from Wagfound's
/// teal/amber on purpose — this is a different brand.
class AppColors {
  static const Color orange = Color(0xFFF2871E); // primary accent / CTAs
  static const Color orangeDark = Color(0xFFD9720F); // hover/pressed states
  static const Color black = Color(0xFF161513); // navbar strip, footer
  static const Color charcoal = Color(0xFF2A2622); // body text
  static const Color cream = Color(0xFFF6F1E6); // section backgrounds
  static const Color white = Color(0xFFFFFFFF);
}

ThemeData buildMyPuppiesTheme() {
  final headingFont = GoogleFonts.oswaldTextTheme();
  final bodyFont = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      secondary: AppColors.black,
      surface: AppColors.white,
    ),
    textTheme: bodyFont.copyWith(
      displayLarge: headingFont.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
        letterSpacing: 0.5,
      ),
      displayMedium: headingFont.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      headlineLarge: headingFont.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      headlineMedium: headingFont.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.charcoal,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.charcoal),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.charcoal,
        side: const BorderSide(color: AppColors.charcoal),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
      ),
    ),
  );
}

/// Bold, condensed heading style used for the big poster-style headlines
/// throughout the reference design (e.g. "TOGETHER WE CAN CLEAR THE
/// SHELTERS"). Use directly where TextTheme doesn't fit.
TextStyle posterHeadline({double fontSize = 40, Color color = AppColors.charcoal}) {
  return GoogleFonts.oswald(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.05,
  );
}