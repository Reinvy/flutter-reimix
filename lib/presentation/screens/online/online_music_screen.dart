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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
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
    ref.read(youtubeSearchProvider.notifier).search(query);
    ref.read(onlineRecentsProvider.notifier).add(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final searchAsync = ref.watch(youtubeSearchProvider);
    final recents = ref.watch(onlineRecentsProvider);
    final activeMood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(activeMood);
    final query = _ctrl.text.trim();

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
              child: query.isEmpty
                  ? _buildQuickLinksAndHistory(recents, moodColors)
                  : searchAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                        child: Text(
                          'Error loading online streams.\nPlease check your connection.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            color: isDark ? AppColorsDark.subtext : AppColorsLight.subtext,
                          ),
                        ),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return _buildNoResults(query, isDark);
                        }
                        return _buildResultsList(results);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksAndHistory(List<String> recents, MoodColors moodColors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  s.artist ?? 'Unknown Channel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(color: subtextColor),
                ),
              ),
              const SizedBox(width: AppDimensions.sp8),
              Text(
                _formatDuration(s.durationMs),
                style: AppTextStyles.labelSmall(color: subtextColor),
              ),
            ],
          ),
          trailing: isDownloading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Stack(
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
                              ? 'Downloaded "${s.title}" successfully!'
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
}
