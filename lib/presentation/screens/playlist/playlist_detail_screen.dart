import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/song_list_tile.dart';

/// Shows songs inside a user-created playlist or a smart playlist.
///
/// Pass [playlistId] for user playlists, or [smartType] for smart playlists
/// ('recently_played', 'most_played', 'favorites').
class PlaylistDetailScreen extends ConsumerWidget {
  final int? playlistId;
  final String? smartType;

  const PlaylistDetailScreen({super.key, this.playlistId, this.smartType})
    : assert(playlistId != null || smartType != null, 'Provide playlistId or smartType');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;

    if (smartType != null) {
      return _buildSmartDetail(context, ref, isDark, bgColor);
    }
    return _buildUserDetail(context, ref, isDark, bgColor);
  }

  // ── Smart playlist ─────────────────────────────────────────────────────────

  Widget _buildSmartDetail(BuildContext context, WidgetRef ref, bool isDark, Color bgColor) {
    final libraryAsync = ref.watch(libraryProvider);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final favoritesAsync = ref.watch(favoritesProvider);

    final (String title, FaIconData icon, AsyncValue<List<Song>> songsAsync) = switch (smartType) {
      'recently_played' => ('Recently Played', FontAwesomeIcons.clockRotateLeft, recentlyPlayedAsync),
      'most_played' => (
        'Most Played',
        FontAwesomeIcons.chartLine,
        libraryAsync.whenData(
          (s) =>
              s.where((x) => x.playCount > 5).toList()
                ..sort((a, b) => b.playCount.compareTo(a.playCount)),
        ),
      ),
      'favorites' => ('Favorites', FontAwesomeIcons.solidHeart, favoritesAsync),
      _ => ('Playlist', FontAwesomeIcons.list, const AsyncData<List<Song>>([])),
    };

    return Scaffold(
      backgroundColor: bgColor,
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (songs) => _DetailBody(
          title: title,
          icon: icon,
          songs: songs,
          isSmartPlaylist: true,
          onPlayAll: (songs) => _playAll(ref, songs),
          onShuffle: (songs) => _shuffle(ref, songs),
        ),
      ),
    );
  }

  // ── User playlist ──────────────────────────────────────────────────────────

  Widget _buildUserDetail(BuildContext context, WidgetRef ref, bool isDark, Color bgColor) {
    final playlistsAsync = ref.watch(playlistProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: playlistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (playlists) {
          final pl = playlists.firstWhere(
            (p) => p.id == playlistId,
            orElse: () => Playlist(id: 0, name: 'Not found', createdAt: DateTime.now()),
          );
          if (pl.id == 0) {
            return const Center(child: Text('Playlist not found.'));
          }
          return _EditablePlaylistBody(
            playlist: pl,
            onPlayAll: (songs) => _playAll(ref, songs),
            onShuffle: (songs) => _shuffle(ref, songs),
            onRemoveSong: (songId) => ref.read(playlistProvider.notifier).removeSong(pl.id, songId),
            onReorder: (songIds) => ref.read(playlistProvider.notifier).reorder(pl.id, songIds),
          );
        },
      ),
    );
  }

  void _playAll(WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return;
    ref.read(playerProvider.notifier).play(songs.first, queue: songs, index: 0);
  }

  void _shuffle(WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return;
    final shuffled = [...songs]..shuffle();
    ref.read(playerProvider.notifier).play(shuffled.first, queue: shuffled, index: 0);
  }
}

// ── Non-editable detail body (smart playlists) ────────────────────────────────

class _DetailBody extends StatelessWidget {
  final String title;
  final FaIconData icon;
  final List<Song> songs;
  final bool isSmartPlaylist;
  final void Function(List<Song>) onPlayAll;
  final void Function(List<Song>) onShuffle;

