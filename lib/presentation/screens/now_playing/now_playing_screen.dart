import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song_list_tile.dart';

// ── Now Playing Screen ────────────────────────────────────────────────────────

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _bounceController;
  late final AnimationController _heartController;
  late final AnimationController _visualizerController;
  late final Animation<double> _scaleAnim;

  Color _dominantColor = AppColorsLight.accent;
  String? _lastArtPath;
  int _currentTab = 0; // 0: Art, 1: Lyrics, 2: Visualizer

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _bounceController;

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    _heartController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  Future<void> _updateDominantColor(String? artPath) async {
    if (artPath == null || artPath == _lastArtPath) return;
    _lastArtPath = artPath;
    try {
      final imageProvider = artPath.startsWith('http')
          ? NetworkImage(artPath) as ImageProvider
          : FileImage(File(artPath));
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100),
      );
      if (mounted) {
        setState(() {
          _dominantColor = palette.dominantColor?.color ?? AppColorsLight.accent;
        });
      }
    } catch (_) {
      // Keep previous color on error
    }
  }

  void _onPlayPauseTap() async {
    final state = ref.read(playerProvider);
    await _bounceController.reverse();
    await _bounceController.forward();
    if (state.isPlaying) {
      ref.read(playerProvider.notifier).pause();
    } else {
      ref.read(playerProvider.notifier).resume();
    }
  }

  void _onFavoriteTap(Song song) {
    _heartController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Update dominant color when song changes
    if (song != null) {
      _updateDominantColor(song.albumArtPath);
    }

    // Control rotation based on play state
    if (playerState.isPlaying) {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    if (song == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColorsDark.background : AppColorsLight.background,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_dominantColor.withAlpha(200), _dominantColor.withAlpha(80), Colors.transparent],
    );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -300) {
          ref.read(playerProvider.notifier).skipToNext();
        } else if ((details.primaryVelocity ?? 0) > 300) {
          ref.read(playerProvider.notifier).skipToPrevious();
        }
      },
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -300) {
          _showQueueSheet(context, ref, playerState);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Blurred background ────────────────────────────────────────
            _BlurredBackground(artPath: song.albumArtPath, gradient: gradient),
            // ── Safe area content ─────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, isDark),
                  const SizedBox(height: AppDimensions.sp16),
                  // Tab-driven content area
                  Expanded(
                    child: _currentTab == 0
                        ? _buildArtView(playerState, song, isDark)
                        : _currentTab == 1
                        ? _LyricsView(song: song, position: playerState.position)
                        : _VisualizerView(
                            isPlaying: playerState.isPlaying,
                            controller: _visualizerController,
                            accentColor: _dominantColor,
                          ),
                  ),
                  _buildTabSwitcher(isDark),
                  const SizedBox(height: AppDimensions.sp8),
                  // Controls panel
                  _buildControlsPanel(context, playerState, song, isDark),
                  const SizedBox(height: AppDimensions.sp24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp8),
      child: Row(
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 20),
            color: isDark ? AppColorsDark.onBackground : Colors.white,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              AppStrings.queue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.list, size: 18),
            color: Colors.white,
            onPressed: () => _showQueueSheet(context, ref, ref.read(playerProvider)),
          ),
        ],
      ),
    );
  }

  // ── Album art view ────────────────────────────────────────────────────────

  Widget _buildArtView(PlayerState playerState, Song song, bool isDark) {
    return Center(
      child: GestureDetector(
        onLongPress: () => HapticFeedback.mediumImpact(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: RotatingAlbumArt(
            key: ValueKey(song.id),
            artPath: song.albumArtPath,
            rotationController: _rotationController,
          ),
        ),
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────

  Widget _buildTabSwitcher(bool isDark) {
    final accentColor = _dominantColor;
    const tabs = ['Art', AppStrings.lyrics, AppStrings.visualizer];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tabs.length, (i) {
          final isSelected = _currentTab == i;
          return GestureDetector(
            onTap: () => setState(() => _currentTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withAlpha(200) : Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Controls panel ────────────────────────────────────────────────────────

  Widget _buildControlsPanel(
    BuildContext context,
    PlayerState playerState,
    Song song,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      child: Column(
        children: [
          // Song info + favorite
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMedium(color: Colors.white),
                    ),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      style: AppTextStyles.bodyMedium(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Favorite button
              AnimatedBuilder(
                animation: _heartController,
                builder: (_, __) {
                  final scale = 1.0 + _heartController.value * 0.3;
                  return GestureDetector(
                    onTap: () => _onFavoriteTap(song),
                    child: Transform.scale(
                      scale: scale,
                      child: FaIcon(
                        song.isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                        color: song.isFavorite ? AppColorsLight.accent : Colors.white70,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sp16),
          // Seekbar
          _Seekbar(playerState: playerState),
          const SizedBox(height: AppDimensions.sp8),
          // Volume slider
          _VolumeSlider(volume: playerState.volume),
          const SizedBox(height: AppDimensions.sp16),
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle
              IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.shuffle,
                  color: playerState.shuffleMode == ShuffleMode.on
                      ? AppColorsLight.accent
                      : Colors.white70,
                  size: 18,
                ),
                onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
              ),
              // Previous
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.backwardStep, color: Colors.white, size: 24),
                onPressed: () => ref.read(playerProvider.notifier).skipToPrevious(),
              ),
              // Play / pause
              ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  onTap: _onPlayPauseTap,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: playerState.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColorsLight.accent,
                            ),
                          )
                        : Center(
                            child: FaIcon(
                              playerState.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                              color: AppColorsLight.accent,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
              // Next
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.forwardStep, color: Colors.white, size: 24),
                onPressed: () => ref.read(playerProvider.notifier).skipToNext(),
              ),
              // Repeat
              IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.repeat,
                  color: playerState.repeatMode != RepeatMode.off
                      ? AppColorsLight.accent
                      : Colors.white70,
                  size: 18,
                ),
                onPressed: () => ref.read(playerProvider.notifier).cycleRepeatMode(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Queue bottom sheet ────────────────────────────────────────────────────

  void _showQueueSheet(BuildContext context, WidgetRef ref, PlayerState playerState) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QueueSheet(playerState: playerState, ref: ref),
    );
  }
}

// ── Rotating album art ────────────────────────────────────────────────────────

class RotatingAlbumArt extends StatelessWidget {
  final String? artPath;
  final AnimationController rotationController;

  const RotatingAlbumArt({super.key, this.artPath, required this.rotationController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotationController,
      builder: (_, child) {
        return Transform.rotate(angle: rotationController.value * 2 * math.pi, child: child);
      },
      child: Container(
        width: AppDimensions.albumArtNowPlayingSize,
        height: AppDimensions.albumArtNowPlayingSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipOval(child: _buildArt()),
      ),
    );
  }

  Widget _buildArt() {
    if (artPath != null && artPath!.isNotEmpty) {
      if (artPath!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: artPath!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        );
      }
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
        child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent, size: 80),
      ),
    );
  }
}

// ── Blurred background ────────────────────────────────────────────────────────

class _BlurredBackground extends StatelessWidget {
  final String? artPath;
  final Gradient gradient;

  const _BlurredBackground({this.artPath, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark base
        Container(color: const Color(0xFF1A0F1A)),
        // Blurred album art
        if (artPath != null && artPath!.isNotEmpty)
          ImageFiltered(
            imageFilter: ColorFilter.mode(Colors.black.withAlpha(100), BlendMode.darken),
            child: artPath!.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: artPath!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                )
              : Image.file(
                  File(artPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
          ),
        // Gradient overlay
        Container(decoration: BoxDecoration(gradient: gradient)),
        // Dark scrim
        Container(color: Colors.black.withAlpha(80)),
      ],
    );
  }
}

// ── Seekbar ───────────────────────────────────────────────────────────────────

class _Seekbar extends ConsumerWidget {
  final PlayerState playerState;

  const _Seekbar({required this.playerState});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = playerState.currentSong != null
        ? Duration(milliseconds: playerState.currentSong!.durationMs)
        : Duration.zero;
    final pos = playerState.position;
    final sliderValue = total.inMilliseconds > 0 ? pos.inMilliseconds / total.inMilliseconds : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: sliderValue.clamp(0.0, 1.0),
            onChanged: (val) {
              final ms = (val * total.inMilliseconds).round();
              ref.read(playerProvider.notifier).seek(Duration(milliseconds: ms));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_fmt(total), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Volume slider ──────────────────────────────────────────────────────────────

class _VolumeSlider extends ConsumerWidget {
  final double volume;

  const _VolumeSlider({required this.volume});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const FaIcon(FontAwesomeIcons.volumeLow, color: Colors.white70, size: 14),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: volume.clamp(0.0, 1.0),
              onChanged: (val) {
                // Volume control — AudioPlayer volume via handler (future enhancement)
              },
            ),
          ),
        ),
        const FaIcon(FontAwesomeIcons.volumeHigh, color: Colors.white70, size: 14),
      ],
    );
  }
}

