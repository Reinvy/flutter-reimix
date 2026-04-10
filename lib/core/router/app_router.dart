import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_dimensions.dart';
import '../../presentation/providers/mood_provider.dart';
import '../../presentation/screens/focus_mode/focus_mode_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/now_playing/now_playing_screen.dart';
import '../../presentation/screens/onboarding/permission_screen.dart';
import '../../presentation/screens/playlist/playlist_detail_screen.dart';
import '../../presentation/screens/playlist/playlists_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/widgets/breath_overlay.dart';
import '../../presentation/widgets/mini_player.dart';
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

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(path: AppRoutes.permission, builder: (context, state) => const PermissionScreen()),
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          redirect: (context, state) =>
              state.matchedLocation == AppRoutes.home ? AppRoutes.homeIndex : null,
          routes: [GoRoute(path: 'index', builder: (context, state) => const HomeScreen())],
        ),
        GoRoute(path: AppRoutes.library, builder: (context, state) => const LibraryScreen()),
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
    GoRoute(path: AppRoutes.nowPlaying, builder: (context, state) => const NowPlayingScreen()),
    GoRoute(path: AppRoutes.focusMode, builder: (context, state) => const FocusModeScreen()),
    GoRoute(path: AppRoutes.stats, builder: (context, state) => const StatsScreen()),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
    ),
  ],
);

/// Bottom navigation shell — wraps the 4 main tabs
class _MainShell extends ConsumerWidget {
  final Widget child;
  const _MainShell({required this.child});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodProvider);
    return Scaffold(
      body: _moodOverlay(
        mood,
        Stack(
          children: [
            child,
            // Mini player sits above the bottom nav bar
            const Positioned(
              left: 0,
              right: 0,
              bottom: AppDimensions.bottomNavHeight,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music_outlined), label: 'Playlists'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}

/// Temporary placeholder for Settings (Step 5)
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
    );
  }
}
