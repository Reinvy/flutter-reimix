import 'dart:convert';
import 'package:objectbox/objectbox.dart';

/// Singleton settings entity
@Entity()
class AppSettings {
  @Id()
  int id = 0;

  /// 'light' | 'dark' | 'system'
  String themeMode = 'system';

  /// 'calm' | 'sad' | 'energetic' | 'night' | 'focus'
  String activeMood = 'calm';

  bool sakuraModeEnabled = true;
  bool equalizerEnabled = false;
  int sleepTimerMinutes = 0;
  double volumeLevel = 1.0;

  /// 'off' | 'all' | 'one'
  String repeatMode = 'off';

  bool shuffleEnabled = false;
  bool onboardingComplete = false;

  int scanMinDurationSeconds = 30;
  
  /// Serialized JSON array of folder paths to exclude from scanning.
  String excludedFoldersRaw = '[]';

  @Transient()
  List<String> get excludedFolders {
    try {
      return List<String>.from(jsonDecode(excludedFoldersRaw));
    } catch (_) {
      return [];
    }
  }

  @Transient()
  set excludedFolders(List<String> list) {
    excludedFoldersRaw = jsonEncode(list);
  }
}
