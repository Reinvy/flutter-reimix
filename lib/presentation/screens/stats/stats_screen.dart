import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/usecases/get_listening_stats.dart';
import '../../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) => _StatsBody(stats: stats),
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final ListeningStats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onBg = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtext = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;
    final accent = Theme.of(context).colorScheme.tertiary;

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPaddingH,
            AppDimensions.sp16,
            AppDimensions.screenPaddingH,
            AppDimensions.sp8,
          ),
          sliver: SliverToBoxAdapter(
            child: Text('Listening Stats', style: AppTextStyles.headlineLarge(color: onBg)),
          ),
        ),

        // ── Hero stats row ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Time',
                    value: _formatTotal(stats.totalListenedMs),
                    icon: Icons.headphones_rounded,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: AppDimensions.sp12),
                Expanded(
                  child: _StatCard(
                    label: 'Streak',
                    value: '${stats.streak} day${stats.streak == 1 ? '' : 's'}',
                    icon: Icons.local_fire_department_rounded,
                    accent: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp24)),

        // ── 7-day bar chart ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last 7 Days', style: AppTextStyles.titleMedium(color: onBg)),
                const SizedBox(height: AppDimensions.sp12),
                SizedBox(
                  height: 160,
                  child: _BarChart(buckets: stats.weeklyMinutes, accentColor: accent),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp24)),

        // ── Top songs ────────────────────────────────────────────────────────
        if (stats.topSongs.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
            sliver: SliverToBoxAdapter(
              child: Text('Top Songs', style: AppTextStyles.titleMedium(color: onBg)),
            ),
          ),
          SliverList.builder(
            itemCount: math.min(stats.topSongs.length, 5),
            itemBuilder: (context, i) {
              final s = stats.topSongs[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingH,
                ),
                leading: CircleAvatar(
                  backgroundColor: accent.withAlpha(40),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium(),
                ),
                subtitle: Text(s.artist ?? 'Unknown', style: AppTextStyles.bodyMedium()),
                trailing: Text(
                  '${s.playCount} plays',
                  style: AppTextStyles.labelSmall(color: subtext),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.sp16)),
        ],

        // ── Top artists ──────────────────────────────────────────────────────
        if (stats.topArtists.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
            sliver: SliverToBoxAdapter(
              child: Text('Top Artists', style: AppTextStyles.titleMedium(color: onBg)),
            ),
          ),
          SliverList.builder(
            itemCount: math.min(stats.topArtists.length, 5),
            itemBuilder: (context, i) {
              final a = stats.topArtists[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingH,
                ),
                leading: CircleAvatar(
                  backgroundColor: accent.withAlpha(40),
                  child: Text(
                    a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium(),
                ),
                trailing: Text(
                  '${a.totalPlays} plays',
                  style: AppTextStyles.labelSmall(color: subtext),
                ),
              );
            },
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  String _formatTotal(int ms) {
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColorsLight.surface;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sp16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(height: AppDimensions.sp8),
          Text(value, style: AppTextStyles.headlineMedium(color: accent)),
          Text(label, style: AppTextStyles.bodyMedium()),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<int> buckets; // 7 buckets, index 0 = 6 days ago, index 6 = today
  final Color accentColor;

  const _BarChart({required this.buckets, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(buckets: buckets, accentColor: accentColor),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> buckets;
  final Color accentColor;

  const _BarChartPainter({required this.buckets, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;
    final maxVal = buckets.reduce(math.max);
    final barWidth = size.width / (buckets.length * 2 - 1);
    final barMaxH = size.height - 32;

    final barPaint = Paint()..style = PaintingStyle.fill;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return _shortDay(d.weekday);
    });

    for (int i = 0; i < buckets.length; i++) {
      final value = buckets[i];
      final x = i * barWidth * 2;
      final barH = maxVal > 0 ? (value / maxVal) * barMaxH : 0.0;

      // Bar
      barPaint.color = value == 0 ? accentColor.withAlpha(40) : accentColor.withAlpha(200);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barH - 20, barWidth, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      // Day label
      labelPainter
        ..text = TextSpan(
          text: dayLabels[i],
          style: TextStyle(fontSize: 10, color: accentColor.withAlpha(160)),
        )
        ..layout();
      labelPainter.paint(canvas, Offset(x + (barWidth - labelPainter.width) / 2, size.height - 16));
    }
  }

  String _shortDay(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.buckets != buckets || old.accentColor != accentColor;
}
