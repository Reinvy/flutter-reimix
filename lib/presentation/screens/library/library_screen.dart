import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/library_provider.dart';
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

    final libraryState = ref.watch(libraryProvider);
    final showPermissionBanner = libraryState.hasError;

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
        body: Column(
          children: [
            if (showPermissionBanner)
              MaterialBanner(
                backgroundColor: isDark ? AppColorsDark.surface : AppColorsLight.surface,
                leading: Icon(Icons.folder_off_outlined, color: accentColor),
                content: Text(
                  AppStrings.storagePermissionBanner,
                  style: AppTextStyles.bodyMedium(color: textColor),
                ),
                actions: [
                  TextButton(
                    onPressed: openAppSettings,
                    child: Text(AppStrings.openSettings, style: TextStyle(color: accentColor)),
                  ),
                ],
              ),
            const Expanded(
              child: TabBarView(children: [SongsTab(), AlbumsTab(), ArtistsTab(), FoldersTab()]),
            ),
          ],
        ),
      ),
    );
  }
}
