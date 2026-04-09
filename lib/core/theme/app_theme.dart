import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.background,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.primary,
      secondary: AppColorsLight.secondary,
      tertiary: AppColorsLight.accent,
      surface: AppColorsLight.surface,
      onPrimary: AppColorsLight.onPrimary,
      onSurface: AppColorsLight.onBackground,
    ),
    textTheme: _textTheme(AppColorsLight.onBackground, AppColorsLight.subtext),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsLight.background,
      foregroundColor: AppColorsLight.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColorsLight.onBackground,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColorsLight.surface,
      selectedItemColor: AppColorsLight.accent,
      unselectedItemColor: AppColorsLight.subtext,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: const CardThemeData(
      color: AppColorsLight.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusCard)),
      ),
    ),
    dividerColor: AppColorsLight.divider,
    chipTheme: ChipThemeData(
      backgroundColor: AppColorsLight.primary,
      selectedColor: AppColorsLight.accent,
      labelStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColorsLight.onPrimary,
      ),
      shape: const StadiumBorder(),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColorsLight.accent,
      inactiveTrackColor: AppColorsLight.divider,
      thumbColor: AppColorsLight.accent,
      overlayColor: Color(0x1AFF8DAA),
    ),
    iconTheme: const IconThemeData(
      color: AppColorsLight.onBackground,
      size: AppDimensions.iconAction,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      surface: AppColorsDark.surface,
      tertiary: AppColorsDark.accent,
      onSurface: AppColorsDark.onBackground,
    ),
    textTheme: _textTheme(AppColorsDark.onBackground, AppColorsDark.subtext),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.background,
      foregroundColor: AppColorsDark.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColorsDark.onBackground,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColorsDark.surface,
      selectedItemColor: AppColorsDark.accent,
      unselectedItemColor: AppColorsDark.subtext,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: const CardThemeData(
      color: AppColorsDark.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusCard)),
      ),
    ),
    dividerColor: AppColorsDark.surface,
    chipTheme: ChipThemeData(
      backgroundColor: AppColorsDark.primary,
      selectedColor: AppColorsDark.accent,
      labelStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColorsDark.onBackground,
      ),
      shape: const StadiumBorder(),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColorsDark.accent,
      inactiveTrackColor: AppColorsDark.surface,
      thumbColor: AppColorsDark.accent,
      overlayColor: Color(0x1AFF8DAA),
    ),
    iconTheme: const IconThemeData(
      color: AppColorsDark.onBackground,
      size: AppDimensions.iconAction,
    ),
  );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    headlineLarge: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
    headlineMedium: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
    titleLarge: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
    titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
    bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
    bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
    labelSmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
  );
}
