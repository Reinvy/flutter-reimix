import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../domain/entities/song.dart';
import '../../providers/mood_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_list_tile.dart';

class LibraryDetailScreen extends ConsumerWidget {
  final String title;
  final String type; // 'album', 'artist', 'folder'
  final List<Song> songs;
  final String? subtitle;

  const LibraryDetailScreen({
    super.key,
    required this.title,
    required this.type,
    required this.songs,
    this.subtitle,
  });

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

    final headerIcon = switch (type) {
      'album' => FontAwesomeIcons.compactDisc,
      'artist' => FontAwesomeIcons.user,
      'folder' => FontAwesomeIcons.folderOpen,
      _ => FontAwesomeIcons.music,
    };

    return Scaffold(
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
              // ── Navigation Header Row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sp16,
                  vertical: AppDimensions.sp12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.chevronLeft),
                      color: textColor,
                      iconSize: 18,
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // ── Header Details (Collage style card) ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            moodAccent.withAlpha(200),
                            moodAccent.withAlpha(100),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: moodAccent.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FaIcon(headerIcon, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headlineMedium(color: textColor).copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle ?? '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium(color: subtextColor).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                              style: AppTextStyles.labelSmall(color: subtextColor).copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Action Buttons Row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
                child: Row(
                  children: [
                    // Play All Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: songs.isEmpty
                            ? null
                            : () => ref.read(playerProvider.notifier).play(
                                  songs.first,
                                  queue: songs,
                                  index: 0,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.play, size: 14),
                        label: const Text(
                          'Play All',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shuffle Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: songs.isEmpty
                            ? null
                            : () {
                                final shuffled = [...songs]..shuffle();
                                ref.read(playerProvider.notifier).play(
                                      shuffled.first,
                                      queue: shuffled,
                                      index: 0,
                                    );
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: moodAccent,
                          side: BorderSide(color: moodAccent.withAlpha(150), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.shuffle, size: 14),
                        label: const Text(
                          'Shuffle',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Divider(height: 1, color: isDark ? AppColorsDark.divider : AppColorsLight.divider),

              // ── Songs List ──────────────────────────────────────────────────
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs found.',
                          style: AppTextStyles.bodyMedium(color: subtextColor),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: songs.length + 1,
                        itemBuilder: (context, i) {
                          if (i == songs.length) {
                            // Bottom spacer of 180dp to clear MiniPlayer / Bottom Navigation Bar
                            return const SizedBox(height: 180);
                          }
                          final song = songs[i];
                          final currentSong = ref.watch(playerProvider).currentSong;
                          return SongListTile(
                            song: song,
                            isPlaying: currentSong?.id == song.id,
                            onTap: () => ref.read(playerProvider.notifier).play(
                                  song,
                                  queue: songs,
                                  index: i,
                                ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
