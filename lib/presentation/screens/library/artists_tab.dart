import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/mood_theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/player_provider.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtists = ref.watch(artistsProvider);
    final librarySongs = ref.watch(libraryProvider).valueOrNull ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mood-specific styles
    final selectedMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(selectedMood);
    final accentColor = moodColors.accent;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return asyncArtists.when(
      loading: () => _ShimmerList(),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium())),
      data: (artists) {
        if (artists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.sp32),
              child: Text(
                AppStrings.noMusicFound,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: artists.length + 1,
          itemBuilder: (context, i) {
            if (i == artists.length) {
              return SizedBox(height: ref.watch(playerProvider).currentSong != null ? 170 : 100);
            }
            final artist = artists[i];
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surface.withAlpha(100) : AppColorsLight.surface.withAlpha(100),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColorsLight.divider.withAlpha(30) : AppColorsLight.divider.withAlpha(60),
                  width: 0.5,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withAlpha(180),
                        accentColor.withAlpha(100),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(60),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.user, color: Colors.white, size: 16),
                  ),
                ),
                title: Text(
                  artist.name,
                  style: AppTextStyles.titleMedium().copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${artist.songCount} ${artist.songCount == 1 ? 'song' : 'songs'}',
                  style: AppTextStyles.labelSmall(color: subtextColor).copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: FaIcon(FontAwesomeIcons.chevronRight, color: subtextColor, size: 14),
                onTap: () {
                  final artistSongs = librarySongs.where((s) => s.artist == artist.name).toList();
                  context.push(
                    '${AppRoutes.library}/detail',
                    extra: {
                      'title': artist.name,
                      'type': 'artist',
                      'songs': artistSongs,
                      'subtitle': null,
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColorsLight.primary.withAlpha(100),
      highlightColor: AppColorsLight.secondary.withAlpha(100),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH, vertical: 12),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColorsLight.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 150, color: AppColorsLight.primary),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 80, color: AppColorsLight.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
