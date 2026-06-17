import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' show objectBox;

/// Controls the app-wide ThemeMode (light / dark / system).
/// Persists the selection to ObjectBox [AppSettings].
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final settings = objectBox.getSettings();
    return switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    final settings = objectBox.getSettings();
    settings.themeMode = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    objectBox.settingsBox.put(settings);
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(),
);
