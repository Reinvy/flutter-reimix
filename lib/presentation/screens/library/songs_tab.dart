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
    
    // Mood-specific styles
    final selectedMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(selectedMood);
    final accentColor = moodColors.accent;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    // Show a petal-burst snackbar each time the library finishes scanning.
    ref.listen<int>(scanCompleteCountProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Text('🌸 Library scanned!')]),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    return asyncSongs.when(
      loading: () => _ShimmerList(),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium())),
      data: (songs) {
        if (songs.isEmpty) {
          return _AnimatedEmptyState(onScan: () => ref.read(libraryProvider.notifier).scan());
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
                    style: AppTextStyles.labelSmall(color: subtextColor).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSortSheet(context, accentColor),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.sort, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text('Sort', style: AppTextStyles.bodyMedium(color: accentColor).copyWith(
                          fontWeight: FontWeight.w700,
                        )),
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
                  padding: EdgeInsets.zero,
                  itemCount: sorted.length + 2,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _buildShuffleHero(context, sorted, accentColor);
                    }
                    if (i == sorted.length + 1) {
                      return SizedBox(height: ref.watch(playerProvider).currentSong != null ? 170 : 100);
                    }
                    final songIndex = i - 1;
                    final song = sorted[songIndex];
                    final currentSong = ref.watch(playerProvider).currentSong;
                    return SongListTile(
                      song: song,
                      isPlaying: currentSong?.id == song.id,
                      onTap: () =>
                          ref.read(playerProvider.notifier).play(song, queue: sorted, index: songIndex),
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

  Widget _buildShuffleHero(BuildContext context, List<Song> songs, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: AppDimensions.sp12,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withAlpha(220),
              accentColor.withAlpha(140),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.compactDisc,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Shuffle Play',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Play your library songs in random order',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (songs.isNotEmpty) {
                  final shuffled = List<Song>.from(songs)..shuffle();
                  ref.read(playerProvider.notifier).play(
                    shuffled.first,
                    queue: shuffled,
                    index: 0,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No songs in library to play.')),
                  );
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.play,
                    color: accentColor,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, Color accentColor) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        accentColor: accentColor,
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
      baseColor: AppColorsLight.primary.withAlpha(100),
      highlightColor: AppColorsLight.secondary.withAlpha(100),
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
  final Color accentColor;
  final ValueChanged<_SortMode> onSelected;

  const _SortSheet({
    required this.current,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;

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
              color: isDark ? AppColorsDark.divider : AppColorsLight.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.sp16),
            child: Text('Sort By', style: AppTextStyles.titleLarge().copyWith(fontWeight: FontWeight.w800)),
          ),
          for (final (mode, label) in options)
            ListTile(
              title: Text(label, style: AppTextStyles.titleMedium()),
              trailing: current == mode ? FaIcon(FontAwesomeIcons.check, color: accentColor, size: 16) : null,
              onTap: () => onSelected(mode),
            ),
          const SizedBox(height: AppDimensions.sp16),
        ],
      ),
    );
  }
}

// ── Animated empty state ──────────────────────────────────────────────────────

class _AnimatedEmptyState extends StatefulWidget {
  final VoidCallback onScan;
  const _AnimatedEmptyState({required this.onScan});

  @override
  State<_AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<_AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.tertiary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: FaIcon(FontAwesomeIcons.music, size: 72, color: accentColor.withAlpha(180)),
            ),
            const SizedBox(height: AppDimensions.sp24),
            Text(
              AppStrings.noMusicFound,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppDimensions.sp24),
            ElevatedButton.icon(
              onPressed: widget.onScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: const Text('Scan Now', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