// ── Lyrics view ───────────────────────────────────────────────────────────────

class _LyricsView extends StatelessWidget {
  final Song song;
  final Duration position;

  const _LyricsView({required this.song, required this.position});

  @override
  Widget build(BuildContext context) {
    // LRC lyrics would normally be loaded from the file's embedded metadata.
    // Show a friendly placeholder for now.
    return const Center(
      child: Text(AppStrings.noLyrics, style: TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }
}

// ── Visualizer view ───────────────────────────────────────────────────────────

class _VisualizerView extends StatelessWidget {
  final bool isPlaying;
  final AnimationController controller;
  final Color accentColor;

  const _VisualizerView({
    required this.isPlaying,
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _VisualizerPainter(
                progress: controller.value,
                isPlaying: isPlaying,
                color: accentColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;

  const _VisualizerPainter({required this.progress, required this.isPlaying, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 32;
    const barSpacing = 3.0;
    final barWidth = (size.width - (barCount + 1) * barSpacing) / barCount;
    final paint = Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final phase = (i / barCount) * math.pi * 2;
      final wave = isPlaying
          ? (0.15 + 0.85 * (0.5 + 0.5 * math.sin(phase + progress * math.pi * 2)))
          : 0.05;
      final barHeight = size.height * wave;
      final x = barSpacing + i * (barWidth + barSpacing);
      final top = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) =>
      old.progress != progress || old.isPlaying != isPlaying;
}

// ── Queue bottom sheet ────────────────────────────────────────────────────────

class _QueueSheet extends StatelessWidget {
  final PlayerState playerState;
  final WidgetRef ref;

  const _QueueSheet({required this.playerState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final queue = playerState.queue;
    final current = playerState.currentSong;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      builder: (_, scrollController) {
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
                child: Text(AppStrings.queue, style: AppTextStyles.titleLarge()),
              ),
              Expanded(
                child: queue.isEmpty
                    ? const Center(child: Text('Queue is empty'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: queue.length,
                        itemBuilder: (_, i) {
                          final song = queue[i];
                          return Dismissible(
                            key: ValueKey('queue_${song.id}_$i'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppDimensions.sp16),
                              color: Colors.red.withAlpha(40),
                              child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.red, size: 18),
                            ),
                            child: SongListTile(
                              song: song,
                              isPlaying: current?.id == song.id,
                              onTap: () {
                                Navigator.pop(context);
                                ref
                                    .read(playerProvider.notifier)
                                    .play(song, queue: queue, index: i);
                              },
                            ),
                            onDismissed: (_) {
                              // Queue item removal — future enhancement
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
