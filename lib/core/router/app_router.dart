import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors/app_exceptions.dart';
import '../../main.dart' show libraryWasRebuilt;
import '../../presentation/providers/mood_provider.dart';
import '../../presentation/providers/player_provider.dart';
import '../../presentation/screens/focus_mode/focus_mode_screen.dart';
import '../../domain/entities/song.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/library/library_detail_screen.dart';
import '../../presentation/screens/now_playing/now_playing_screen.dart';
import '../../presentation/screens/onboarding/permission_screen.dart';
import '../../presentation/screens/playlist/playlist_detail_screen.dart';
import '../../presentation/screens/playlist/playlists_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/widgets/breath_overlay.dart';
import '../../presentation/widgets/mini_player.dart';
import '../../presentation/widgets/floating_bottom_nav_bar.dart';
import '../../presentation/widgets/pulse_ripple_overlay.dart';
import '../../presentation/widgets/rain_overlay.dart';
import '../../presentation/widgets/sakura_overlay.dart';
import '../../presentation/widgets/star_overlay.dart';
import '../theme/mood_theme.dart';

/// Named route constants
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String permission = '/onboarding/permission';
  static const String home = '/home';
  static const String homeIndex = '/home/index';
  static const String library = '/library';
  static const String playlists = '/playlists';
  static const String playlistDetail = '/playlists/detail/:id';
  static const String search = '/search';
  static const String nowPlaying = '/now-playing';
  static const String focusMode = '/focus-mode';
  static const String stats = '/stats';
  static const String settings = '/settings';
}

/// Slide-from-right + fade transition used for all full-screen route pushes.
Page<T> _buildPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _buildPage(state, const SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.permission,
      pageBuilder: (context, state) => _buildPage(state, const PermissionScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          redirect: (context, state) =>
              state.matchedLocation == AppRoutes.home ? AppRoutes.homeIndex : null,
          routes: [GoRoute(path: 'index', builder: (context, state) => const HomeScreen())],
        ),
        GoRoute(
          path: AppRoutes.library,
          builder: (context, state) => const LibraryScreen(),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                return LibraryDetailScreen(
                  title: extra['title'] as String,
                  type: extra['type'] as String,
                  songs: extra['songs'] as List<Song>,
                  subtitle: extra['subtitle'] as String?,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.playlists,
          builder: (context, state) => const PlaylistsScreen(),
          routes: [
            GoRoute(
              path: 'detail/:id',
              builder: (context, state) => PlaylistDetailScreen(
                playlistId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
            GoRoute(
              path: 'smart/:type',
              builder: (context, state) =>
                  PlaylistDetailScreen(smartType: state.pathParameters['type']),
            ),
          ],
        ),
        GoRoute(path: AppRoutes.search, builder: (context, state) => const SearchScreen()),
      ],
    ),
    GoRoute(
      path: AppRoutes.nowPlaying,
      pageBuilder: (context, state) => _buildPage(state, const NowPlayingScreen()),
    ),
    GoRoute(
      path: AppRoutes.focusMode,
      pageBuilder: (context, state) => _buildPage(state, const FocusModeScreen()),
    ),
    GoRoute(
      path: AppRoutes.stats,
      pageBuilder: (context, state) => _buildPage(state, const StatsScreen()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => _buildPage(state, const SettingsScreen()),
    ),
  ],
);

/// Bottom navigation shell — wraps the 4 main tabs
class _MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  static const _tabs = [
    AppRoutes.homeIndex,
    AppRoutes.library,
    AppRoutes.playlists,
    AppRoutes.search,
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere(
      (t) => location.startsWith('${t.split('/').first}/${t.split('/').last}'),
    );
    return index < 0 ? 0 : index;
  }

  Widget _moodOverlay(MoodType mood, Widget child) {
    switch (mood) {
      case MoodType.calm:
        return SakuraOverlay(child: child);
      case MoodType.sad:
        return RainOverlay(child: child);
      case MoodType.energetic:
        return PulseRippleOverlay(child: child);
      case MoodType.night:
        return StarOverlay(child: child);
      case MoodType.focus:
        return BreathOverlay(child: child);
    }
  }

  @override
  void initState() {
    super.initState();
    if (libraryWasRebuilt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u{1F5C4}\uFE0F Library rebuilt — please rescan your music.'),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(moodProvider);

    // Show a snackbar when an audio file cannot be played, then skip to next.
    ref.listen<AsyncValue<AudioException>>(audioErrorStreamProvider, (_, next) {
      next.whenData((err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File not found \u2014 skipping song.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(playerProvider.notifier).skipToNext();
      });
    });

    return Scaffold(
      extendBody: true,
      body: _moodOverlay(
        mood,
        Stack(
          children: [
            widget.child,
            // Floating MiniPlayer sits above the Floating Nav Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 88 + MediaQuery.paddingOf(context).bottom,
              child: const MiniPlayer(),
            ),
            // Floating Bottom Nav Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom,
              child: FloatingBottomNavBar(
                selectedIndex: _selectedIndex(context),
                onTap: (i) => context.go(_tabs[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
