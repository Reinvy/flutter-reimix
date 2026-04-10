import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/song_list_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final searchState = ref.watch(searchProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = searchState.query.trim();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPaddingH,
                AppDimensions.sp16,
                AppDimensions.screenPaddingH,
                AppDimensions.sp8,
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                decoration: InputDecoration(
                  hintText: 'Songs, albums, artists…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _ctrl.clear();
                            ref.read(searchProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColorsDark.surface : AppColorsLight.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (q) {
                  ref.read(searchProvider.notifier).setQuery(q);
                },
                onSubmitted: (q) {
                  ref.read(searchProvider.notifier).commitSearch(q);
                },
                textInputAction: TextInputAction.search,
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: query.isEmpty
                  ? _RecentSearches(
                      recents: searchState.recentSearches,
                      onSelect: (q) {
                        _ctrl.text = q;
                        ref.read(searchProvider.notifier).selectRecent(q);
                      },
                      onRemove: (q) => ref.read(searchProvider.notifier).removeRecent(q),
                      onClearAll: () => ref.read(searchProvider.notifier).clearRecents(),
                    )
                  : resultsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (results) {
                        if (results.isEmpty) {
                          return _NoResults(query: query);
                        }
                        return _ResultsList(
                          results: results,
                          onSongTap: (s) {
                            ref.read(searchProvider.notifier).commitSearch(query);
                            ref.read(playerProvider.notifier).play(s);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent searches ───────────────────────────────────────────────────────────

class _RecentSearches extends StatelessWidget {
  final List<String> recents;
  final void Function(String) onSelect;
  final void Function(String) onRemove;
  final VoidCallback onClearAll;

  const _RecentSearches({
    required this.recents,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    if (recents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 64, color: subtext.withAlpha(100)),
            const SizedBox(height: AppDimensions.sp12),
            Text('Search your music', style: AppTextStyles.bodyMedium(color: subtext)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Recent Searches', style: AppTextStyles.labelMedium(color: subtext)),
            ),
            TextButton(onPressed: onClearAll, child: const Text('Clear all')),
          ],
        ),
        const SizedBox(height: AppDimensions.sp8),
        Wrap(
          spacing: AppDimensions.sp8,
          runSpacing: AppDimensions.sp8,
          children: recents
              .map(
                (q) => InputChip(
                  label: Text(q),
                  onPressed: () => onSelect(q),
                  onDeleted: () => onRemove(q),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── No results ────────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_off_rounded, size: 64, color: subtext.withAlpha(100)),
          const SizedBox(height: AppDimensions.sp12),
          Text(
            'No results for "$query"',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium(color: subtext),
          ),
          const SizedBox(height: AppDimensions.sp8),
          Text('Try a different keyword.', style: AppTextStyles.bodyMedium(color: subtext)),
        ],
      ),
    );
  }
}

// ── Results list ──────────────────────────────────────────────────────────────

class _ResultsList extends ConsumerWidget {
  final SearchResults results;
  final void Function(Song) onSongTap;

  const _ResultsList({required this.results, required this.onSongTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return ListView(
      children: [
        if (results.songs.isNotEmpty) ...[
          _SectionHeader(title: 'Songs (${results.songs.length})', color: subtext),
          ...results.songs.map((s) => SongListTile(song: s, onTap: () => onSongTap(s))),
        ],
        if (results.albums.isNotEmpty) ...[
          _SectionHeader(title: 'Albums (${results.albums.length})', color: subtext),
          ...results.albums.map((a) => _AlbumResultTile(album: a)),
        ],
        if (results.artists.isNotEmpty) ...[
          _SectionHeader(title: 'Artists (${results.artists.length})', color: subtext),
          ...results.artists.map((a) => _ArtistResultTile(artist: a)),
        ],
        if (results.playlists.isNotEmpty) ...[
          _SectionHeader(title: 'Playlists (${results.playlists.length})', color: subtext),
          ...results.playlists.map((p) => _PlaylistResultTile(playlist: p)),
        ],
        const SizedBox(height: 120),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        AppDimensions.sp16,
        AppDimensions.screenPaddingH,
        AppDimensions.sp4,
      ),
      child: Text(title, style: AppTextStyles.labelMedium(color: color)),
    );
  }
}

class _AlbumResultTile extends StatelessWidget {
  final Album album;
  const _AlbumResultTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.sp8),
        child: album.artPath != null
            ? Image.file(
                File(album.artPath!),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _albumPlaceholder(),
              )
            : _albumPlaceholder(),
      ),
      title: Text(
        album.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.titleMedium(),
      ),
      subtitle: Text(album.artist ?? 'Unknown Artist', style: AppTextStyles.bodyMedium()),
    );
  }

  Widget _albumPlaceholder() => Container(
    width: 44,
    height: 44,
    color: AppColorsLight.primary,
    child: const Icon(Icons.album_rounded, color: AppColorsLight.accent),
  );
}

class _ArtistResultTile extends StatelessWidget {
  final Artist artist;
  const _ArtistResultTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      leading: CircleAvatar(
        backgroundColor: AppColorsLight.primary,
        child: Text(
          artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColorsLight.accent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        artist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.titleMedium(),
      ),
      subtitle: Text('${artist.songCount} songs', style: AppTextStyles.bodyMedium()),
    );
  }
}

class _PlaylistResultTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistResultTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColorsLight.primary,
          borderRadius: BorderRadius.circular(AppDimensions.sp8),
        ),
        child: const Icon(Icons.queue_music_rounded, color: AppColorsLight.accent),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.titleMedium(),
      ),
      subtitle: Text('${playlist.songs.length} songs', style: AppTextStyles.bodyMedium()),
    );
  }
}
