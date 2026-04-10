import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../providers/library_provider.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with SingleTickerProviderStateMixin {
  bool _isRequesting = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    // Request all required permissions
    final audioStatus = await Permission.audio.request();

    // READ_MEDIA_IMAGES for album art (Android only)
    PermissionStatus photosStatus = PermissionStatus.granted;
    if (Platform.isAndroid) {
      photosStatus = await Permission.photos.request();
    }

    // POST_NOTIFICATIONS for sleep timer (Android 13+ / iOS)
    final notifStatus = await Permission.notification.request();

    if (!mounted) return;

    final allGranted = audioStatus.isGranted && photosStatus.isGranted && notifStatus.isGranted;

    if (allGranted) {
      await _onPermissionGranted();
      return;
    }

    setState(() => _isRequesting = false);

    final anyPermanentlyDenied =
        audioStatus.isPermanentlyDenied ||
        photosStatus.isPermanentlyDenied ||
        notifStatus.isPermanentlyDenied;

    if (anyPermanentlyDenied) {
      _showSettingsDialog();
    } else {
      _showRationaleDialog();
    }
  }

  Future<void> _onPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // Kick off library scan; errors surface through AsyncValue
    await ref.read(libraryProvider.notifier).scan();

    if (!mounted) return;
    context.go(AppRoutes.homeIndex);
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text(AppStrings.permissionDeniedTitle),
          content: const Text(AppStrings.permissionDeniedBody),
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
  }

  void _showRationaleDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text(AppStrings.permissionRetryTitle),
          content: const Text(AppStrings.permissionRetryBody),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _requestPermission();
              },
              child: const Text(AppStrings.grantAccess),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.onBackground : AppColorsLight.onBackground;
    final subtextColor = isDark ? AppColorsDark.subtext : AppColorsLight.subtext;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColorsDark.background, AppColorsDark.primary]
                : [AppColorsLight.background, AppColorsLight.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH,
              vertical: AppDimensions.sp32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Pulsing music icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColorsLight.accent.withAlpha(40),
                      border: Border.all(color: AppColorsLight.accent.withAlpha(80), width: 2),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 80,
                      color: AppColorsLight.accent,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.sp24),

                Text('🌸', style: Theme.of(context).textTheme.displaySmall),

                const SizedBox(height: AppDimensions.sp24),

                // Title
                Text(
                  AppStrings.permissionTitle,
                  style: AppTextStyles.headlineLarge(color: textColor),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.sp12),

                // Subtitle
                Text(
                  AppStrings.permissionSubtext,
                  style: AppTextStyles.bodyMedium(color: subtextColor),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsLight.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColorsLight.accent.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButtonPrimary),
                      ),
                      elevation: 0,
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            AppStrings.grantAccess,
                            style: AppTextStyles.titleLarge(color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: AppDimensions.sp32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
