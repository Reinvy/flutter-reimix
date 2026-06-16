import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../providers/player_provider.dart';
import 'glassmorphic_card.dart';

/// Persistent mini player shown above the bottom navigation bar.
///
/// Hides itself when no song is active. Tap → opens Now Playing screen.
/// Horizontal swipe to dismiss (velocity > 300 px/s) → stops playback.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    if (song == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.nowPlaying),
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity?.abs() ?? 0) > 300) {
            ref.read(playerProvider.notifier).stop();
          }
        },
        child: Container(
          height: AppDimensions.miniPlayerHeight,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: GlassmorphicCard(
            borderRadius: AppDimensions.radiusMiniPlayer,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp12),
            child: Row(
              children: [
                // Album art
                _MiniArt(artPath: song.albumArtPath),
                const SizedBox(width: AppDimensions.sp12),
                // Title + artist
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium(),
                      ),
                      Text(
                        song.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall(),
                      ),
                    ],
                  ),
                ),
                // Play / pause
                _PlayPauseButton(
                  isPlaying: playerState.isPlaying,
                  isLoading: playerState.isLoading,
                  onTap: () {
                    if (playerState.isPlaying) {
                      ref.read(playerProvider.notifier).pause();
                    } else {
                      ref.read(playerProvider.notifier).resume();
                    }
                  },
                ),
                // Skip next
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.forwardStep),
                  iconSize: 18,
                  color: AppColorsLight.onPrimary,
                  onPressed: () => ref.read(playerProvider.notifier).skipToNext(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini art thumbnail ────────────────────────────────────────────────────────

class _MiniArt extends StatelessWidget {
  final String? artPath;

  const _MiniArt({this.artPath});

  @override
  Widget build(BuildContext context) {
    const size = AppDimensions.albumArtMiniPlayerSize;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.sp8),
      child: SizedBox(width: size, height: size, child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (artPath != null && artPath!.isNotEmpty) {
      return Image.file(
        File(artPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColorsLight.primary,
      child: const Center(
        child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent, size: 18),
      ),
    );
  }
}

// ── Play / Pause button with loading indicator ────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isPlaying, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColorsLight.accent),
        ),
      );
    }
    return IconButton(
      icon: FaIcon(isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play),
      iconSize: 18,
      color: AppColorsLight.accent,
      onPressed: onTap,
    );
  }
}
