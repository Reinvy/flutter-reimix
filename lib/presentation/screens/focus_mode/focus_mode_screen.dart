import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/player_provider.dart';

// ── Notification helpers ──────────────────────────────────────────────────────

final _notifications = FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(android: android, iOS: iosSettings);
  await _notifications.initialize(settings);

  // Request notification permission at runtime (Android 13+ / iOS)
  if (Platform.isAndroid) {
    await Permission.notification.request();
  } else if (Platform.isIOS) {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }
}

Future<void> _showSleepTimerEndedNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'reimix_sleep_timer',
    'Sleep Timer',
    channelDescription: 'Notifies when the sleep timer ends',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  await _notifications.show(1, 'Reimix', 'Sleep timer ended', details);
}

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
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;
  bool _timerActive = false;
  bool _endOfSong = false;

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
    _fadeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onTimerExpired();
    });

    _initNotifications();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _countdownTimer?.cancel();
    _fadeCtrl.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Timer logic ────────────────────────────────────────────────────────────

  void _startTimer(Duration duration, {bool endOfSong = false}) {
    _countdownTimer?.cancel();
    setState(() {
      _timerDuration = duration;
      _remaining = duration;
      _timerActive = true;
      _endOfSong = endOfSong;
    });
    _fadeCtrl.reset();

    if (endOfSong) return; // handled by player stream

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds <= 1) {
          _remaining = Duration.zero;
          _countdownTimer?.cancel();
          _beginFadeOut();
        } else {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _fadeCtrl.stop();
    setState(() {
      _timerActive = false;
      _timerDuration = null;
      _remaining = Duration.zero;
    });
  }

  void _beginFadeOut() {
    _fadeCtrl.forward();
  }

  Future<void> _onTimerExpired() async {
    await _showSleepTimerEndedNotification();
    await ref.read(playerProvider.notifier).stop();
    if (mounted) Navigator.of(context).pop();
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
          child: AlertDialog(
            title: const Text(AppStrings.permissionNotifRequiredTitle),
            content: const Text(AppStrings.permissionNotifRequiredBody),
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SleepTimerSheet(
        isActive: _timerActive,
        remaining: _remaining,
        onSelect: (d, {bool endOfSong = false}) {
          Navigator.pop(ctx);
          _startTimer(d, endOfSong: endOfSong);
        },
        onCancel: () {
          Navigator.pop(ctx);
          _cancelTimer();
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final accent = Theme.of(context).colorScheme.tertiary;

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
                  child: Image.file(
                    File(song!.albumArtPath!),
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
                      child: Image.file(
                        File(song!.albumArtPath!),
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
                  if (_timerActive) ...[
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: _CountdownRing(
                        progress: _timerDuration != null && _timerDuration!.inSeconds > 0
                            ? _remaining.inSeconds / _timerDuration!.inSeconds
                            : 1.0,
                        color: accent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _endOfSong ? 'End' : _formatDuration(_remaining),
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
                    label: Text(_timerActive ? 'Edit Timer' : 'Sleep Timer'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColorsDark.surface : AppColorsLight.surface;

    final presets = [
      ('15 min', const Duration(minutes: 15)),
      ('30 min', const Duration(minutes: 30)),
      ('45 min', const Duration(minutes: 45)),
      ('60 min', const Duration(minutes: 60)),
    ];

    return Container(
      margin: const EdgeInsets.all(AppDimensions.sp16),
      padding: const EdgeInsets.all(AppDimensions.sp16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBottomSheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.sp16),
              decoration: BoxDecoration(
                color: AppColorsLight.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Sleep Timer', style: AppTextStyles.titleLarge()),
          const SizedBox(height: AppDimensions.sp16),

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
      ),
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
