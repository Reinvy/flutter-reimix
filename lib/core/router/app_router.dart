import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_dimensions.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/library/library_screen.dart';
import '../../presentation/screens/now_playing/now_playing_screen.dart';
import '../../presentation/screens/onboarding/permission_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/widgets/mini_player.dart';

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
          builder: (context, state) => const _PlaceholderScreen(title: 'Playlists'),
          routes: [
            GoRoute(
              path: 'detail/:id',
              builder: (context, state) =>
                  _PlaceholderScreen(title: 'Playlist ${state.pathParameters['id']}'),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const _PlaceholderScreen(title: 'Search'),
        ),
      ],
    ),
    GoRoute(path: AppRoutes.nowPlaying, builder: (context, state) => const NowPlayingScreen()),
    GoRoute(
      path: AppRoutes.focusMode,
      builder: (context, state) => const _PlaceholderScreen(title: 'Focus Mode'),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => const _PlaceholderScreen(title: 'Stats'),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const _PlaceholderScreen(title: 'Settings'),
    ),
  ],
);

/// Bottom navigation shell — wraps the 4 main tabs
class _MainShell extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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

/// Temporary placeholder while feature screens are built in Steps 2–4
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
