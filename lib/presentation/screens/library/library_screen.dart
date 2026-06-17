import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/mood_provider.dart';
import 'songs_tab.dart';
import 'albums_tab.dart';
import 'artists_tab.dart';
import 'folders_tab.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    // Mood-specific styles
    final selectedMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(selectedMood);
    final moodBg = moodColors.backgroundFor(Theme.of(context).brightness);
    final moodAccent = moodColors.accent;

    final libraryState = ref.watch(libraryProvider);
    final showPermissionBanner = libraryState.hasError;
    final isLoading = libraryState.isLoading;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                moodBg.withAlpha(180),
                bgColor,
              ],
              stops: const [0.0, 0.4],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Custom Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPaddingH,
                    AppDimensions.sp20,
                    AppDimensions.screenPaddingH,
                    AppDimensions.sp12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Library',
                                  style: AppTextStyles.headlineLarge(color: textColor).copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: moodAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: moodAccent.withAlpha(150),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All your local music in one place',
                              style: AppTextStyles.bodyMedium(color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                      _LibraryScanButton(isLoading: isLoading, accentColor: moodAccent),
                    ],
                  ),
                ),

                // ── Tab Bar (Capsule Style) ───────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                    vertical: AppDimensions.sp8,
                  ),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColorsDark.surface.withAlpha(150) : AppColorsLight.surface.withAlpha(150),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: moodAccent.withAlpha(40),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: moodAccent,
                      boxShadow: [
                        BoxShadow(
                          color: moodAccent.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: subtextColor,
                    labelStyle: AppTextStyles.labelSmall().copyWith(fontWeight: FontWeight.w800),
                    unselectedLabelStyle: AppTextStyles.labelSmall().copyWith(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: AppStrings.songs),
                      Tab(text: AppStrings.albums),
                      Tab(text: AppStrings.artists),
                      Tab(text: AppStrings.folders),
                    ],
                  ),
                ),

                if (showPermissionBanner)
                  MaterialBanner(
                    backgroundColor: isDark ? AppColorsDark.surface : AppColorsLight.surface,
                    leading: FaIcon(FontAwesomeIcons.folderOpen, color: moodAccent, size: 20),
                    content: Text(
                      AppStrings.storagePermissionBanner,
                      style: AppTextStyles.bodyMedium(color: textColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: openAppSettings,
                        child: Text(AppStrings.openSettings, style: TextStyle(color: moodAccent)),
                      ),
                    ],
                  ),

                const Expanded(
                  child: TabBarView(
                    children: [
                      SongsTab(),
                      AlbumsTab(),
                      ArtistsTab(),
                      FoldersTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryScanButton extends ConsumerStatefulWidget {
  final bool isLoading;
  final Color accentColor;

  const _LibraryScanButton({
    required this.isLoading,
    required this.accentColor,
  });

  @override
  ConsumerState<_LibraryScanButton> createState() => _LibraryScanButtonState();
}

class _LibraryScanButtonState extends ConsumerState<_LibraryScanButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isLoading) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _LibraryScanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
        color: widget.accentColor,
        iconSize: 18,
        onPressed: widget.isLoading
            ? null
            : () => ref.read(libraryProvider.notifier).scan(),
      ),
    );
  }
}
