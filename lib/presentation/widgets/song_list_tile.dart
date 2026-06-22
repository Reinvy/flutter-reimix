import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/entities/song.dart';
import 'reimix_dialog.dart';

/// Formats a duration in milliseconds to mm:ss
String _formatDuration(int ms) {
  final d = Duration(milliseconds: ms);
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// A list tile representing a single [Song].
///
/// Shows album art thumbnail, title, artist, duration, and a long-press
/// context menu with quick actions.
class SongListTile extends ConsumerWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPlaying;

  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final accentColor = colorScheme.tertiary;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showContextMenu(context, ref),
      borderRadius: BorderRadius.circular(AppDimensions.sp12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: AppDimensions.sp8,
        ),
        child: Row(
          children: [
            // Album art
            _AlbumArtThumbnail(
              artPath: song.albumArtPath,
              size: AppDimensions.albumArtListSize,
              isPlaying: isPlaying,
              accentColor: accentColor,
            ),
            const SizedBox(width: AppDimensions.sp12),
            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium(color: isPlaying ? accentColor : textColor),
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
            const SizedBox(width: AppDimensions.sp8),
            // Duration
            Text(
              _formatDuration(song.durationMs),
              style: AppTextStyles.labelSmall(color: subtextColor),
            ),
            const SizedBox(width: AppDimensions.sp4),
            // More options
            GestureDetector(
              onTap: () => _showContextMenu(context, ref),
              child: FaIcon(FontAwesomeIcons.ellipsisVertical, size: 18, color: subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReimixDialog(
        title: song.title,
        icon: FontAwesomeIcons.music,
        body: _SongContextMenu(song: song, ref: ref),
      ),
    );
  }
}

// ── Album Art Thumbnail ───────────────────────────────────────────────────────

class _AlbumArtThumbnail extends StatelessWidget {
  final String? artPath;
  final double size;
  final bool isPlaying;
  final Color accentColor;

  const _AlbumArtThumbnail({
    required this.artPath,
    required this.size,
    required this.isPlaying,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusAlbumArtList),
            child: _buildImage(),
          ),
          if (isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(180),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusAlbumArtList),
                ),
                child: Center(
                  child: FaIcon(FontAwesomeIcons.chartSimple, color: Colors.white, size: size * 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (artPath != null && artPath!.isNotEmpty) {
      if (artPath!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: artPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        );
      }
      return Image.file(
        File(artPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: AppColorsLight.primary,
      child: const Center(
        child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent, size: 18),
      ),
    );
  }
}

// ── Context Menu ──────────────────────────────────────────────────────────────

class _SongContextMenu extends StatelessWidget {
  final Song song;
  final WidgetRef ref;

  const _SongContextMenu({required this.song, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.sp12),
          child: Text(
            song.artist ?? 'Unknown Artist',
            style: AppTextStyles.bodyMedium(color: subtextColor).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ReimixDialogMenuItem(
          icon: FontAwesomeIcons.circlePlay,
          label: 'Play Next',
          onTap: () => Navigator.pop(context),
        ),
        const _AddToPlaylistItem(),
        ReimixDialogMenuItem(
          icon: song.isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
          label: song.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
          onTap: () => Navigator.pop(context),
        ),
        ReimixDialogMenuItem(
          icon: FontAwesomeIcons.shareNodes,
          label: 'Share',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContextMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FaIcon(icon, color: AppColorsLight.accent, size: 18),
      title: Text(label, style: AppTextStyles.titleMedium()),
      onTap: onTap,
    );
  }
}

// ── Add to Playlist context item with checkmark animation ─────────────────────

class _AddToPlaylistItem extends StatefulWidget {
  const _AddToPlaylistItem();

  @override
  State<_AddToPlaylistItem> createState() => _AddToPlaylistItemState();
}

class _AddToPlaylistItemState extends State<_AddToPlaylistItem> {
  bool _checked = false;

  void _onTap() async {
    setState(() => _checked = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeIconColor = isDark ? AppColorsDark.accent : AppColorsLight.accent;

    return ReimixDialogMenuItem(
      icon: _checked ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.circlePlus,
      iconColor: _checked ? Colors.green : activeIconColor,
      label: AppStrings.addToPlaylist,
      onTap: _onTap,
    );
  }
}
