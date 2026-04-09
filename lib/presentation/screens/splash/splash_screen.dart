import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Start logo fade-in after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fadeController.forward();
    });

    // Navigate after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(AppStrings.prefOnboardingComplete) ?? false;
    if (!mounted) return;
    context.go(onboardingComplete ? AppRoutes.homeIndex : AppRoutes.permission);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsLight.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Petal animation placeholder — Lottie will be wired up when asset is added
          _PetalBackground(),

          // Logo + wordmark
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon placeholder (replaced with real asset in Step 6)
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColorsLight.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColorsLight.shadow,
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppColorsLight.accent,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColorsLight.onBackground,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your mood. Your music.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColorsLight.subtext),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sakura petal background — uses Lottie when the asset file is present,
/// falls back to an animated gradient shimmer otherwise.
class _PetalBackground extends StatefulWidget {
  @override
  State<_PetalBackground> createState() => _PetalBackgroundState();
}

class _PetalBackgroundState extends State<_PetalBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  static const _lottieAsset = 'assets/lottie/sakura_splash.json';

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Try Lottie; if not available, show animated gradient fallback
    return FutureBuilder<bool>(
      future: _assetExists(_lottieAsset),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return const _LottieSakura(asset: _lottieAsset);
        }
        return AnimatedBuilder(
          animation: _shimmerAnim,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    AppColorsLight.background,
                    AppColorsLight.primary,
                    _shimmerAnim.value,
                  )!,
                  AppColorsLight.background,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _LottieSakura extends StatelessWidget {
  final String asset;
  const _LottieSakura({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(asset, fit: BoxFit.cover, repeat: true);
  }
}
