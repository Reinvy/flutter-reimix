import 'dart:io';

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
import '../../widgets/glassmorphic_card.dart';
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

    // Mood-specific styles
    final selectedMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(selectedMood);
    final moodBg = moodColors.backgroundFor(Theme.of(context).brightness);
    final moodAccent = moodColors.accent;

    // Retrieve active and recently played songs to determine spotlight
    final playerState = ref.watch(playerProvider);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);

    Widget spotlightWidget;
    if (playerState.currentSong != null) {
      spotlightWidget = _SpotlightCard(
        song: playerState.currentSong!,
        isPlaying: playerState.isPlaying,
        accentColor: moodAccent,
      );
    } else {
      final recents = recentlyPlayedAsync.valueOrNull ?? [];
      if (recents.isNotEmpty) {
        spotlightWidget = _SpotlightCard(
          song: recents.first,
          isPlaying: false,
          accentColor: moodAccent,
        );
      } else {
        spotlightWidget = _WelcomeSpotlightCard(
          accentColor: moodAccent,
          onShufflePlay: () {
            final librarySongs = ref.read(libraryProvider).valueOrNull ?? [];
            if (librarySongs.isNotEmpty) {
              final shuffled = List<Song>.from(librarySongs)..shuffle();
              ref.read(playerProvider.notifier).play(
                shuffled.first,
                queue: shuffled,
                index: 0,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No local songs available to play.')),
              );
            }
          },
        );
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              moodBg.withAlpha(200),
              bgColor,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPaddingH,
                  AppDimensions.sp20,
                  AppDimensions.screenPaddingH,
                  AppDimensions.sp12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _greeting(),
                                  style: AppTextStyles.headlineLarge(color: textColor),
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

              // ── Spotlight Hero Card ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sp24),
                  child: spotlightWidget,
                ),
              ),

              // ── Mood Carousel ───────────────────────────────────────────────
              _SectionHeader(title: 'Choose Your Mood'),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sp24),
                  child: _MoodChips(),
                ),
              ),

              // ── Recently Played ─────────────────────────────────────────────
              _SectionHeader(
                title: AppStrings.recentlyPlayed,
                onSeeAll: () => context.go(AppRoutes.library),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sp24),
                  child: _RecentlyPlayedRow(),
                ),
              ),

              // ── Favorites ───────────────────────────────────────────────────
              _SectionHeader(
                title: AppStrings.yourFavorites,
                onSeeAll: () => context.go(AppRoutes.library),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sp24),
                  child: _FavoritesRow(),
                ),
              ),

              // ── Playlists ───────────────────────────────────────────────────
              _SectionHeader(
                title: AppStrings.yourPlaylists,
                onSeeAll: () => context.go(AppRoutes.playlists),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 180), // spacer for bottom nav bar
                  child: _PlaylistsRow(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mood Chips Carousel ───────────────────────────────────────────────────────

class _MoodChips extends ConsumerWidget {
  static const _moods = [
    (MoodType.calm, AppStrings.moodCalm, FontAwesomeIcons.mugHot, 'Relaxing'),
    (MoodType.sad, AppStrings.moodSad, FontAwesomeIcons.cloudRain, 'Melancholic'),
    (MoodType.energetic, AppStrings.moodEnergetic, FontAwesomeIcons.bolt, 'High Energy'),
    (MoodType.night, AppStrings.moodNight, FontAwesomeIcons.moon, 'Night Vibes'),
    (MoodType.focus, AppStrings.moodFocus, FontAwesomeIcons.brain, 'Concentrate'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(moodProvider);
    final accentColor = Theme.of(context).colorScheme.tertiary;

    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sp12),
        itemBuilder: (context, i) {
          final (moodType, label, icon, subtitle) = _moods[i];
          final isSelected = selected == moodType;
          return _MoodCard(
            moodType: moodType,
            label: label,
            subtitle: subtitle,
            icon: icon,
            isSelected: isSelected,
            accentColor: accentColor,
            onTap: () => ref.read(moodProvider.notifier).setMood(moodType),
          );
        },
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final MoodType moodType;
  final String label;
  final String subtitle;
  final FaIconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _MoodCard({
    required this.moodType,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isSelected ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : accentColor.withAlpha(40),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                color: isSelected ? Colors.white : accentColor,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.titleMedium(
                  color: isSelected ? Colors.white : textColor,
                ).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium(
                  color: isSelected ? Colors.white.withAlpha(200) : textColor.withAlpha(150),
                ).copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends ConsumerWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;

    final selectedMood = ref.watch(moodProvider);
    final accentColor = MoodTheme.of(selectedMood).accent;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPaddingH,
          AppDimensions.sp16,
          AppDimensions.screenPaddingH,
          AppDimensions.sp12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.titleLarge(color: textColor).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  AppStrings.seeAll,
                  style: AppTextStyles.bodyMedium(color: accentColor).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Recently Played Row ───────────────────────────────────────────────────────

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

// ── Favorites Row ────────────────────────────────────────────────────────────

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

// ── Horizontal Song List ──────────────────────────────────────────────────────

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

// ── Horizontal Song Skeleton ──────────────────────────────────────────────────

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

// ── Playlists Row ────────────────────────────────────────────────────────────

class _PlaylistsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final libraryAsync = ref.watch(libraryProvider);
    final accentColor = Theme.of(context).colorScheme.tertiary;

    final recentlyPlayedCount = recentlyPlayedAsync.valueOrNull?.length ?? 0;
    final favoritesCount = favoritesAsync.valueOrNull?.length ?? 0;
    final mostPlayedCount = libraryAsync.valueOrNull?.where((x) => x.playCount > 5).length ?? 0;

    final playlists = [
      (
        name: 'Recently Played',
        icon: FontAwesomeIcons.clockRotateLeft,
        count: recentlyPlayedCount,
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      (
        name: 'Most Played',
        icon: FontAwesomeIcons.chartLine,
        count: mostPlayedCount,
        gradient: const LinearGradient(
          colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      (
        name: 'Favorites',
        icon: FontAwesomeIcons.solidHeart,
        count: favoritesCount,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
        itemCount: playlists.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sp12),
        itemBuilder: (context, i) {
          if (i == 0) {
            // New playlist card
            return GestureDetector(
              onTap: () => context.go(AppRoutes.playlists),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withAlpha(80), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.plus, color: accentColor, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.newPlaylist,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall(
                        color: accentColor,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            );
          }
          final pl = playlists[i - 1];
          return _PlaylistCard(
            name: pl.name,
            icon: pl.icon,
            count: pl.count,
            gradient: pl.gradient,
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String name;
  final FaIconData icon;
  final int count;
  final Gradient gradient;

  const _PlaylistCard({
    required this.name,
    required this.icon,
    required this.count,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.playlists),
      child: Container(
        width: 130,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withAlpha(80),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FaIcon(icon, color: Colors.white, size: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count songs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall(color: Colors.white).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Spotlight Card ────────────────────────────────────────────────────────────

class _SpotlightCard extends ConsumerWidget {
  final Song song;
  final bool isPlaying;
  final Color accentColor;

  const _SpotlightCard({
    required this.song,
    required this.isPlaying,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      child: GlassmorphicCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => context.push(AppRoutes.nowPlaying),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              Hero(
                tag: 'now_playing_art',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: song.albumArtPath != null && song.albumArtPath!.isNotEmpty
                      ? Image.file(
                          File(song.albumArtPath!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _artPlaceholder(),
                        )
                      : _artPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NOW PLAYING',
                            style: AppTextStyles.labelSmall(color: accentColor).copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(width: 8),
                          _PlayingWaveIndicator(color: accentColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium(color: textColor).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(color: subtextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (isPlaying) {
                    ref.read(playerProvider.notifier).pause();
                  } else {
                    ref.read(playerProvider.notifier).resume();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(40),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withAlpha(80), width: 1),
                  ),
                  child: Center(
                    child: FaIcon(
                      isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColorsLight.primary,
      child: const Center(
        child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent, size: 28),
      ),
    );
  }
}

class _WelcomeSpotlightCard extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onShufflePlay;

  const _WelcomeSpotlightCard({
    required this.accentColor,
    required this.onShufflePlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      child: GlassmorphicCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Reimix',
              style: AppTextStyles.titleLarge(color: textColor).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your offline local music player tailored to your mood.',
              style: AppTextStyles.bodyMedium(color: subtextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onShufflePlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              icon: const FaIcon(FontAwesomeIcons.shuffle, size: 14),
              label: const Text('Quick Shuffle Play', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayingWaveIndicator extends StatefulWidget {
  final Color color;
  const _PlayingWaveIndicator({required this.color});

  @override
  State<_PlayingWaveIndicator> createState() => _PlayingWaveIndicatorState();
}

class _PlayingWaveIndicatorState extends State<_PlayingWaveIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            final double heightFactor = ((_controller.value + (index * 0.3)) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2.5,
              height: 4 + (12 * heightFactor),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
