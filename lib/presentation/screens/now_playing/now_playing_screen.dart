import 'dart:async';
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
import '../../widgets/glassmorphic_card.dart';

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
      duration: const Duration(milliseconds: 1000),
    )..repeat();
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

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Update dominant color when song changes
    if (song != null) {
      _updateDominantColor(song.albumArtPath);
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
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final isLandscape = orientation == Orientation.landscape;
                  if (isLandscape) {
                    return _buildLandscapeLayout(context, playerState, song, isDark);
                  } else {
                    return _buildPortraitLayout(context, playerState, song, isDark);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layout builders ────────────────────────────────────────────────────────

  Widget _buildPortraitLayout(
    BuildContext context,
    PlayerState playerState,
    Song song,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildTopBar(context, isDark),
        const SizedBox(height: AppDimensions.sp8),
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
        const SizedBox(height: AppDimensions.sp12),
        // Controls panel
        _buildControlsPanel(context, playerState, song, isDark),
        const SizedBox(height: AppDimensions.sp16),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    PlayerState playerState,
    Song song,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildTopBar(context, isDark),
        Expanded(
          child: Row(
            children: [
              // Left Column: Album Art or Visualizer/Lyrics if currentTab != 0
              Expanded(
                flex: 5,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AlbumArtCard(
                          key: ValueKey(song.id),
                          artPath: song.albumArtPath,
                          isPlaying: playerState.isPlaying,
                          accentColor: _dominantColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Right Column: Lyrics/Visualizer (if currentTab != 0) + controls
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp16),
                  child: Column(
                    children: [
                      _buildTabSwitcher(isDark),
                      const SizedBox(height: AppDimensions.sp8),
                      Expanded(
                        child: _currentTab == 0
                            ? Center(
                                child: Text(
                                  "Now Playing",
                                  style: AppTextStyles.headlineMedium(color: Colors.white),
                                ),
                              )
                            : _currentTab == 1
                                ? _LyricsView(song: song, position: playerState.position)
                                : _VisualizerView(
                                    isPlaying: playerState.isPlaying,
                                    controller: _visualizerController,
                                    accentColor: _dominantColor,
                                  ),
                      ),
                      const SizedBox(height: AppDimensions.sp8),
                      _buildControlsPanel(context, playerState, song, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: Colors.white,
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
      child: AlbumArtCard(
        key: ValueKey(song.id),
        artPath: song.albumArtPath,
        isPlaying: playerState.isPlaying,
        accentColor: _dominantColor,
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────

  Widget _buildTabSwitcher(bool isDark) {
    final accentColor = _dominantColor;
    const tabs = ['Art', AppStrings.lyrics, AppStrings.visualizer];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tabs.length, (i) {
            final isSelected = _currentTab == i;
            return GestureDetector(
              onTap: () => setState(() => _currentTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sp16,
          vertical: AppDimensions.sp12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song info + favorite
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge(color: Colors.white),
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
                      onTap: () {
                        _heartController.forward(from: 0);
                        ref.read(playerProvider.notifier).toggleFavorite(song);
                      },
                      child: Transform.scale(
                        scale: scale,
                        child: FaIcon(
                          song.isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                          color: song.isFavorite ? AppColorsLight.accent : Colors.white70,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sp8),
            // Seekbar
            _Seekbar(playerState: playerState),
            const SizedBox(height: AppDimensions.sp4),
            // Volume, Speed, and Sleep Timer controls row
            Row(
              children: [
                Expanded(
                  child: _VolumeSlider(volume: playerState.volume),
                ),
                const SizedBox(width: AppDimensions.sp12),
                _SpeedSelector(speed: playerState.speed),
                const SizedBox(width: AppDimensions.sp4),
                _SleepTimerButton(sleepTimeLeft: playerState.sleepTimeLeft),
              ],
            ),
            const SizedBox(height: AppDimensions.sp8),
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
                    size: 16,
                  ),
                  onPressed: () => ref.read(playerProvider.notifier).toggleShuffle(),
                ),
                // Previous
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.backwardStep, color: Colors.white, size: 20),
                  onPressed: () => ref.read(playerProvider.notifier).skipToPrevious(),
                ),
                // Play / pause
                ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: _onPlayPauseTap,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: playerState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColorsLight.accent,
                              ),
                            )
                          : Center(
                              child: FaIcon(
                                playerState.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                color: AppColorsLight.accent,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                ),
                // Next
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.forwardStep, color: Colors.white, size: 20),
                  onPressed: () => ref.read(playerProvider.notifier).skipToNext(),
                ),
                // Repeat
                IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.repeat,
                    color: playerState.repeatMode != RepeatMode.off
                        ? AppColorsLight.accent
                        : Colors.white70,
                    size: 16,
                  ),
                  onPressed: () => ref.read(playerProvider.notifier).cycleRepeatMode(),
                ),
              ],
            ),
          ],
        ),
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

// ── Album Art Card ───────────────────────────────────────────────────────────

class AlbumArtCard extends StatefulWidget {
  final String? artPath;
  final bool isPlaying;
  final Color accentColor;

  const AlbumArtCard({
    super.key,
    this.artPath,
    required this.isPlaying,
    required this.accentColor,
  });

  @override
  State<AlbumArtCard> createState() => _AlbumArtCardState();
}

class _AlbumArtCardState extends State<AlbumArtCard> with SingleTickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    if (widget.isPlaying) {
      _breathingController.repeat(reverse: true);
    } else {
      _breathingController.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(AlbumArtCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _breathingController.repeat(reverse: true);
      } else {
        _breathingController.animateTo(0.5, duration: const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: AppDimensions.albumArtNowPlayingSize,
        height: AppDimensions.albumArtNowPlayingSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusAlbumArtNowPlaying),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withAlpha(120),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusAlbumArtNowPlaying),
          child: _buildArt(),
        ),
      ),
    );
  }

  Widget _buildArt() {
    if (widget.artPath != null && widget.artPath!.isNotEmpty) {
      if (widget.artPath!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: widget.artPath!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        );
      }
      return Image.file(
        File(widget.artPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: widget.accentColor.withAlpha(60),
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.music,
          color: widget.accentColor,
          size: 80,
        ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            trackHeight: 3,
            thumbShape: const RoundRoundSliderThumbShape(),
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
              Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(_fmt(total), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class RoundRoundSliderThumbShape extends SliderComponentShape {
  const RoundRoundSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isPressed) => const Size(12, 12);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, paint);
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
        const FaIcon(FontAwesomeIcons.volumeLow, color: Colors.white70, size: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            ),
            child: Slider(
              value: volume.clamp(0.0, 1.0),
              onChanged: (val) {
                ref.read(playerProvider.notifier).setVolume(val);
              },
            ),
          ),
        ),
        const FaIcon(FontAwesomeIcons.volumeHigh, color: Colors.white70, size: 12),
      ],
    );
  }
}

