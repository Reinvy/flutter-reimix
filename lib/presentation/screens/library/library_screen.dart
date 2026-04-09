import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import 'songs_tab.dart';
import 'albums_tab.dart';
import 'artists_tab.dart';
import 'folders_tab.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final accentColor = Theme.of(context).colorScheme.tertiary;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(AppStrings.songs, style: AppTextStyles.headlineMedium(color: textColor)),
          bottom: TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
            labelStyle: AppTextStyles.titleMedium().copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.bodyMedium(),
            tabs: const [
              Tab(text: AppStrings.songs),
              Tab(text: AppStrings.albums),
              Tab(text: AppStrings.artists),
              Tab(text: AppStrings.folders),
            ],
          ),
        ),
        body: const TabBarView(children: [SongsTab(), AlbumsTab(), ArtistsTab(), FoldersTab()]),
      ),
    );
  }
}
