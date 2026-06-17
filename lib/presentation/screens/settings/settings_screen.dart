import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../providers/mood_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glassmorphic_card.dart';

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
        centerTitle: false,
        title: Text(
          AppStrings.settings,
          style: AppTextStyles.headlineMedium(color: textColor).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: AppDimensions.sp8,
        ),
        children: [
          // ── Appearance Section ─────────────────────────────────────────
          _SectionHeader(title: 'Appearance', textColor: subtextColor),
          const SizedBox(height: AppDimensions.sp12),
          GlassmorphicCard(
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme choice
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: AppTextStyles.titleMedium(color: textColor).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ThemeSelectionCard(
                            isSelected: themeMode == ThemeMode.light,
                            icon: FontAwesomeIcons.sun,
                            label: 'Light',
                            accentColor: accentColor,
                            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                          ),
                          const SizedBox(width: 10),
                          _ThemeSelectionCard(
                            isSelected: themeMode == ThemeMode.system,
                            icon: FontAwesomeIcons.mobileScreen,
                            label: 'System',
                            accentColor: accentColor,
                            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                          ),
                          const SizedBox(width: 10),
                          _ThemeSelectionCard(
                            isSelected: themeMode == ThemeMode.dark,
                            icon: FontAwesomeIcons.moon,
                            label: 'Dark',
                            accentColor: accentColor,
                            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Mood choice
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.defaultMood,
                        style: AppTextStyles.titleMedium(color: textColor).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MoodType.values.map((m) {
                          return _MoodCapsuleButton(
                            mood: m,
                            isSelected: mood == m,
                            accentColor: accentColor,
                            label: _moodLabel(m),
                            onTap: () => ref.read(moodProvider.notifier).setMood(m),
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

          // ── Playback Section ───────────────────────────────────────────
          _SectionHeader(title: 'Playback', textColor: subtextColor),
          const SizedBox(height: AppDimensions.sp12),
          GlassmorphicCard(
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: FontAwesomeIcons.music,
              iconBgColor: accentColor.withOpacity(0.12),
              iconColor: accentColor,
              title: AppStrings.audioFocusBehavior,
              subtitle: 'Pause music when other apps take focus',
              trailing: Switch.adaptive(
                value: _audioFocusPause,
                activeColor: accentColor,
                onChanged: _setAudioFocusPause,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sp24),

          // ── About Section ──────────────────────────────────────────────
          _SectionHeader(title: AppStrings.about, textColor: subtextColor),
          const SizedBox(height: AppDimensions.sp12),
          GlassmorphicCard(
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: FontAwesomeIcons.circleInfo,
                  iconBgColor: accentColor.withOpacity(0.12),
                  iconColor: accentColor,
                  title: AppStrings.appName,
                  subtitle: 'Version $_version (build $_build)',
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: FontAwesomeIcons.bug,
                  iconBgColor: accentColor.withOpacity(0.12),
                  iconColor: accentColor,
                  title: AppStrings.errorLog,
                  subtitle: 'View recent playback errors',
                  trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
                  onTap: () => _showErrorLog(
                    context,
                    surfaceColor,
                    textColor,
                    subtextColor,
                    accentColor,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 180),
        ],
      ),
    );
  }

  void _showErrorLog(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color accentColor,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(AppDimensions.sp16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBottomSheet),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.sp12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.errorLog,
                    style: AppTextStyles.titleLarge(color: textColor).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const FaIcon(FontAwesomeIcons.trashCan, size: 12, color: Colors.red),
                    label: const Text(
                      'Clear Logs',
                      style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.circleCheck,
                        color: accentColor,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No errors logged.',
                    style: AppTextStyles.titleMedium(color: textColor).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Everything is running smoothly without issues.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(color: subtextColor),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    foregroundColor: textColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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

class _ThemeSelectionCard extends StatelessWidget {
  final bool isSelected;
  final FaIconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeSelectionCard({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : (isDark ? Colors.white10 : Colors.black12),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: isSelected
                  ? accentColor.withOpacity(0.08)
                  : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01)),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      FaIcon(
                        icon,
                        color: isSelected ? accentColor : (isDark ? Colors.white60 : Colors.black54),
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: AppTextStyles.labelSmall(
                          color: isSelected ? accentColor : (isDark ? Colors.white70 : Colors.black87),
                        ).copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodCapsuleButton extends StatelessWidget {
  final MoodType mood;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final String label;

  const _MoodCapsuleButton({
    required this.mood,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodColors = MoodTheme.of(mood);
    final moodBg = moodColors.backgroundFor(Theme.of(context).brightness);
    final moodAccent = moodColors.accent;

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: moodAccent.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [moodAccent, moodAccent.withOpacity(0.75)]
                        : [
                            isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                            isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? moodAccent
                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      _moodIcon(mood),
                      color: isSelected ? Colors.white : moodAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTextStyles.labelSmall(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ).copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  FaIconData _moodIcon(MoodType mood) => switch (mood) {
        MoodType.calm => FontAwesomeIcons.mugHot,
        MoodType.sad => FontAwesomeIcons.cloudRain,
        MoodType.energetic => FontAwesomeIcons.bolt,
        MoodType.night => FontAwesomeIcons.moon,
        MoodType.focus => FontAwesomeIcons.brain,
      };
}

class _SettingsTile extends StatelessWidget {
  final FaIconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FaIcon(icon, color: iconColor, size: 14),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium(color: textColor).copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodyMedium(color: subtextColor),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
