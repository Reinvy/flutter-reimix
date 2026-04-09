import 'package:flutter/material.dart';

/// The five mood types supported by Reimix
enum MoodType { calm, sad, energetic, night, focus }

/// Per-mood color overrides applied on top of the base theme
class MoodTheme {
  MoodTheme._();

  static MoodColors of(MoodType mood) {
    switch (mood) {
      case MoodType.calm:
        return const MoodColors(
          lightBackground: Color(0xFFFFF5F7),
          darkBackground: Color(0xFF1E1A1D),
          accent: Color(0xFFFF8DAA),
        );
      case MoodType.sad:
        return const MoodColors(
          lightBackground: Color(0xFFF0F4FF),
          darkBackground: Color(0xFF1A1C2E),
          accent: Color(0xFF8DA8FF),
        );
      case MoodType.energetic:
        return const MoodColors(
          lightBackground: Color(0xFFFFF8F0),
          darkBackground: Color(0xFF1E1A10),
          accent: Color(0xFFFF7043),
        );
      case MoodType.night:
        return const MoodColors(
          lightBackground: Color(0xFFF0EFF8),
          darkBackground: Color(0xFF0D0F14),
          accent: Color(0xFF9B8EC4),
        );
      case MoodType.focus:
        return const MoodColors(
          lightBackground: Color(0xFFF4F9F4),
          darkBackground: Color(0xFF141A14),
          accent: Color(0xFF5BAF7A),
        );
    }
  }
}

/// Color overrides for a single mood state
class MoodColors {
  final Color lightBackground;
  final Color darkBackground;
  final Color accent;

  const MoodColors({
    required this.lightBackground,
    required this.darkBackground,
    required this.accent,
  });

  Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.light ? lightBackground : darkBackground;
}
