import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import 'package:reimix/domain/entities/song.dart';
import 'package:reimix/presentation/providers/player_provider.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a [ProviderContainer] with all streams pre-stubbed on [mock].
ProviderContainer _makeContainer(MockReimixAudioHandler mock) {
  final playbackSubject = BehaviorSubject<PlaybackState>.seeded(PlaybackState());

  when(() => mock.positionStream).thenAnswer((_) => const Stream.empty());
  when(() => mock.playingStream).thenAnswer((_) => const Stream.empty());
  when(() => mock.playbackState).thenAnswer((_) => playbackSubject);

  return ProviderContainer(overrides: [audioHandlerProvider.overrideWithValue(mock)]);
}

void main() {
  late MockReimixAudioHandler mockHandler;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(song1);
    registerFallbackValue(<Song>[]);
    registerFallbackValue(AudioServiceShuffleMode.none);
  });

  setUp(() {
    mockHandler = MockReimixAudioHandler();
    container = _makeContainer(mockHandler);
  });

  tearDown(() {
    container.dispose();
  });

  group('PlayerProvider – initial state', () {
    test('starts with empty/default values', () {
      final state = container.read(playerProvider);

      expect(state.currentSong, isNull);
      expect(state.queue, isEmpty);
      expect(state.isPlaying, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.position, Duration.zero);
      expect(state.shuffleMode, ShuffleMode.off);
      expect(state.repeatMode, RepeatMode.off);
      expect(state.volume, 1.0);
    });
  });

  group('PlayerProvider.play', () {
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

    test('sets currentSong synchronously', () async {
      await container.read(playerProvider.notifier).play(song1);

      expect(container.read(playerProvider).currentSong, equals(song1));
    });

    test('sets isLoading to true while handler call is in flight', () async {
      // Capture state during flight
      PlayerState? stateBeforeHandler;
      when(
        () => mockHandler.playFromSong(
          any(),
          queue: any(named: 'queue'),
          queueIndex: any(named: 'queueIndex'),
        ),
      ).thenAnswer((_) async {
        stateBeforeHandler = container.read(playerProvider);
      });

      await container.read(playerProvider.notifier).play(song1);

      expect(stateBeforeHandler?.isLoading, isTrue);
    });

    test('stores full queue when provided', () async {
      final queue = [song1, song2];
      await container.read(playerProvider.notifier).play(song1, queue: queue);

      expect(container.read(playerProvider).queue, equals(queue));
    });

    test('uses single-song queue when no queue passed', () async {
      await container.read(playerProvider.notifier).play(song1);

      expect(container.read(playerProvider).queue, [song1]);
    });
  });

  group('PlayerProvider.stop', () {
    setUp(() {
      when(() => mockHandler.stop()).thenAnswer((_) async {});
      when(
        () => mockHandler.playFromSong(
          any(),
          queue: any(named: 'queue'),
          queueIndex: any(named: 'queueIndex'),
        ),
      ).thenAnswer((_) async {});
    });

    test('resets state to defaults', () async {
      await container.read(playerProvider.notifier).play(song1);
      await container.read(playerProvider.notifier).stop();

      final state = container.read(playerProvider);
      expect(state.currentSong, isNull);
      expect(state.isPlaying, isFalse);
    });
  });

  group('PlayerProvider.toggleShuffle', () {
    setUp(() {
      when(() => mockHandler.setShuffleMode(any())).thenAnswer((_) async {});
    });

    test('toggles shuffleMode from off → on', () async {
      await container.read(playerProvider.notifier).toggleShuffle();

      expect(container.read(playerProvider).shuffleMode, ShuffleMode.on);
    });

    test('toggles shuffleMode from on → off', () async {
      // First toggle: off → on
      await container.read(playerProvider.notifier).toggleShuffle();
      // Second toggle: on → off
      await container.read(playerProvider.notifier).toggleShuffle();

      expect(container.read(playerProvider).shuffleMode, ShuffleMode.off);
    });
  });

  group('PlayerProvider.skipToNext', () {
    setUp(() {
      when(() => mockHandler.skipToNext()).thenAnswer((_) async {});
      when(() => mockHandler.currentSong).thenReturn(song2);
    });

    test('updates currentSong from handler after skip', () async {
      await container.read(playerProvider.notifier).skipToNext();

      expect(container.read(playerProvider).currentSong, equals(song2));
    });
  });
}
