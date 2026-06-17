import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/mood_theme.dart';
import 'presentation/providers/mood_provider.dart';
import 'presentation/providers/theme_provider.dart';

class ReimixApp extends ConsumerWidget {
  const ReimixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final mood = ref.watch(moodProvider);
    final moodColors = MoodTheme.of(mood);

    final lightTheme = AppTheme.light.copyWith(
      scaffoldBackgroundColor: moodColors.lightBackground,
      colorScheme: AppTheme.light.colorScheme.copyWith(tertiary: moodColors.accent),
    );
    final darkTheme = AppTheme.dark.copyWith(
      scaffoldBackgroundColor: moodColors.darkBackground,
      colorScheme: AppTheme.dark.colorScheme.copyWith(tertiary: moodColors.accent),
    );

    return AnimatedTheme(
      data: themeMode == ThemeMode.dark ? darkTheme : lightTheme,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: MaterialApp.router(
        title: 'Reimix',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
