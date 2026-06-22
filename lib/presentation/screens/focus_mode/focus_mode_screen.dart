import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/player_provider.dart';
import '../../widgets/reimix_dialog.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> with TickerProviderStateMixin {
  // ── Clock ──────────────────────────────────────────────────────────────────
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // ── Sleep timer ────────────────────────────────────────────────────────────
  Duration? _timerDuration;

  // ── Fade-out animation (10s) ───────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    // Notification service is a singleton — safe to call init() here,
    // it's a no-op if already initialised by _MainShell.
    NotificationService.instance.init();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Sleep timer sheet ──────────────────────────────────────────────────────

  Future<void> _showSleepTimerSheet() async {
    // Notification permission is required for sleep timer alerts
    var notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      notifStatus = await Permission.notification.request();
    }

    if (!mounted) return;

    if (!notifStatus.isGranted) {
      // Mandatory: user must enable notification permission to use sleep timer
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: ReimixDialog(
            title: AppStrings.permissionNotifRequiredTitle,
            icon: FontAwesomeIcons.bell,
            body: const Text(
              AppStrings.permissionNotifRequiredBody,
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettings();
                },
                child: const Text(AppStrings.openSettings),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final playerState = ref.read(playerProvider);
    final timerActive = playerState.sleepTimeLeft != null || playerState.sleepAtEndOfSong;
    final remaining = playerState.sleepTimeLeft ?? Duration.zero;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReimixDialog(
        title: 'Sleep Timer',
        icon: FontAwesomeIcons.stopwatch,
        body: _SleepTimerSheet(
          isActive: timerActive,
          remaining: remaining,
          onSelect: (d, {bool endOfSong = false}) {
            Navigator.pop(ctx);
            if (endOfSong) {
              _timerDuration = null;
              ref.read(playerProvider.notifier).startSleepTimer(Duration.zero, endOfSong: true);
            } else {
              _timerDuration = d;
              ref.read(playerProvider.notifier).startSleepTimer(d);
            }
          },
          onCancel: () {
            Navigator.pop(ctx);
            _timerDuration = null;
            ref.read(playerProvider.notifier).cancelSleepTimer();
          },
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final accent = Theme.of(context).colorScheme.tertiary;

    final sleepTimeLeft = playerState.sleepTimeLeft;
    final timerActive = sleepTimeLeft != null || playerState.sleepAtEndOfSong;
    final remaining = sleepTimeLeft ?? Duration.zero;
    final endOfSong = playerState.sleepAtEndOfSong;

    // Reset local initial duration if timer is no longer active
    if (!timerActive) {
      _timerDuration = null;
    }

    ref.listen<PlayerState>(playerProvider, (prev, next) {
      final left = next.sleepTimeLeft;
      if (left != null) {
        if (left.inSeconds <= 10 && left.inSeconds > 0) {
          if (!_fadeCtrl.isAnimating && _fadeCtrl.status == AnimationStatus.dismissed) {
            _fadeCtrl.forward();
          }
        }
      } else {
        if (_fadeCtrl.status != AnimationStatus.dismissed && !next.sleepAtEndOfSong) {
          _fadeCtrl.reset();
        }
      }

      if (prev?.sleepTimeLeft != null && left == Duration.zero) {
        if (mounted) Navigator.of(context).pop();
      }

      if (prev?.sleepAtEndOfSong == true && next.sleepAtEndOfSong == false && !next.isPlaying) {
        if (mounted) Navigator.of(context).pop();
      }
    });

    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(_fadeAnim),
        child: Stack(
          children: [
            // ── Blurred album art background ─────────────────────────────────
            if (song?.albumArtPath != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ColorFilter.mode(Colors.black.withAlpha(160), BlendMode.darken),
                  child: song!.albumArtPath!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: song.albumArtPath!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox(),
                          errorWidget: (_, __, ___) => const SizedBox(),
                        )
                      : Image.file(
                          File(song.albumArtPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                ),
              ),

            // ── Content ──────────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const Spacer(),

                  // Album art
                  if (song?.albumArtPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      child: song!.albumArtPath!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: song.albumArtPath!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _artPlaceholder(accent),
                              errorWidget: (_, __, ___) => _artPlaceholder(accent),
                            )
                          : Image.file(
                              File(song.albumArtPath!),
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _artPlaceholder(accent),
                            ),
                    )
                  else
                    _artPlaceholder(accent),

                  const SizedBox(height: AppDimensions.sp24),

                  // Clock
                  Text(
                    '$hh:$mm',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.sp8),

                  // Song info
                  if (song != null) ...[
                    Text(
                      song.title,
                      style: AppTextStyles.titleMedium(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist ?? 'Unknown Artist',
                      style: AppTextStyles.bodyMedium(color: Colors.white60),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.sp32),

                  // Countdown ring + timer info
                  if (timerActive) ...[
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: _CountdownRing(
                        progress: _timerDuration != null && _timerDuration!.inSeconds > 0
                            ? remaining.inSeconds / _timerDuration!.inSeconds
                            : 1.0,
                        color: accent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              endOfSong ? 'End' : _formatDuration(remaining),
                              style: AppTextStyles.titleMedium(color: Colors.white),
                            ),
                            Text('left', style: AppTextStyles.bodyMedium(color: Colors.white60)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sp16),
                  ],

                  // Sleep timer button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.stopwatch),
                    label: Text(timerActive ? 'Edit Timer' : 'Sleep Timer'),
                    onPressed: _showSleepTimerSheet,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artPlaceholder(Color accent) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: accent.withAlpha(60),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: const Center(
        child: FaIcon(FontAwesomeIcons.music, color: Colors.white54, size: 64),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ── Countdown ring ────────────────────────────────────────────────────────────

class _CountdownRing extends StatelessWidget {
  final double progress; // 1.0 = full, 0.0 = empty
  final Color color;
  final Widget? child;

  const _CountdownRing({required this.progress, required this.color, this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(progress: progress, color: color),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - 6;

    final trackPaint = Paint()
      ..color = color.withAlpha(40)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ── Sleep timer bottom sheet ──────────────────────────────────────────────────

class _SleepTimerSheet extends StatefulWidget {
  final bool isActive;
  final Duration remaining;
  final void Function(Duration, {bool endOfSong}) onSelect;
  final VoidCallback onCancel;

  const _SleepTimerSheet({
    required this.isActive,
    required this.remaining,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  int _customMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final presets = [
      ('15 min', const Duration(minutes: 15)),
      ('30 min', const Duration(minutes: 30)),
      ('45 min', const Duration(minutes: 45)),
      ('60 min', const Duration(minutes: 60)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

          // Preset options
          Wrap(
            spacing: AppDimensions.sp8,
            runSpacing: AppDimensions.sp8,
            children: [
              ...presets.map((p) => _TimerChip(label: p.$1, onTap: () => widget.onSelect(p.$2))),
              _TimerChip(
                label: 'End of Song',
                onTap: () => widget.onSelect(const Duration(hours: 99), endOfSong: true),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.sp16),

          // Custom time slider
          Text('Custom: $_customMinutes min', style: AppTextStyles.bodyMedium()),
          Slider(
            value: _customMinutes.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            onChanged: (v) => setState(() => _customMinutes = v.round()),
            onChangeEnd: (_) {},
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => widget.onSelect(Duration(minutes: _customMinutes)),
              child: const Text('Set Custom'),
            ),
          ),

          // Cancel (only when timer active)
          if (widget.isActive) ...[
            const Divider(),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.stopwatch, color: Colors.red, size: 18),
              title: const Text('Cancel Timer', style: TextStyle(color: Colors.red)),
              onTap: widget.onCancel,
            ),
          ],
        ],
      );
  }
}

class _TimerChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimerChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
