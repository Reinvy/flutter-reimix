import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtists = ref.watch(artistsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.tertiary;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return asyncArtists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium())),
      data: (artists) {
        if (artists.isEmpty) {
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
        return ListView.builder(
          itemCount: artists.length + 1,
          itemBuilder: (context, i) {
            if (i == artists.length) {
              return SizedBox(height: ref.watch(playerProvider).currentSong != null ? 170 : 100);
            }
            final artist = artists[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: AppDimensions.sp4,
              ),
              leading: CircleAvatar(
                backgroundColor: accentColor.withAlpha(30),
                child: Center(
                  child: FaIcon(FontAwesomeIcons.user, color: accentColor, size: 16),
                ),
              ),
              title: Text(artist.name, style: AppTextStyles.titleMedium()),
              subtitle: Text(
                '${artist.songCount} ${artist.songCount == 1 ? 'song' : 'songs'}',
                style: AppTextStyles.labelSmall(color: subtextColor),
              ),
              trailing: FaIcon(FontAwesomeIcons.chevronRight, color: subtextColor, size: 14),
              onTap: () {
                // Artist detail screen is Step 4
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(artist.name),
                    backgroundColor: accentColor,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