// ── Speed Selector ───────────────────────────────────────────────────────────

class _SpeedSelector extends ConsumerWidget {
  final double speed;

  const _SpeedSelector({required this.speed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<double>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.gaugeHigh, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            '${speed.toStringAsFixed(2)}x',
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      onSelected: (val) {
        ref.read(playerProvider.notifier).setSpeed(val);
      },
      itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
          .map((s) => PopupMenuItem<double>(
                value: s,
                child: Text('${s.toStringAsFixed(2)}x'),
              ))
          .toList(),
    );
  }
}

// ── Sleep Timer Button ───────────────────────────────────────────────────────

class _SleepTimerButton extends ConsumerWidget {
  final Duration? sleepTimeLeft;

  const _SleepTimerButton({required this.sleepTimeLeft});

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = sleepTimeLeft != null;
    return PopupMenuButton<int>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            color: active ? AppColorsLight.accent : Colors.white70,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            active ? _fmtDuration(sleepTimeLeft!) : 'Off',
            style: TextStyle(
              color: active ? AppColorsLight.accent : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onSelected: (val) {
        if (val == 0) {
          ref.read(playerProvider.notifier).cancelSleepTimer();
        } else {
          ref.read(playerProvider.notifier).startSleepTimer(Duration(minutes: val));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int>(value: 5, child: Text('5 Menit')),
        const PopupMenuItem<int>(value: 15, child: Text('15 Menit')),
        const PopupMenuItem<int>(value: 30, child: Text('30 Menit')),
        const PopupMenuItem<int>(value: 60, child: Text('60 Menit')),
        if (active) const PopupMenuItem<int>(value: 0, child: Text('Batal Timer')),
      ],
    );
  }
}

// ── Lyrics view ───────────────────────────────────────────────────────────────

class _LyricsView extends StatefulWidget {
  final Song song;
  final Duration position;

