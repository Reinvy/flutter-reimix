import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:reimix/core/constants/app_strings.dart';
import 'package:reimix/core/theme/mood_theme.dart';
import 'package:reimix/data/models/stats_model.dart';
import 'package:reimix/presentation/providers/mood_provider.dart';
import 'package:reimix/presentation/screens/home/home_screen.dart';
import 'package:reimix/main.dart' as app;

import '../helpers/mock_repositories.dart';

/// Wraps [HomeScreen] with the providers it needs (no router navigation required).
Widget _wrapHome({MoodType initialMood = MoodType.calm}) {
  return ProviderScope(
    overrides: [moodProvider.overrideWith((ref) => MoodNotifier.withInitialState(initialMood))],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(AppSettings());
  });

  late MockObjectBoxDatasource mockDb;
  late MockAppSettingsBox mockSettingsBox;

  setUp(() {
    mockSettingsBox = MockAppSettingsBox();
    mockDb = MockObjectBoxDatasource();

    final settings = AppSettings();
    when(() => mockDb.getSettings()).thenReturn(settings);
    when(() => mockDb.settingsBox).thenReturn(mockSettingsBox);
    when(() => mockSettingsBox.put(any())).thenReturn(1);

    // Inject into the global so MoodNotifier.setMood doesn't throw.
    app.objectBox = mockDb;
  });

  group('MoodSelector – rendering', () {
    testWidgets('all 5 mood labels are visible', (tester) async {
      await tester.pumpWidget(_wrapHome());
      await tester.pump();

      expect(find.text(AppStrings.moodCalm), findsOneWidget);
      expect(find.text(AppStrings.moodSad), findsOneWidget);
      expect(find.text(AppStrings.moodEnergetic), findsOneWidget);
      expect(find.text(AppStrings.moodNight), findsOneWidget);
      expect(find.text(AppStrings.moodFocus), findsOneWidget);
    });
  });

  group('MoodSelector – interaction', () {
    testWidgets('tapping Sad chip updates moodProvider state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          moodProvider.overrideWith((ref) => MoodNotifier.withInitialState(MoodType.calm)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      // Tap the sad chip
      await tester.tap(find.text(AppStrings.moodSad));
      await tester.pump();

      expect(container.read(moodProvider), MoodType.sad);
    });

    testWidgets('tapping Focus chip updates moodProvider state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          moodProvider.overrideWith((ref) => MoodNotifier.withInitialState(MoodType.calm)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(AppStrings.moodFocus));
      await tester.pump();

      expect(container.read(moodProvider), MoodType.focus);
    });
  });
}
