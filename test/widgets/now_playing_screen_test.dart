import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import 'package:reimix/domain/entities/song.dart';
import 'package:reimix/presentation/providers/player_provider.dart';
import 'package:reimix/presentation/screens/now_playing/now_playing_screen.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

Widget _wrapNowPlaying(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: NowPlayingScreen()),
  );
}

ProviderContainer _makeContainer(MockReimixAudioHandler handler, {bool isPlaying = true}) {
  final playbackSubject = BehaviorSubject<PlaybackState>.seeded(PlaybackState(playing: isPlaying));
  when(() => handler.positionStream).thenAnswer((_) => const Stream.empty());
  when(() => handler.playingStream).thenAnswer((_) => const Stream.empty());
  when(() => handler.playbackState).thenAnswer((_) => playbackSubject);
  when(() => handler.mediaItem).thenAnswer((_) => BehaviorSubject<MediaItem?>.seeded(null));

  return ProviderContainer(overrides: [audioHandlerProvider.overrideWithValue(handler)]);
}

void main() {
  late MockReimixAudioHandler mockHandler;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(song1);
    registerFallbackValue(<Song>[]);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockHandler = MockReimixAudioHandler();
    container = _makeContainer(mockHandler);
  });

  tearDown(() => container.dispose());

  group('NowPlayingScreen – no song loaded', () {
    testWidgets('renders without crash when currentSong is null', (tester) async {
      await tester.pumpWidget(_wrapNowPlaying(container));
      await tester.pump();

      // Should not throw; screen handles null gracefully
      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });
  });

  group('NowPlayingScreen – song loaded', () {
    setUp(() {
      when(
        () => mockHandler.playFromSong(
          any(),
          queue: any(named: 'queue'),
          queueIndex: any(named: 'queueIndex'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockHandler.currentSong).thenReturn(song1);
    });

    testWidgets('seekbar Slider widget is present', (tester) async {
      await container.read(playerProvider.notifier).play(song1);

      await tester.pumpWidget(_wrapNowPlaying(container));
      await tester.pump();
      // Give animations a frame to settle
      await tester.pump(const Duration(milliseconds: 100));

      // At least one Slider is present (seekbar + optional volume slider)
      expect(find.byType(Slider), findsAtLeastNWidgets(1));
    });

    testWidgets('song title is displayed', (tester) async {
      await container.read(playerProvider.notifier).play(song1);

      await tester.pumpWidget(_wrapNowPlaying(container));
      await tester.pump();

      expect(find.text(song1.title), findsOneWidget);
    });

    testWidgets('artist name is displayed', (tester) async {
      await container.read(playerProvider.notifier).play(song1);

      await tester.pumpWidget(_wrapNowPlaying(container));
      await tester.pump();

      expect(find.text(song1.artist!), findsOneWidget);
    });

    testWidgets('slider drag calls seek on the player', (tester) async {
      when(() => mockHandler.seek(any())).thenAnswer((_) async {});

      // Give the song a known duration so sliderValue > 0
      final songWithDuration = fakeSong(id: 1, durationMs: 180000); // 3 min
      when(
        () => mockHandler.playFromSong(
          any(),
          queue: any(named: 'queue'),
          queueIndex: any(named: 'queueIndex'),
        ),
      ).thenAnswer((_) async {});
      await container.read(playerProvider.notifier).play(songWithDuration);

      await tester.pumpWidget(_wrapNowPlaying(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Drag the first Slider (seekbar) from 0 to somewhere in the middle
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();

      verify(() => mockHandler.seek(any())).called(greaterThanOrEqualTo(1));
    });
  });
}
