import 'dart:io';

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
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/player_provider.dart';

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
                onTap: () {
                  context.push(
                    '${AppRoutes.library}/detail',
                    extra: {
                      'title': _folderName(folderPath),
                      'type': 'folder',
                      'songs': folderSongs,
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
