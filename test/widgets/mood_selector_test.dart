import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';

import 'package:reimix/core/constants/app_strings.dart';
import 'package:reimix/core/theme/mood_theme.dart';
import 'package:reimix/data/models/stats_model.dart';
import 'package:reimix/presentation/providers/mood_provider.dart';
import 'package:reimix/presentation/providers/player_provider.dart';
import 'package:reimix/presentation/screens/home/home_screen.dart';
import 'package:reimix/main.dart' as app;

import '../helpers/mock_repositories.dart';

late MockReimixAudioHandler mockHandler;

/// Wraps [HomeScreen] with the providers it needs (no router navigation required).
Widget _wrapHome({MoodType initialMood = MoodType.calm}) {
  return ProviderScope(
    overrides: [
      moodProvider.overrideWith((ref) => MoodNotifier.withInitialState(initialMood)),
      audioHandlerProvider.overrideWithValue(mockHandler),
    ],
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
    mockHandler = MockReimixAudioHandler();

    final settings = AppSettings();
    when(() => mockDb.getSettings()).thenReturn(settings);
    when(() => mockDb.settingsBox).thenReturn(mockSettingsBox);
    when(() => mockSettingsBox.put(any())).thenReturn(1);

    final playbackSubject = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
    when(() => mockHandler.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => mockHandler.playingStream).thenAnswer((_) => const Stream.empty());
    when(() => mockHandler.playbackState).thenAnswer((_) => playbackSubject);
    when(() => mockHandler.mediaItem).thenAnswer((_) => BehaviorSubject<MediaItem?>.seeded(null));

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
          audioHandlerProvider.overrideWithValue(mockHandler),
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
      await tester.ensureVisible(find.text(AppStrings.moodSad));
      await tester.tap(find.text(AppStrings.moodSad));
      await tester.pump();

      expect(container.read(moodProvider), MoodType.sad);
    });

    testWidgets('tapping Focus chip updates moodProvider state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          moodProvider.overrideWith((ref) => MoodNotifier.withInitialState(MoodType.calm)),
          audioHandlerProvider.overrideWithValue(mockHandler),
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

      await tester.ensureVisible(find.text(AppStrings.moodFocus));
      await tester.tap(find.text(AppStrings.moodFocus));
      await tester.pump();

      expect(container.read(moodProvider), MoodType.focus);
    });
  });
}
