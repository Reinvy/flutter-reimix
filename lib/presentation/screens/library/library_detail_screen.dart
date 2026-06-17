import 'dart:io';
import 'dart:ui' as ui;

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

class LibraryDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends ConsumerState<LibraryDetailScreen> {
  late ScrollController _scrollController;
  bool _isCollapsed = false;
  static const double _collapseThreshold = 220.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isCollapsed = _scrollController.offset > _collapseThreshold;
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    final selectedMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(selectedMood);
    final moodAccent = moodColors.accent;

    final firstSongArtPath = widget.songs.isNotEmpty ? widget.songs.first.albumArtPath : null;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Collapsing Header (SliverAppBar) ─────────────────────────────
          SliverAppBar(
            expandedHeight: 340.0,
            pinned: true,
            elevation: 0,
            backgroundColor: bgColor,
            leading: IconButton(
              icon: const FaIcon(FontAwesomeIcons.chevronLeft),
              color: _isCollapsed
                  ? textColor
                  : (isDark ? Colors.white : Colors.black87),
              iconSize: 18,
              onPressed: () => context.pop(),
            ),
            title: AnimatedOpacity(
              opacity: _isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.title,
                style: AppTextStyles.titleMedium(color: textColor).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Blurred background
                  _buildBlurBackground(context, firstSongArtPath, moodColors, isDark),
                  // 2. Bottom scrim to fade out to scaffold background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          bgColor.withOpacity(0.8),
                          bgColor,
                        ],
                        stops: const [0.6, 0.9, 1.0],
                      ),
                    ),
                  ),
                  // 3. Centered content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCoverCard(context, firstSongArtPath, moodColors),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headlineMedium(
                                color: isDark ? Colors.white : Colors.black87,
                              ).copyWith(
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle ?? '${widget.songs.length} ${widget.songs.length == 1 ? 'song' : 'songs'}',
                            style: AppTextStyles.bodyMedium(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${widget.songs.length} ${widget.songs.length == 1 ? 'song' : 'songs'}',
                              style: AppTextStyles.labelSmall(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ).copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky Actions Bar ──────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              height: 80.0,
              backgroundColor: bgColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
                child: Row(
                  children: [
                    // Play All Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.songs.isEmpty
                            ? null
                            : () => ref.read(playerProvider.notifier).play(
                                  widget.songs.first,
                                  queue: widget.songs,
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
                        onPressed: widget.songs.isEmpty
                            ? null
                            : () {
                                final shuffled = [...widget.songs]..shuffle();
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
            ),
          ),

          // ── Songs List ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: widget.songs.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No songs found.',
                        style: AppTextStyles.bodyMedium(color: subtextColor),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final song = widget.songs[i];
                        final currentSong = ref.watch(playerProvider).currentSong;
                        return SongListTile(
                          song: song,
                          isPlaying: currentSong?.id == song.id,
                          onTap: () => ref.read(playerProvider.notifier).play(
                                song,
                                queue: widget.songs,
                                index: i,
                              ),
                        );
                      },
                      childCount: widget.songs.length,
                    ),
                  ),
          ),

          // ── Bottom Spacer to clear MiniPlayer / Nav Bar ──────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBackground(
    BuildContext context,
    String? artPath,
    MoodColors moodColors,
    bool isDark,
  ) {
    if (artPath != null && artPath.isNotEmpty && File(artPath).existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Image.file(
              File(artPath),
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(isDark ? 0.65 : 0.45),
          ),
        ],
      );
    }

    // Fallback gradient based on mood colors
    final moodBg = moodColors.backgroundFor(Theme.of(context).brightness);
    final moodAccent = moodColors.accent;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodBg,
            moodAccent.withOpacity(0.5),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverCard(BuildContext context, String? artPath, MoodColors moodColors) {
    final headerIcon = switch (widget.type) {
      'album' => FontAwesomeIcons.compactDisc,
      'artist' => FontAwesomeIcons.user,
      'folder' => FontAwesomeIcons.folderOpen,
      _ => FontAwesomeIcons.music,
    };

    const double cardSize = 140.0;
    final bool isArtist = widget.type == 'artist';

    Widget imageWidget;
    if (artPath != null && artPath.isNotEmpty && File(artPath).existsSync()) {
      imageWidget = Image.file(
        File(artPath),
        width: cardSize,
        height: cardSize,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        width: cardSize,
        height: cardSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              moodColors.accent.withOpacity(0.8),
              moodColors.accent.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FaIcon(headerIcon, color: Colors.white, size: 48),
        ),
      );
    }

    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isArtist ? null : BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isArtist ? BorderRadius.circular(cardSize / 2) : BorderRadius.circular(24),
        child: imageWidget,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final Color backgroundColor;

  _StickyHeaderDelegate({
    required this.child,
    required this.height,
    required this.backgroundColor,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isPinned = shrinkOffset > 0;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: isPinned ? 10.0 : 0.0,
          sigmaY: isPinned ? 10.0 : 0.0,
        ),
        child: Container(
          height: height,
          color: isPinned ? backgroundColor.withOpacity(0.85) : Colors.transparent,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
