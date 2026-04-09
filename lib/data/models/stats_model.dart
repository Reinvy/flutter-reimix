import 'package:objectbox/objectbox.dart';

/// Singleton settings entity (always id = 1)
@Entity()
class AppSettings {
  @Id()
  int id = 1;

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
}
