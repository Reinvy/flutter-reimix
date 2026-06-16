import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/album_card.dart';
import '../../widgets/song_list_tile.dart';

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
                _showAlbumSheet(context, ref, album.name, album.artist, albumSongs);
              },
            );
          },
        );
      },
    );
  }

  void _showAlbumSheet(BuildContext context, WidgetRef ref, String albumName, String? artistName, List<Song> songs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    final accentColor = Theme.of(context).colorScheme.tertiary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
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
                    color: isDark ? AppColorsDark.divider : AppColorsLight.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header details
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.sp16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.compactDisc, color: accentColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sp12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              albumName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleLarge().copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              artistName ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium().copyWith(
                                color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: FaIcon(FontAwesomeIcons.circlePlay, color: accentColor, size: 28),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (songs.isNotEmpty) {
                            ref.read(playerProvider.notifier).play(songs.first, queue: songs, index: 0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? AppColorsDark.divider : AppColorsLight.divider),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: songs.length,
                    itemBuilder: (_, i) {
                      final song = songs[i];
                      return SongListTile(
                        song: song,
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(playerProvider.notifier).play(song, queue: songs, index: i);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