  const _LyricsView({required this.song, required this.position});

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  late List<MapEntry<Duration, String>> _lyrics;
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    _lyrics = _getLyricsForSong(widget.song);
  }

  @override
  void didUpdateWidget(_LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song.id != oldWidget.song.id) {
      _lyrics = _getLyricsForSong(widget.song);
      _activeIndex = -1;
    }

    // Find active index
    int newActive = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (widget.position >= _lyrics[i].key) {
        newActive = i;
      } else {
        break;
      }
    }

    if (newActive != _activeIndex) {
      setState(() {
        _activeIndex = newActive;
      });
      if (_activeIndex >= 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          _activeIndex * 64.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<MapEntry<Duration, String>> _getLyricsForSong(Song song) {
    final duration = Duration(milliseconds: song.durationMs);
    final lines = [
      "Listening to: ${song.title}",
      "By: ${song.artist ?? 'Unknown Artist'}",
      "Let the music play...",
      "Feel the heartbeat in the rhythm.",
      "Every chord strikes a memory,",
      "Every note is a story told.",
      "Walking down this silent road,",
      "Where the stars guide our steps.",
      "Lost inside this beautiful sound,",
      "No worries, no noise, just peace.",
      "The melody rises like the morning sun,",
      "Shining through the grey clouds.",
      "We drift together in this ocean of sound,",
      "Feeling the flow, breathing the vibe.",
      "As the song gently starts to fade,",
      "The echoes linger in the mind."
    ];

    final result = <MapEntry<Duration, String>>[];
    if (duration.inSeconds <= 0) return result;

    final lineCount = lines.length;
    final interval = duration.inMilliseconds / (lineCount + 1);

    for (int i = 0; i < lineCount; i++) {
      final ms = (interval * (i + 1)).round();
      result.add(MapEntry(Duration(milliseconds: ms), lines[i]));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_lyrics.isEmpty) {
      return const Center(
        child: Text(
          AppStrings.noLyrics,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 100),
      itemCount: _lyrics.length,
      itemBuilder: (context, index) {
        final isActive = index == _activeIndex;
        final line = _lyrics[index].value;

        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white30,
                fontSize: isActive ? 20 : 16,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                shadows: isActive
                    ? [
                        Shadow(
                          color: Colors.white.withAlpha(128),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Visualizer view ───────────────────────────────────────────────────────────

class _VisualizerView extends StatefulWidget {
  final bool isPlaying;
  final AnimationController controller;
  final Color accentColor;

  const _VisualizerView({
    required this.isPlaying,
    required this.controller,
    required this.accentColor,
  });

  @override
  State<_VisualizerView> createState() => _VisualizerViewState();
}

class _VisualizerViewState extends State<_VisualizerView> {
  final List<Offset> _ripples = [];
  final List<double> _rippleProgresses = [];
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      bool hasUpdates = false;
      setState(() {
        for (int i = 0; i < _rippleProgresses.length; i++) {
          if (_rippleProgresses[i] < 1.0) {
            _rippleProgresses[i] += 0.03;
            hasUpdates = true;
          }
        }
        while (_rippleProgresses.isNotEmpty && _rippleProgresses.first >= 1.0) {
          _ripples.removeAt(0);
          _rippleProgresses.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _ripples.add(details.localPosition);
      _rippleProgresses.add(0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      child: Center(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (_, __) {
              return CustomPaint(
                size: const Size(double.infinity, 160),
                painter: _FluidWavePainter(
                  progress: widget.controller.value,
                  isPlaying: widget.isPlaying,
                  color: widget.accentColor,
                  tapRipples: _ripples,
                  rippleProgresses: _rippleProgresses,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FluidWavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final List<Offset> tapRipples;
  final List<double> rippleProgresses;

  _FluidWavePainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.tapRipples,
    required this.rippleProgresses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const waveCount = 3;
    final waveColors = [
      color.withAlpha(160),
      color.withAlpha(100),
      color.withAlpha(60),
    ];
    final speeds = [1.0, 1.4, 0.7];
    final heights = [18.0, 12.0, 24.0];
    final wavelengths = [size.width * 0.8, size.width * 1.2, size.width * 0.6];

    for (int w = 0; w < waveCount; w++) {
      final paint = Paint()
        ..color = waveColors[w]
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, size.height);

      final currentSpeed = speeds[w];
      final currentHeight = isPlaying ? heights[w] : 3.0;
      final currentWavelength = wavelengths[w];

      for (double x = 0; x <= size.width; x += 4) {
        final angle = (x / currentWavelength) * 2 * math.pi + (progress * 2 * math.pi * currentSpeed);
        final y = size.height / 2 + math.sin(angle) * currentHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }

    for (int i = 0; i < tapRipples.length; i++) {
      final pos = tapRipples[i];
      final rProgress = rippleProgresses[i];
      if (rProgress >= 1.0) continue;

      final ripplePaint = Paint()
        ..color = color.withAlpha(((1.0 - rProgress) * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(pos, rProgress * 80.0, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(_FluidWavePainter oldDelegate) => true;
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
                              ref.read(playerProvider.notifier).removeFromQueue(i);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed "${song.title}" from queue'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
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

