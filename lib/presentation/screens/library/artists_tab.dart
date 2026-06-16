import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_list_tile.dart';

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
                  _showArtistSheet(context, ref, artist.name, artistSongs);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showArtistSheet(BuildContext context, WidgetRef ref, String artistName, List<Song> songs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final accentColor = Theme.of(context).colorScheme.tertiary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusBottomSheet),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: AppDimensions.sp12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColorsDark.divider : AppColorsLight.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header details
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.sp16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.user, color: accentColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sp12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLarge().copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium().copyWith(
                                color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: FaIcon(FontAwesomeIcons.circlePlay, color: accentColor, size: 28),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (songs.isNotEmpty) {
                            ref.read(playerProvider.notifier).play(songs.first, queue: songs, index: 0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColorsDark.divider : AppColorsLight.divider),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: songs.length,
                    itemBuilder: (_, i) {
                      final song = songs[i];
                      return SongListTile(
                        song: song,
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(playerProvider.notifier).play(song, queue: songs, index: i);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
