import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
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
    final accentColor = Theme.of(context).colorScheme.tertiary;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return asyncSongs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
          itemCount: sortedFolders.length + 1,
          itemBuilder: (context, i) {
            if (i == sortedFolders.length) {
              return SizedBox(height: ref.watch(playerProvider).currentSong != null ? 170 : 100);
            }
            final entry = sortedFolders[i];
            final folderPath = entry.key;
            final folderSongs = entry.value;
            final count = folderSongs.length;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: AppDimensions.sp4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppDimensions.sp8),
                ),
                child: Center(
                  child: FaIcon(FontAwesomeIcons.folder, color: accentColor, size: 16),
                ),
              ),
              title: Text(_folderName(folderPath), style: AppTextStyles.titleMedium()),
              subtitle: Text(
                '$count ${count == 1 ? 'song' : 'songs'}',
                style: AppTextStyles.labelSmall(color: subtextColor),
              ),
              trailing: FaIcon(FontAwesomeIcons.chevronRight, color: subtextColor, size: 14),
              onTap: () => _showFolderSheet(context, ref, _folderName(folderPath), folderSongs),
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
                    color: AppColorsLight.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.sp16),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.folderOpen, color: AppColorsLight.accent, size: 18),
                      const SizedBox(width: AppDimensions.sp8),
                      Expanded(child: Text(folderName, style: AppTextStyles.titleLarge())),
                    ],
                  ),
                ),
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
