import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_list_tile.dart';

enum _SortMode { title, artist, album, dateAdded, duration }

class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key});

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  _SortMode _sort = _SortMode.title;

  List<Song> _sorted(List<Song> songs) {
    final list = [...songs];
    switch (_sort) {
      case _SortMode.title:
        list.sort((a, b) => a.title.compareTo(b.title));
      case _SortMode.artist:
        list.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
      case _SortMode.album:
        list.sort((a, b) => (a.album ?? '').compareTo(b.album ?? ''));
      case _SortMode.dateAdded:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case _SortMode.duration:
        list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final asyncSongs = ref.watch(libraryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.tertiary;
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
        final sorted = _sorted(songs);
        return Column(
          children: [
            // Sort bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: AppDimensions.sp8,
              ),
              child: Row(
                children: [
                  Text(
                    '${songs.length} songs',
                    style: AppTextStyles.labelSmall(color: subtextColor),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded, size: 18, color: accentColor),
                        const SizedBox(width: 4),
                        Text('Sort', style: AppTextStyles.bodyMedium(color: accentColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: accentColor,
                onRefresh: () => ref.read(libraryProvider.notifier).scan(),
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final song = sorted[i];
                    final currentSong = ref.watch(playerProvider).currentSong;
                    return SongListTile(
                      song: song,
                      isPlaying: currentSong?.id == song.id,
                      onTap: () =>
                          ref.read(playerProvider.notifier).play(song, queue: sorted, index: i),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        onSelected: (s) {
          setState(() => _sort = s);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Shimmer loading list ──────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColorsLight.primary,
      highlightColor: AppColorsLight.secondary,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
            vertical: AppDimensions.sp8,
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.albumArtListSize,
                height: AppDimensions.albumArtListSize,
                decoration: BoxDecoration(
                  color: AppColorsLight.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusAlbumArtList),
                ),
              ),
              const SizedBox(width: AppDimensions.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: AppColorsLight.primary),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 90, color: AppColorsLight.primary),
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

// ── Sort bottom sheet ─────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final _SortMode current;
  final ValueChanged<_SortMode> onSelected;

  const _SortSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final accentColor = Theme.of(context).colorScheme.tertiary;

    const options = [
      (_SortMode.title, 'Title'),
      (_SortMode.artist, 'Artist'),
      (_SortMode.album, 'Album'),
      (_SortMode.dateAdded, 'Date Added'),
      (_SortMode.duration, 'Duration'),
    ];

    return Container(
      margin: const EdgeInsets.all(AppDimensions.sp16),
      decoration: BoxDecoration(
        color: bgColor,
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
            child: Text('Sort By', style: AppTextStyles.titleLarge()),
          ),
          for (final (mode, label) in options)
            ListTile(
              title: Text(label, style: AppTextStyles.titleMedium()),
              trailing: current == mode ? Icon(Icons.check_rounded, color: accentColor) : null,
              onTap: () => onSelected(mode),
            ),
          const SizedBox(height: AppDimensions.sp16),
        ],
      ),
    );
  }
}
