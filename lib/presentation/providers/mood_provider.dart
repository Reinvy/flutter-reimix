import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/mood_theme.dart';
import '../../main.dart' show objectBox;

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Controls the currently selected mood.
///
/// Persists the active mood to ObjectBox [AppSettings] so it survives restarts.
class MoodNotifier extends StateNotifier<MoodType> {
  MoodNotifier() : super(_loadInitial());

  /// Named constructor used in tests to bypass ObjectBox initialisation.
  MoodNotifier.withInitialState(super.initial);

  static MoodType _loadInitial() {
    final settings = objectBox.getSettings();
    return _fromString(settings.activeMood);
  }

  static MoodType _fromString(String s) {
    return MoodType.values.firstWhere((m) => m.name == s, orElse: () => MoodType.calm);
  }

  void setMood(MoodType mood) {
    state = mood;
    final settings = objectBox.getSettings();
    settings.activeMood = mood.name;
    objectBox.settingsBox.put(settings);
  }

  /// Sets the mood without persisting to ObjectBox. Used in tests.
  void setMoodWithoutPersistence(MoodType mood) {
    state = mood;
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodType>((ref) => MoodNotifier());
