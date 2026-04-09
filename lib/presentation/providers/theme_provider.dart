import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the app-wide ThemeMode (light / dark / system).
/// Persisted to ObjectBox AppSettings in later steps when the settings
/// screen is built.
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
