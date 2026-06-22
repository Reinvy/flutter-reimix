import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/lyrics.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';


/// A widget that displays timed (synced) lyrics that auto-scroll
/// with the current playback position, or falls back to plain text.
class SyncedLyricsView extends ConsumerStatefulWidget {
  const SyncedLyricsView({super.key});

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView> {
  final _scrollCtrl = ScrollController();
  int _currentLineIndex = -1;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lyricsState = ref.watch(lyricsProvider);
    final playerState = ref.watch(playerProvider);
    final accent = Theme.of(context).colorScheme.tertiary;

    // Load lyrics when the current song changes
    ref.listen<PlayerState>(playerProvider, (prev, next) {
      if (prev?.currentSong?.id != next.currentSong?.id) {
        ref.read(lyricsProvider.notifier).clear();
        if (next.currentSong != null) {
          ref.read(lyricsProvider.notifier).loadLyrics(next.currentSong!);
        }
      }
    });

    if (lyricsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lyricsState.notFound) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics_outlined, size: 48, color: Colors.white30),
            const SizedBox(height: 12),
            Text(
              'No lyrics found',
              style: AppTextStyles.bodyMedium(
                color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
              ),
            ),
          ],
        ),
      );
    }

    if (lyricsState.lyrics == null) {
      return Center(
        child: TextButton.icon(
          onPressed: () {
            final song = playerState.currentSong;
            if (song != null) {
              ref.read(lyricsProvider.notifier).loadLyrics(song);
            }
          },
          icon: const Icon(Icons.lyrics_outlined),
          label: const Text('Load Lyrics'),
        ),
      );
    }

    final lyrics = lyricsState.lyrics!;

    // Plain text fallback
    if (!lyrics.hasSynced) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          lyrics.plainText ?? '',
          style: AppTextStyles.bodyMedium(
            color: isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground,
          ).copyWith(height: 1.8),
          textAlign: TextAlign.center,
        ),
      );
    }

    final lines = lyrics.syncedLines!;
    final position = playerState.position;

    // Find the current active lyric line
    int activeIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestamp <= position) {
        activeIndex = i;
      } else {
        break;
      }
    }

    // Auto-scroll to the active line when it changes
    if (activeIndex != _currentLineIndex && activeIndex >= 0) {
      _currentLineIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollCtrl.animateTo(
          (activeIndex * 72.0) - 160,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      itemCount: lines.length,
      itemBuilder: (context, i) {
        final isActive = i == activeIndex;
        final isPast = i < activeIndex;
        return _LyricLine(
          line: lines[i],
          isActive: isActive,
          isPast: isPast,
          accent: accent,
          isDark: isDark,
        );
      },
    );
  }
}

class _LyricLine extends StatelessWidget {
  final LyricLine line;
  final bool isActive;
  final bool isPast;
  final Color accent;
  final bool isDark;

  const _LyricLine({
    required this.line,
    required this.isActive,
    required this.isPast,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final textColor = isActive
        ? accent
        : isPast
            ? baseColor.withAlpha(120)
            : baseColor.withAlpha(180);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: 72,
      alignment: Alignment.center,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: AppTextStyles.bodyMedium(color: textColor).copyWith(
          fontSize: isActive ? 18 : 14,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          height: 1.4,
        ),
        child: Text(
          line.text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
