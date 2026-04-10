import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../providers/mood_provider.dart';
import '../../providers/theme_provider.dart';

const _kAudioFocusKey = 'audio_focus_pause_on_interrupt';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '—';
  String _build = '—';
  bool _audioFocusPause = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadAudioFocusPref();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _build = info.buildNumber;
      });
    }
  }

  Future<void> _loadAudioFocusPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _audioFocusPause = prefs.getBool(_kAudioFocusKey) ?? true);
    }
  }

  Future<void> _setAudioFocusPause(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAudioFocusKey, value);
    if (mounted) setState(() => _audioFocusPause = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final accentColor = Theme.of(context).colorScheme.tertiary;
    final themeMode = ref.watch(themeProvider);
    final mood = ref.watch(moodProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(AppStrings.settings, style: AppTextStyles.headlineMedium(color: textColor)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: AppDimensions.sp16,
        ),
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance', textColor: subtextColor),
          const SizedBox(height: AppDimensions.sp12),
          _SettingsCard(
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.sp16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: AppTextStyles.titleMedium(color: textColor)),
                      const SizedBox(height: AppDimensions.sp12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.phone_android_rounded),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (set) =>
                            ref.read(themeProvider.notifier).setTheme(set.first),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) return accentColor;
                            return Colors.transparent;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColorsLight.divider),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.sp16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.defaultMood,
                        style: AppTextStyles.titleMedium(color: textColor),
                      ),
                      const SizedBox(height: AppDimensions.sp12),
                      Wrap(
                        spacing: AppDimensions.sp8,
                        runSpacing: AppDimensions.sp8,
                        children: MoodType.values.map((m) {
                          final selected = mood == m;
                          final moodColors = MoodTheme.of(m);
                          return ChoiceChip(
                            label: Text(_moodLabel(m)),
                            selected: selected,
                            selectedColor: moodColors.accent,
                            onSelected: (_) => ref.read(moodProvider.notifier).setMood(m),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sp24),

          // ── Playback ────────────────────────────────────────────────────
          _SectionHeader(title: 'Playback', textColor: subtextColor),
          const SizedBox(height: AppDimensions.sp12),
          _SettingsCard(
            color: surfaceColor,
            child: SwitchListTile(
              title: Text(
                AppStrings.audioFocusBehavior,
                style: AppTextStyles.titleMedium(color: textColor),
              ),
              subtitle: Text(
                'Pause music when a call or other app takes audio focus',
                style: AppTextStyles.bodyMedium(color: subtextColor),
              ),
              value: _audioFocusPause,
              activeThumbColor: accentColor,
              onChanged: _setAudioFocusPause,
            ),
          ),
          const SizedBox(height: AppDimensions.sp24),

          // ── About ──────────────────────────────────────────────────────
          _SectionHeader(title: AppStrings.about, textColor: subtextColor),
          const SizedBox(height: AppDimensions.sp12),
          _SettingsCard(
            color: surfaceColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.music_note_rounded, color: accentColor),
                  title: Text(
                    AppStrings.appName,
                    style: AppTextStyles.titleMedium(color: textColor),
                  ),
                  subtitle: Text(
                    'Version $_version (build $_build)',
                    style: AppTextStyles.bodyMedium(color: subtextColor),
                  ),
                ),
                const Divider(height: 1, color: AppColorsLight.divider),
                ListTile(
                  leading: Icon(Icons.bug_report_outlined, color: accentColor),
                  trailing: Icon(Icons.chevron_right_rounded, color: subtextColor),
                  title: Text(
                    AppStrings.errorLog,
                    style: AppTextStyles.titleMedium(color: textColor),
                  ),
                  subtitle: Text(
                    'View recent playback errors',
                    style: AppTextStyles.bodyMedium(color: subtextColor),
                  ),
                  onTap: () => _showErrorLog(context, surfaceColor, textColor, subtextColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sp32),
        ],
      ),
    );
  }

  void _showErrorLog(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(AppDimensions.sp16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBottomSheet),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.sp12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColorsLight.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.sp16),
              child: Text(AppStrings.errorLog, style: AppTextStyles.titleLarge(color: textColor)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.sp16,
                0,
                AppDimensions.sp16,
                AppDimensions.sp24,
              ),
              child: Text(
                'No errors logged.',
                style: AppTextStyles.bodyMedium(color: subtextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _moodLabel(MoodType mood) => switch (mood) {
    MoodType.calm => AppStrings.moodCalm,
    MoodType.sad => AppStrings.moodSad,
    MoodType.energetic => AppStrings.moodEnergetic,
    MoodType.night => AppStrings.moodNight,
    MoodType.focus => AppStrings.moodFocus,
  };
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textColor;
  const _SectionHeader({required this.title, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.sp4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium(color: textColor).copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _SettingsCard({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(AppDimensions.radiusCard), child: child),
    );
  }
}
