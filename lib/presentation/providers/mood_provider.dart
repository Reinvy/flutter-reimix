import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/mood_theme.dart';

/// Controls the currently selected mood.
/// Driving force behind per-mood color overrides and background animations.
final moodProvider = StateProvider<MoodType>((ref) => MoodType.calm);