  const _DetailBody({
    required this.title,
    required this.icon,
    required this.songs,
    required this.isSmartPlaylist,
    required this.onPlayAll,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title, style: AppTextStyles.titleLarge()),
            background: _HeaderCollage(songs: songs, icon: icon),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH,
              vertical: AppDimensions.sp16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onPlayAll(songs),
                    icon: const FaIcon(FontAwesomeIcons.play, size: 14),
                    label: const Text('Play All'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sp12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onShuffle(songs),
                    icon: const FaIcon(FontAwesomeIcons.shuffle, size: 14),
                    label: const Text('Shuffle'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, i) =>
              SongListTile(song: songs[i], onTap: () => onPlayAll(songs.sublist(i))),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }
}

// ── Editable playlist body (user playlists) ───────────────────────────────────

class _EditablePlaylistBody extends ConsumerStatefulWidget {
  final Playlist playlist;
  final void Function(List<Song>) onPlayAll;
  final void Function(List<Song>) onShuffle;
  final void Function(int songId) onRemoveSong;
  final void Function(List<int> songIds) onReorder;

  const _EditablePlaylistBody({
    required this.playlist,
    required this.onPlayAll,
    required this.onShuffle,
    required this.onRemoveSong,
    required this.onReorder,
  });

  @override
  ConsumerState<_EditablePlaylistBody> createState() => _EditablePlaylistBodyState();
}

class _EditablePlaylistBodyState extends ConsumerState<_EditablePlaylistBody> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List<Song>.from(widget.playlist.songs);
  }

  @override
  void didUpdateWidget(_EditablePlaylistBody old) {
    super.didUpdateWidget(old);
    if (old.playlist != widget.playlist) {
      _songs = List<Song>.from(widget.playlist.songs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(widget.playlist.name, style: AppTextStyles.titleLarge()),
            background: _HeaderCollage(songs: _songs, coverPath: widget.playlist.coverImagePath),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH,
              vertical: AppDimensions.sp16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onPlayAll(_songs),
                    icon: const FaIcon(FontAwesomeIcons.play, size: 14),
                    label: const Text('Play All'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sp12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onShuffle(_songs),
                    icon: const FaIcon(FontAwesomeIcons.shuffle, size: 14),
                    label: const Text('Shuffle'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_songs.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.sp32),
              child: Center(child: Text('No songs yet. Add songs from the Library.')),
            ),
          )
        else
          SliverToBoxAdapter(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _songs.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final song = _songs.removeAt(oldIndex);
                  _songs.insert(newIndex, song);
                });
                widget.onReorder(_songs.map((s) => s.id).toList());
              },
              itemBuilder: (context, i) {
                final song = _songs[i];
                return Dismissible(
                  key: ValueKey(song.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sp16),
                    child: const FaIcon(FontAwesomeIcons.trashCan, color: Colors.white, size: 18),
                  ),
                  onDismissed: (_) {
                    setState(() => _songs.removeAt(i));
                    widget.onRemoveSong(song.id);
                  },
                  child: SongListTile(
                    key: ValueKey('tile_${song.id}'),
                    song: song,
                    onLongPress: () => _confirmRemove(context, song),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Song'),
        content: Text('Remove "${song.title}" from this playlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _songs.removeWhere((s) => s.id == song.id));
      widget.onRemoveSong(song.id);
    }
  }
}

// ── Header collage ────────────────────────────────────────────────────────────

class _HeaderCollage extends StatelessWidget {
  final List<Song> songs;
  final String? coverPath;
  final FaIconData? icon;

  const _HeaderCollage({required this.songs, this.coverPath, this.icon});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.tertiary;

    // Explicit cover image
    if (coverPath != null) {
      return Image.file(File(coverPath!), fit: BoxFit.cover, width: double.infinity);
    }

    // 4-art collage
    final arts = songs
        .where((s) => s.albumArtPath != null && s.albumArtPath!.isNotEmpty)
        .map((s) => s.albumArtPath!)
        .toSet()
        .take(4)
        .toList();

    if (arts.length >= 4) {
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        children: arts
            .map(
              (p) => Image.file(
                File(p),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(accent),
              ),
            )
            .toList(),
      );
    }

    // Fallback gradient with icon
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withAlpha(180), accent.withAlpha(80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: FaIcon(
          icon ?? FontAwesomeIcons.list,
          size: 64,
          color: Colors.white.withAlpha(200),
        ),
      ),
    );
  }

  Widget _fallback(Color accent) => Container(color: accent.withAlpha(60));
}
