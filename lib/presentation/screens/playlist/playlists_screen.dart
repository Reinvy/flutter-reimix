import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../widgets/reimix_dialog.dart';
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
import '../../widgets/glassmorphic_card.dart';

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

    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

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

            // ── Smart playlists label ─────────────────────────────────────────
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

            // ── Smart playlists Grid ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingH,
                  vertical: 12,
                ),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _SmartPlaylistCard(
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
                              gradientColors: [
                                Colors.tealAccent.shade400,
                                Colors.blueAccent.shade700,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmartPlaylistCard(
                              icon: FontAwesomeIcons.chartLine,
                              label: 'Most Played',
                              subtitle: ref.watch(libraryProvider).when(
                                    data: (s) => '${s.where((x) => x.playCount > 5).length} songs',
                                    loading: () => '—',
                                    error: (_, __) => '—',
                                  ),
                              songs: ref.watch(libraryProvider).valueOrNull
                                      ?.where((s) => s.playCount > 5)
                                      .toList() ??
                                  [],
                              smartType: 'most_played',
                              onTap: () => context.go('/playlists/smart/most_played'),
                              gradientColors: const [
                                Colors.indigoAccent,
                                Colors.purpleAccent,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmartPlaylistCard(
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
                              gradientColors: const [
                                Colors.orangeAccent,
                                Colors.redAccent,
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1.3,
                                  child: _SmartPlaylistCard(
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
                                    gradientColors: [
                                      Colors.tealAccent.shade400,
                                      Colors.blueAccent.shade700,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1.3,
                                  child: _SmartPlaylistCard(
                                    icon: FontAwesomeIcons.chartLine,
                                    label: 'Most Played',
                                    subtitle: ref.watch(libraryProvider).when(
                                          data: (s) => '${s.where((x) => x.playCount > 5).length} songs',
                                          loading: () => '—',
                                          error: (_, __) => '—',
                                        ),
                                    songs: ref.watch(libraryProvider).valueOrNull
                                            ?.where((s) => s.playCount > 5)
                                            .toList() ??
                                        [],
                                    smartType: 'most_played',
                                    onTap: () => context.go('/playlists/smart/most_played'),
                                    gradientColors: const [
                                      Colors.indigoAccent,
                                      Colors.purpleAccent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 2.8,
                            child: _SmartPlaylistCard(
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
                              gradientColors: const [
                                Colors.orangeAccent,
                                Colors.redAccent,
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── User playlists header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPaddingH,
                  AppDimensions.sp12,
                  AppDimensions.screenPaddingH,
                  12,
                ),
                child: Text(
                  'My Playlists',
                  style: AppTextStyles.labelMedium(
                    color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                  ),
                ),
              ),
            ),

            // ── User playlists Grid ───────────────────────────────────────────
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

                final gridCrossAxisCount = isWide ? 4 : 2;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final pl = userPlaylists[i];
                        return _UserPlaylistCard(
                          playlist: pl,
                          onTap: () => context.go('/playlists/detail/${pl.id}'),
                          onEllipsisTap: () => _showPlaylistContextSheet(context, ref, pl),
                          onQuickPlay: () => ref.read(playerProvider.notifier).play(
                                pl.songs.first,
                                queue: pl.songs,
                                index: 0,
                              ),
                        );
                      },
                      childCount: userPlaylists.length,
                    ),
                  ),
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
          onPressed: () => _showCreateBottomSheet(context, ref),
          child: const FaIcon(FontAwesomeIcons.plus),
        ),
      ),
    );
  }

  void _showCreateBottomSheet(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReimixDialog(
        title: 'New Playlist',
        icon: FontAwesomeIcons.folderPlus,
        body: _CreatePlaylistBottomSheet(
          onCreate: (name, coverPath) =>
              ref.read(playlistProvider.notifier).create(name, coverImagePath: coverPath),
        ),
      ),
    );
  }

  void _showPlaylistContextSheet(BuildContext context, WidgetRef ref, Playlist pl) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReimixDialog(
        title: pl.name,
        icon: FontAwesomeIcons.listUl,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReimixDialogMenuItem(
              icon: FontAwesomeIcons.circlePlay,
              label: 'Play Playlist',
              onTap: pl.songs.isEmpty
                  ? () {}
                  : () {
                      Navigator.pop(ctx);
                      ref.read(playerProvider.notifier).play(
                            pl.songs.first,
                            queue: pl.songs,
                            index: 0,
                          );
                    },
            ),
            ReimixDialogMenuItem(
              icon: FontAwesomeIcons.trashCan,
              label: 'Delete Playlist',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref, pl);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSheetCover(Playlist pl) {
    if (pl.coverImagePath != null && pl.coverImagePath!.isNotEmpty) {
      final file = File(pl.coverImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        );
      }
    }
    final arts = pl.songs
        .where((s) => s.albumArtPath != null && s.albumArtPath!.isNotEmpty)
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
    return Container(
      width: 48,
      height: 48,
      color: AppColorsLight.primary.withOpacity(0.3),
      child: const Center(
        child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent, size: 18),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Playlist pl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ReimixDialog(
        title: 'Delete Playlist',
        icon: FontAwesomeIcons.trashCan,
        accentColor: Colors.red,
        body: Text(
          'Delete "${pl.name}"? This cannot be undone.',
          style: const TextStyle(height: 1.4),
        ),
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

// ── Smart playlist Card ───────────────────────────────────────────────────────

class _SmartPlaylistCard extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String subtitle;
  final List<Song> songs;
  final String smartType;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const _SmartPlaylistCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.songs,
    required this.smartType,
    required this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Background faint icon for watermark look
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Opacity(
                      opacity: 0.12,
                      child: FaIcon(icon, size: 100, color: Colors.white),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Icon container + Play indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(icon, color: Colors.white, size: 18),
                          ),
                          if (songs.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.play,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Text info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium(color: Colors.white).copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodyMedium(
                              color: Colors.white.withOpacity(0.85),
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── User playlist Card (Grid) ─────────────────────────────────────────────────

class _UserPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onEllipsisTap;
  final VoidCallback onQuickPlay;

  const _UserPlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onEllipsisTap,
    required this.onQuickPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.tertiary;

    return GlassmorphicCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover collage/art stack
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildCover(),
                    ),
                    // Floating ellipsis button (top right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ClipOval(
                        child: Material(
                          color: Colors.black.withOpacity(0.4),
                          child: InkWell(
                            onTap: onEllipsisTap,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: FaIcon(
                                FontAwesomeIcons.ellipsisVertical,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Quick Play button (bottom right)
                    if (playlist.songs.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: ClipOval(
                          child: Material(
                            color: accent,
                            child: InkWell(
                              onTap: onQuickPlay,
                              child: const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: FaIcon(
                                  FontAwesomeIcons.play,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Text Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
                  style: AppTextStyles.bodyMedium(
                    color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (playlist.coverImagePath != null && playlist.coverImagePath!.isNotEmpty) {
      final file = File(playlist.coverImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    final arts = playlist.songs
        .where((s) => s.albumArtPath != null && s.albumArtPath!.isNotEmpty)
        .map((s) => s.albumArtPath!)
        .take(4)
        .toList();

    if (arts.length >= 4) {
      return GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: arts.map((p) => Image.file(File(p), fit: BoxFit.cover)).toList(),
      );
    } else if (arts.isNotEmpty) {
      return Image.file(
        File(arts.first),
        fit: BoxFit.cover,
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColorsLight.primary.withOpacity(0.35),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.music,
          color: AppColorsLight.accent,
          size: 24,
        ),
      ),
    );
  }
}

// ── Create playlist bottom sheet ──────────────────────────────────────────────

class _CreatePlaylistBottomSheet extends StatefulWidget {
  final Future<void> Function(String name, String? coverPath) onCreate;

  const _CreatePlaylistBottomSheet({required this.onCreate});

  @override
  State<_CreatePlaylistBottomSheet> createState() => _CreatePlaylistBottomSheetState();
}

class _CreatePlaylistBottomSheetState extends State<_CreatePlaylistBottomSheet> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final accent = Theme.of(context).colorScheme.tertiary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1.5,
                  ),
                ),
                child: _coverPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(File(_coverPath!), fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.image,
                              color: accent,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add Cover',
                              style: AppTextStyles.labelSmall(color: accent).copyWith(
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 60,
            style: AppTextStyles.titleMedium(color: textColor),
            decoration: InputDecoration(
              labelText: 'Playlist name',
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accent, width: 2),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
