import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../domain/entities/album.dart';

/// A square card representing a music album.
///
/// Shown in the Albums tab grid. Displays album art (120×120dp, radius 20),
/// album name, and artist name. Shows a shimmer placeholder while loading.
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumCard({super.key, required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Art square
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            child: SizedBox(
              width: AppDimensions.albumArtCardSize,
              height: AppDimensions.albumArtCardSize,
              child: _buildArt(),
            ),
          ),
          const SizedBox(height: AppDimensions.sp8),
          // Album name
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium(color: textColor),
          ),
          // Artist
          Text(
            album.artist ?? 'Unknown Artist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall(color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildArt() {
    if (album.artPath != null && album.artPath!.isNotEmpty) {
      return Image.file(
        File(album.artPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _shimmerOrPlaceholder(false),
      );
    }
    return _shimmerOrPlaceholder(true);
  }

  Widget _shimmerOrPlaceholder(bool useShimmer) {
    if (useShimmer) {
      return Shimmer.fromColors(
        baseColor: AppColorsLight.primary,
        highlightColor: AppColorsLight.secondary,
        child: Container(color: AppColorsLight.primary),
      );
    }
    return Container(
      color: AppColorsLight.primary,
      child: const Center(
        child: FaIcon(FontAwesomeIcons.compactDisc, color: AppColorsLight.accent, size: 48),
      ),
    );
  }
}
