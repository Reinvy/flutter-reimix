import 'dart:io';

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

class FoldersTab extends ConsumerWidget {
  const FoldersTab({super.key});

  Map<String, List<Song>> _groupByFolder(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final song in songs) {
      final folder = File(song.filePath).parent.path;
      (map[folder] ??= []).add(song);
    }
    return map;
  }

  String _folderName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSongs = ref.watch(libraryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mood-specific styles
    final selectedMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(selectedMood);
    final accentColor = moodColors.accent;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return asyncSongs.when(
      loading: () => _ShimmerList(),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium())),
      data: (songs) {
        if (songs.isEmpty) {
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
        final folders = _groupByFolder(songs);
        final sortedFolders = folders.entries.toList()
          ..sort((a, b) => _folderName(a.key).compareTo(_folderName(b.key)));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: sortedFolders.length + 1,
          itemBuilder: (context, i) {
            if (i == sortedFolders.length) {
              return SizedBox(height: ref.watch(playerProvider).currentSong != null ? 170 : 100);
            }
            final entry = sortedFolders[i];
            final folderPath = entry.key;
            final folderSongs = entry.value;
            final count = folderSongs.length;

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
                    color: accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.folder, color: accentColor, size: 16),
                  ),
                ),
                title: Text(_folderName(folderPath), style: AppTextStyles.titleMedium().copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '$count ${count == 1 ? 'song' : 'songs'}',
                  style: AppTextStyles.labelSmall(color: subtextColor).copyWith(fontWeight: FontWeight.w600),
                ),
                trailing: FaIcon(FontAwesomeIcons.chevronRight, color: subtextColor, size: 14),
                onTap: () => _showFolderSheet(context, ref, _folderName(folderPath), folderSongs),
              ),
            );
          },
        );
      },
    );
  }

  void _showFolderSheet(BuildContext context, WidgetRef ref, String folderName, List<Song> songs) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (_, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
          final accentColor = Theme.of(context).colorScheme.tertiary;

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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.folderOpen, color: accentColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sp8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folderName,
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
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColorsLight.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: AppColorsLight.primary),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 70, color: AppColorsLight.primary),
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
