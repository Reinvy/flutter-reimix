import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Nunito-based typography scale
class AppTextStyles {
  AppTextStyles._();

  static TextStyle headlineLarge({Color? color}) => GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color ?? AppColorsLight.onBackground,
  );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color ?? AppColorsLight.onBackground,
  );

  static TextStyle titleLarge({Color? color}) => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color ?? AppColorsLight.onBackground,
  );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color ?? AppColorsLight.onBackground,
  );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? AppColorsLight.subtext,
  );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? AppColorsLight.subtext,
  );
}
