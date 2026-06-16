import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistProvider);
    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final onBg = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final accent = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPaddingH,
                AppDimensions.sp16,
                AppDimensions.screenPaddingH,
                AppDimensions.sp8,
              ),
              sliver: SliverToBoxAdapter(
                child: Text('Playlists', style: AppTextStyles.headlineLarge(color: onBg)),
              ),
            ),

            // ── Smart playlists ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPaddingH,
                  AppDimensions.sp8,
                  AppDimensions.screenPaddingH,
                  0,
                ),
                child: Text(
                  'Smart Playlists',
                  style: AppTextStyles.labelMedium(
                    color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  _SmartPlaylistTile(
                    icon: FontAwesomeIcons.clockRotateLeft,
                    label: 'Recently Played',
                    subtitle: recentlyPlayedAsync.when(
                      data: (s) => '${s.length} songs',
                      loading: () => '—',
                      error: (_, __) => '—',
                    ),
                    songs: recentlyPlayedAsync.valueOrNull ?? [],
                    smartType: 'recently_played',
                    onTap: () => context.go('/playlists/smart/recently_played'),
                  ),
                  _SmartPlaylistTile(
                    icon: FontAwesomeIcons.chartLine,
                    label: 'Most Played',
                    subtitle: ref
                        .watch(libraryProvider)
                        .when(
                          data: (s) => '${s.where((x) => x.playCount > 5).length} songs',
                          loading: () => '—',
                          error: (_, __) => '—',
                        ),
                    songs:
                        ref
                            .watch(libraryProvider)
                            .valueOrNull
                            ?.where((s) => s.playCount > 5)
                            .toList() ??
                        [],
                    smartType: 'most_played',
                    onTap: () => context.go('/playlists/smart/most_played'),
                  ),
                  _SmartPlaylistTile(
                    icon: FontAwesomeIcons.solidHeart,
                    label: 'Favorites',
                    subtitle: favoritesAsync.when(
                      data: (s) => '${s.length} songs',
                      loading: () => '—',
                      error: (_, __) => '—',
                    ),
                    songs: favoritesAsync.valueOrNull ?? [],
                    smartType: 'favorites',
                    onTap: () => context.go('/playlists/smart/favorites'),
                  ),
                ],
              ),
            ),

            // ── User playlists header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPaddingH,
                  AppDimensions.sp20,
                  AppDimensions.screenPaddingH,
                  0,
                ),
                child: Text(
                  'My Playlists',
                  style: AppTextStyles.labelMedium(
                    color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                  ),
                ),
              ),
            ),

            // ── User playlists ────────────────────────────────────────────────
            playlistsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (playlists) {
                final userPlaylists = playlists.where((p) => !p.isSmartPlaylist).toList();
                if (userPlaylists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sp32),
                      child: Center(
                        child: Text(
                          'No playlists yet.\nTap + to create one.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: userPlaylists.length,
                  itemBuilder: (context, i) {
                    final pl = userPlaylists[i];
                    return _UserPlaylistTile(
                      playlist: pl,
                      onTap: () => context.go('/playlists/detail/${pl.id}'),
                      onDelete: () => _confirmDelete(context, ref, pl),
                    );
                  },
                );
              },
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: ref.watch(playerProvider).currentSong != null ? 170 : 100),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: ref.watch(playerProvider).currentSong != null ? 168 : 92),
        child: FloatingActionButton(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          onPressed: () => _showCreateDialog(context, ref),
          child: const FaIcon(FontAwesomeIcons.plus),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CreatePlaylistDialog(
        onCreate: (name, coverPath) =>
            ref.read(playlistProvider.notifier).create(name, coverImagePath: coverPath),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Playlist pl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Delete "${pl.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(playlistProvider.notifier).delete(pl.id);
    }
  }
}

// ── Smart playlist tile ───────────────────────────────────────────────────────

class _SmartPlaylistTile extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String subtitle;
  final List<Song> songs;
  final String smartType;
  final VoidCallback onTap;

  const _SmartPlaylistTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.songs,
    required this.smartType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.tertiary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: accent.withAlpha(40),
          borderRadius: BorderRadius.circular(AppDimensions.sp12),
        ),
        child: Center(
          child: FaIcon(icon, color: accent, size: 16),
        ),
      ),
      title: Text(label, style: AppTextStyles.titleMedium()),
      subtitle: Text(subtitle, style: AppTextStyles.bodyMedium()),
      trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
      onTap: onTap,
    );
  }
}

// ── User playlist tile ────────────────────────────────────────────────────────

class _UserPlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserPlaylistTile({required this.playlist, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      leading: ClipRRect(borderRadius: BorderRadius.circular(AppDimensions.sp8), child: _cover()),
      title: Text(
        playlist.name,
        style: AppTextStyles.titleMedium(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${playlist.songs.length} songs', style: AppTextStyles.bodyMedium()),
      trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
      onTap: onTap,
      onLongPress: onDelete,
    );
  }

  Widget _cover() {
    if (playlist.coverImagePath != null) {
      return Image.file(
        File(playlist.coverImagePath!),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // Collage of first 4 song arts or generic icon
    final arts = playlist.songs
        .where((s) => s.albumArtPath != null)
        .map((s) => s.albumArtPath!)
        .take(4)
        .toList();
    if (arts.length >= 4) {
      return SizedBox(
        width: 48,
        height: 48,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: arts.map((p) => Image.file(File(p), fit: BoxFit.cover)).toList(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppColorsLight.primary,
      child: const Center(
        child: FaIcon(FontAwesomeIcons.list, color: AppColorsLight.accent, size: 18),
      ),
    );
  }
}

// ── Create playlist dialog ────────────────────────────────────────────────────

class _CreatePlaylistDialog extends StatefulWidget {
  final Future<void> Function(String name, String? coverPath) onCreate;

  const _CreatePlaylistDialog({required this.onCreate});

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _nameCtrl = TextEditingController();
  String? _coverPath;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) setState(() => _coverPath = xFile.path);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }
    if (name.length > 60) {
      setState(() => _error = 'Name must be 60 characters or fewer.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onCreate(name, _coverPath);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Playlist'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cover picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColorsLight.primary,
                borderRadius: BorderRadius.circular(AppDimensions.sp12),
                border: Border.all(color: AppColorsLight.divider),
              ),
              child: _coverPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.sp12),
                      child: Image.file(File(_coverPath!), fit: BoxFit.cover),
                    )
                  : const Center(
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        color: AppColorsLight.accent,
                        size: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppDimensions.sp16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(labelText: 'Playlist name', errorText: _error),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
