import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/album_card.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlbums = ref.watch(albumsProvider);
    final librarySongs = ref.watch(libraryProvider).valueOrNull ?? [];

    return asyncAlbums.when(
      loading: () => _ShimmerGrid(),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium())),
      data: (albums) {
        if (albums.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.sp32),
              child: Text(
                AppStrings.noMusicFound,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(),
              ),
            ),
          );
        }
        return GridView.builder(
          padding: EdgeInsets.only(
            left: AppDimensions.screenPaddingH,
            right: AppDimensions.screenPaddingH,
            top: 12,
            bottom: ref.watch(playerProvider).currentSong != null ? 170 : 100,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final album = albums[i];
            return AlbumCard(
              album: album,
              onTap: () {
                final albumSongs = librarySongs.where((s) => s.album == album.name).toList();
                context.push(
                  '${AppRoutes.library}/detail',
                  extra: {
                    'title': album.name,
                    'type': 'album',
                    'songs': albumSongs,
                    'subtitle': album.artist,
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColorsLight.primary.withAlpha(100),
      highlightColor: AppColorsLight.secondary.withAlpha(100),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH, vertical: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColorsLight.primary,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
