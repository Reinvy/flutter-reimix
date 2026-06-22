import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/mood_theme.dart';
import '../../../domain/entities/song.dart';
import '../../providers/mood_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/online_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class OnlineMusicScreen extends ConsumerStatefulWidget {
  const OnlineMusicScreen({super.key});

  @override
  ConsumerState<OnlineMusicScreen> createState() => _OnlineMusicScreenState();
}

class _OnlineMusicScreenState extends ConsumerState<OnlineMusicScreen> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  int _selectedTab = 0; // 0: Songs, 1: Playlists

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
    _focus.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _triggerSearch(String query) {
    _ctrl.text = query;
    _focus.unfocus();
    ref.read(onlineSuggestProvider.notifier).clear();
    ref.read(youtubeSearchProvider.notifier).search(query);
    ref.read(youtubePlaylistSearchProvider.notifier).search(query);
    ref.read(onlineRecentsProvider.notifier).add(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final searchAsync = ref.watch(youtubeSearchProvider);
    final recents = ref.watch(onlineRecentsProvider).valueOrNull ?? [];
    final activeMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(activeMood);
    final query = _ctrl.text.trim();

    final suggestionsAsync = ref.watch(onlineSuggestProvider);
    final ytSuggestions = suggestionsAsync.valueOrNull ?? [];
    final trendingAsync = ref.watch(youtubeTrendingProvider);

    final filteredRecents = recents
        .where((q) => q.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();
    final combinedSuggestions = <String>[...filteredRecents];
    for (final s in ytSuggestions) {
      if (combinedSuggestions.length >= 10) break;
      if (!combinedSuggestions.any((x) => x.toLowerCase() == s.toLowerCase())) {
        combinedSuggestions.add(s);
      }
    }

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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      decoration: InputDecoration(
                        hintText: 'Search YouTube Music…',
                        prefixIcon: const Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: FaIcon(FontAwesomeIcons.earthAmericas, size: 16),
                        ),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _ctrl.clear();
                                  });
                                  ref.read(youtubeSearchProvider.notifier).search('');
                                  ref.read(youtubePlaylistSearchProvider.notifier).clear();
                                  ref.read(onlineSuggestProvider.notifier).clear();
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
                      onChanged: (val) {
                        setState(() {}); // trigger suffix icon show/hide
                        ref.read(onlineSuggestProvider.notifier).fetchSuggestions(val);
                      },
                      onSubmitted: (q) {
                        _triggerSearch(q);
                      },
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content area ─────────────────────────────────────────────────
            Expanded(
              child: _focus.hasFocus && query.isNotEmpty
                  ? _buildSuggestionsList(combinedSuggestions, filteredRecents, moodColors.accent)
                  : (query.isEmpty
                      ? _buildQuickLinksAndHistory(recents, moodColors, trendingAsync)
                      : Column(
                          children: [
                            _buildTabBar(moodColors.accent, textColor),
                            Expanded(
                              child: _selectedTab == 0
                                  ? searchAsync.when(
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (err, _) => Center(
                                        child: Text(
                                          'Error loading online streams.\nPlease check your connection.',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.bodyMedium(color: subtextColor),
                                        ),
                                      ),
                                      data: (results) {
                                        if (results.isEmpty) {
                                          return _buildNoResults(query, isDark);
                                        }
                                        return _buildResultsList(results);
                                      },
                                    )
                                  : ref.watch(youtubePlaylistSearchProvider).when(
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (err, _) => Center(
                                        child: Text(
                                          'Error loading playlists.\nPlease check your connection.',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.bodyMedium(color: subtextColor),
                                        ),
                                      ),
                                      data: (playlists) {
                                        if (playlists.isEmpty) {
                                          return _buildNoResults(query, isDark);
                                        }
                                        return _buildPlaylistResultsList(
                                          playlists,
                                          moodColors.accent,
                                          isDark ? AppColorsDark.surface : AppColorsLight.surface,
                                          textColor,
                                          subtextColor,
                                          isDark,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksAndHistory(
    List<String> recents,
    MoodColors moodColors,
    AsyncValue<List<Song>> trendingAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      children: [
        const SizedBox(height: AppDimensions.sp12),
        Text(
          'Explore Moods Online',
          style: AppTextStyles.titleMedium(color: moodColors.accent).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.sp12),
        // Horizontal Carousel of Mood Cards
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildMoodCard(
                title: 'Calm',
                query: 'Calm lofi study music',
                icon: FontAwesomeIcons.mugHot,
                colors: [const Color(0xFFFFD1DC), const Color(0xFFFFB7C5)],
              ),
              _buildMoodCard(
                title: 'Sad',
                query: 'Sad cinematic piano background',
                icon: FontAwesomeIcons.cloudRain,
                colors: [const Color(0xFFC5D3E8), const Color(0xFF8DA8FF)],
              ),
              _buildMoodCard(
                title: 'Energetic',
                query: 'Upbeat electronic gym workout music',
                icon: FontAwesomeIcons.bolt,
                colors: [const Color(0xFFFFCC80), const Color(0xFFFF7043)],
              ),
              _buildMoodCard(
                title: 'Night',
                query: 'Late night synthwave beats',
                icon: FontAwesomeIcons.moon,
                colors: [const Color(0xFFD1C4E9), const Color(0xFF9B8EC4)],
              ),
              _buildMoodCard(
                title: 'Focus',
                query: 'Deep focus binaural alpha waves',
                icon: FontAwesomeIcons.brain,
                colors: [const Color(0xFFA5D6A7), const Color(0xFF5BAF7A)],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.sp24),
        _buildTrendingSection(trendingAsync, moodColors.accent, textColor, subtextColor),

        const SizedBox(height: AppDimensions.sp24),
        if (recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: AppTextStyles.labelMedium(color: subtextColor)),
              TextButton(
                onPressed: () => ref.read(onlineRecentsProvider.notifier).clear(),
                child: Text('Clear', style: TextStyle(color: moodColors.accent)),
              ),
            ],
          ),
          Wrap(
            spacing: AppDimensions.sp8,
            runSpacing: AppDimensions.sp8,
            children: recents
                .map(
                  (q) => InputChip(
                    label: Text(q),
                    onPressed: () => _triggerSearch(q),
                    onDeleted: () => ref.read(onlineRecentsProvider.notifier).remove(q),
                    deleteIcon: const FaIcon(FontAwesomeIcons.xmark, size: 12),
                  ),
                )
                .toList(),
          ),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: Column(
                children: [
                  FaIcon(FontAwesomeIcons.earthAmericas, size: 48, color: subtextColor.withOpacity(0.3)),
                  const SizedBox(height: AppDimensions.sp12),
                  Text(
                    'Search YouTube to stream and download tracks',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(color: subtextColor),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 180),
      ],
    );
  }

  Widget _buildMoodCard({
    required String title,
    required String query,
    required FaIconData icon,
    required List<Color> colors,
  }) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: AppDimensions.sp12),
      child: GestureDetector(
        onTap: () => _triggerSearch(query),
        child: GlassmorphicCard(
          borderRadius: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: FaIcon(
                    icon,
                    size: 44,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.sp12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FaIcon(icon, size: 18, color: Colors.white),
                      Text(
                        title,
                        style: AppTextStyles.titleMedium(color: Colors.white).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(List<Song> songs) {
    final activeMood = ref.watch(moodProvider);
    final moodAccent = MoodTheme.of(activeMood).accent;
    final isPlaying = ref.watch(playerProvider).currentSong;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length + 1,
      itemBuilder: (context, index) {
        if (index == songs.length) {
          return const SizedBox(height: 180); // Bottom spacer
        }
        final s = songs[index];
        final isSongPlaying = isPlaying != null && isPlaying.filePath == s.filePath;

        return _buildOnlineSongTile(s, isSongPlaying, moodAccent);
      },
    );
  }

  Widget _buildOnlineSongTile(Song s, bool isSongPlaying, Color moodAccent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final videoId = s.filePath.replaceFirst('youtube://', '');
    final downloads = ref.watch(downloadQueueProvider);
    final isDownloading = downloads.containsKey(videoId);
    final downloadProgress = downloads[videoId] ?? 0.0;

    final downloadNotifier = ref.read(downloadQueueProvider.notifier);
    final isQueued = downloadNotifier.isQueued(videoId);
    final speed = downloadNotifier.getSpeed(videoId);
    final eta = downloadNotifier.getEta(videoId);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: AppDimensions.sp8,
      ),
      child: GlassmorphicCard(
        borderRadius: AppDimensions.sp12,
        child: ListTile(
          onTap: () {
            ref.read(playerProvider.notifier).play(s);
          },
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.sp8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CachedNetworkImage(
                imageUrl: s.albumArtPath!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0x3D000000),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColorsLight.primary,
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent, size: 16),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            s.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium(color: isSongPlaying ? moodAccent : textColor),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  isDownloading
                      ? (isQueued ? 'Queued in download list…' : 'Downloading at $speed')
                      : (s.artist ?? 'Unknown Channel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(color: subtextColor),
                ),
              ),
              const SizedBox(width: AppDimensions.sp8),
              Text(
                isDownloading
                    ? (isQueued ? 'Waiting' : 'ETA: $eta')
                    : _formatDuration(s.durationMs),
                style: AppTextStyles.labelSmall(color: subtextColor),
              ),
            ],
          ),
          trailing: isDownloading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: isQueued
                        ? FaIcon(FontAwesomeIcons.clock, size: 16, color: moodAccent)
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: downloadProgress,
                                strokeWidth: 2,
                                color: moodAccent,
                              ),
                              Text(
                                '${(downloadProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: moodAccent,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
              : IconButton(
                  icon: const FaIcon(FontAwesomeIcons.circleDown, size: 18),
                  color: moodAccent.withOpacity(0.85),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${s.title}"...'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    final success = await ref.read(downloadQueueProvider.notifier).download(s, ref);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Queued "${s.title}" for download!'
                              : 'Failed to download "${s.title}"',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildNoResults(String query, bool isDark) {
    final subtext = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.faceFrown, size: 64, color: subtext.withOpacity(0.3)),
          const SizedBox(height: AppDimensions.sp12),
          Text(
            'No results for "$query" on YouTube',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium(color: subtext),
          ),
          const SizedBox(height: AppDimensions.sp8),
          Text('Try searching with different keywords.', style: AppTextStyles.bodyMedium(color: subtext)),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildSuggestionsList(List<String> suggestions, List<String> filteredRecents, Color moodAccent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        final isRecent = filteredRecents.contains(suggestion);

        return ListTile(
          onTap: () => _triggerSearch(suggestion),
          leading: FaIcon(
            isRecent ? FontAwesomeIcons.clockRotateLeft : FontAwesomeIcons.magnifyingGlass,
            size: 14,
            color: isRecent ? moodAccent : subtextColor.withOpacity(0.7),
          ),
          title: Text(
            suggestion,
            style: AppTextStyles.bodyMedium(color: textColor).copyWith(
              fontWeight: isRecent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 10),
        );
      },
    );
  }

  Widget _buildTabBar(Color moodAccent, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH, vertical: 8),
      child: Row(
        children: [
          _buildTabItem(0, 'Songs', moodAccent, textColor),
          const SizedBox(width: 12),
          _buildTabItem(1, 'Playlists', moodAccent, textColor),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, Color moodAccent, Color textColor) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? moodAccent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? moodAccent : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium(color: isSelected ? moodAccent : textColor).copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection(AsyncValue<List<Song>> trendingAsync, Color moodAccent, Color textColor, Color subtextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Trending Music',
            style: AppTextStyles.titleMedium(color: moodAccent).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 175,
          child: trendingAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Could not load trending music',
                style: AppTextStyles.bodyMedium(color: subtextColor),
              ),
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return Center(
                  child: Text(
                    'No trending music found',
                    style: AppTextStyles.bodyMedium(color: subtextColor),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: songs.length,
                itemBuilder: (ctx, idx) {
                  final s = songs[idx];
                  return _buildTrendingCard(s, moodAccent, textColor, subtextColor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(Song s, Color moodAccent, Color textColor, Color subtextColor) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: AppDimensions.sp12),
      child: GestureDetector(
        onTap: () {
          ref.read(playerProvider.notifier).play(s);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: s.albumArtPath!,
                    width: 130,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.black12),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColorsLight.primary,
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.music, color: AppColorsLight.accent),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(FontAwesomeIcons.play, size: 8, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              s.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(color: textColor).copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              s.artist ?? 'Unknown artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall(color: subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistResultsList(
    List<OnlinePlaylist> playlists,
    Color moodAccent,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == playlists.length) {
          return const SizedBox(height: 180);
        }
        final p = playlists[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
            vertical: AppDimensions.sp8,
          ),
          child: GlassmorphicCard(
            borderRadius: AppDimensions.sp12,
            child: ListTile(
              onTap: () {
                _showPlaylistDetails(p, moodAccent, surfaceColor, textColor, subtextColor, isDark);
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.sp8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: p.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.black12),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColorsLight.primary,
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.list, color: AppColorsLight.accent, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                p.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium(color: textColor).copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${p.videoCount} songs',
                style: AppTextStyles.bodyMedium(color: subtextColor),
              ),
              trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
            ),
          ),
        );
      },
    );
  }

  void _showPlaylistDetails(
    OnlinePlaylist playlist,
    Color moodAccent,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final videosAsync = ref.watch(playlistVideosProvider(playlist.id));
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: playlist.thumbnailUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.music_note),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.title,
                                    style: AppTextStyles.titleMedium(color: textColor).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${playlist.videoCount} videos',
                                    style: AppTextStyles.bodyMedium(color: subtextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: videosAsync.valueOrNull == null
                                ? null
                                : () {
                                    final songs = videosAsync.value!;
                                    if (songs.isNotEmpty) {
                                      ref.read(playerProvider.notifier).play(
                                            songs.first,
                                            queue: songs,
                                            index: 0,
                                          );
                                      Navigator.pop(context);
                                    }
                                  },
                            icon: const FaIcon(FontAwesomeIcons.play, size: 12),
                            label: const Text('Play Playlist Queue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: moodAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: videosAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error loading songs: $e')),
                          data: (songs) {
                            if (songs.isEmpty) {
                              return const Center(child: Text('No videos found in this playlist.'));
                            }
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: songs.length,
                              itemBuilder: (context, idx) {
                                final song = songs[idx];
                                return ListTile(
                                  onTap: () {
                                    ref.read(playerProvider.notifier).play(song);
                                    Navigator.pop(context);
                                  },
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: song.albumArtPath ?? '',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.music_note),
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    song.artist ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: subtextColor, fontSize: 12),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
