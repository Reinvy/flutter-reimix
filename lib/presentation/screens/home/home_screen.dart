import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
import '../../widgets/song_list_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: AppDimensions.sp16,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: AppTextStyles.headlineLarge(color: textColor)),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.homeSubtitle,
                            style: AppTextStyles.bodyMedium(color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.gear),
                      color: subtextColor,
                      iconSize: 18,
                      onPressed: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
              ),
            ),
            // ── Mood Chips ───────────────────────────────────────────────────
            SliverToBoxAdapter(child: _MoodChips()),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp24)),
            // ── Recently Played ───────────────────────────────────────────────
            _SectionHeader(
              title: AppStrings.recentlyPlayed,
              onSeeAll: () => context.go(AppRoutes.library),
            ),
            SliverToBoxAdapter(child: _RecentlyPlayedRow()),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp24)),
            // ── Favorites ────────────────────────────────────────────────────
            _SectionHeader(
              title: AppStrings.yourFavorites,
              onSeeAll: () => context.go(AppRoutes.library),
            ),
            SliverToBoxAdapter(child: _FavoritesRow()),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp24)),
            // ── Playlists ─────────────────────────────────────────────────────
            _SectionHeader(
              title: AppStrings.yourPlaylists,
              onSeeAll: () => context.go(AppRoutes.playlists),
            ),
            SliverToBoxAdapter(child: _PlaylistsRow()),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp48)),
          ],
        ),
      ),
    );
  }
}

// ── Mood Chips ────────────────────────────────────────────────────────────────

class _MoodChips extends ConsumerWidget {
  static const _moods = [
    (MoodType.calm, AppStrings.moodCalm),
    (MoodType.sad, AppStrings.moodSad),
    (MoodType.energetic, AppStrings.moodEnergetic),
    (MoodType.night, AppStrings.moodNight),
    (MoodType.focus, AppStrings.moodFocus),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(moodProvider);
    final accentColor = Theme.of(context).colorScheme.tertiary;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sp8),
        itemBuilder: (context, i) {
          final (moodType, label) = _moods[i];
          final isSelected = selected == moodType;
          return GestureDetector(
            onTap: () => ref.read(moodProvider.notifier).setMood(moodType),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.sp16,
                vertical: AppDimensions.sp8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : accentColor.withAlpha(30),
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                border: Border.all(
                  color: isSelected ? accentColor : accentColor.withAlpha(60),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(
                  color: isSelected ? Colors.white : accentColor,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget implements SliverToBoxAdapterDelegate {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final accentColor = Theme.of(context).colorScheme.tertiary;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppDimensions.screenPaddingH,
          right: AppDimensions.screenPaddingH,
          bottom: AppDimensions.sp12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.titleLarge(color: textColor)),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(AppStrings.seeAll, style: AppTextStyles.bodyMedium(color: accentColor)),
              ),
          ],
        ),
      ),
    );
  }
}

// ignore: undefined_class
mixin SliverToBoxAdapterDelegate implements Widget {
  Widget build(BuildContext context);
}

// ── Recently Played Row ────────────────────────────────────────────────────────

class _RecentlyPlayedRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSongs = ref.watch(recentlyPlayedProvider);

    return asyncSongs.when(
      loading: () => const _HorizontalSongSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (songs) {
        if (songs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
            child: Text(AppStrings.noSongsPlayedYet, style: AppTextStyles.bodyMedium()),
          );
        }
        return _HorizontalSongList(songs: songs);
      },
    );
  }
}

// ── Favorites Row ─────────────────────────────────────────────────────────────

class _FavoritesRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSongs = ref.watch(favoritesProvider);

    return asyncSongs.when(
      loading: () => const _HorizontalSongSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (songs) {
        if (songs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
            child: Text(AppStrings.noFavorites, style: AppTextStyles.bodyMedium()),
          );
        }
        return _HorizontalSongList(songs: songs);
      },
    );
  }
}

// ── Horizontal song list ──────────────────────────────────────────────────────

class _HorizontalSongList extends ConsumerWidget {
  final List<Song> songs;

  const _HorizontalSongList({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final song = songs[i];
          return SizedBox(
            width: 280,
            child: SongListTile(
              song: song,
              onTap: () => ref.read(playerProvider.notifier).play(song, queue: songs, index: i),
            ),
          );
        },
      ),
    );
  }
}

// ── Horizontal song skeleton placeholder ──────────────────────────────────────

class _HorizontalSongSkeleton extends StatelessWidget {
  const _HorizontalSongSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, __) => Container(
          width: 280,
          height: 64,
          decoration: BoxDecoration(
            color: AppColorsLight.primary.withAlpha(60),
            borderRadius: BorderRadius.circular(AppDimensions.sp12),
          ),
        ),
      ),
    );
  }
}

// ── Playlists Row ─────────────────────────────────────────────────────────────

class _PlaylistsRow extends StatelessWidget {
  static const _smartPlaylists = [
    AppStrings.recentlyPlayedPlaylist,
    AppStrings.mostPlayedPlaylist,
    AppStrings.favoritesPlaylist,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.tertiary;

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
        itemCount: _smartPlaylists.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sp12),
        itemBuilder: (context, i) {
          if (i == 0) {
            // New playlist card
            return GestureDetector(
              onTap: () => context.go(AppRoutes.playlists),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: accentColor.withAlpha(80)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.plus, color: accentColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.newPlaylist,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall(
                        color: accentColor,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }
          final name = _smartPlaylists[i - 1];
          return _PlaylistCard(name: name, isDark: isDark, accentColor: accentColor);
        },
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String name;
  final bool isDark;
  final Color accentColor;

  const _PlaylistCard({required this.name, required this.isDark, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    return GestureDetector(
      onTap: () => context.go(AppRoutes.playlists),
      child: Container(
        width: 110,
        height: 90,
        padding: const EdgeInsets.all(AppDimensions.sp12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          boxShadow: const [
            BoxShadow(
              color: AppColorsLight.shadow,
              blurRadius: AppDimensions.shadowBlur,
              offset: Offset(0, AppDimensions.shadowOffsetY),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.list, color: accentColor, size: 24),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall(),
            ),
          ],
        ),
      ),
    );
  }
}
