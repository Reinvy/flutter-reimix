import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import 'package:reimix/domain/entities/song.dart';
import 'package:reimix/presentation/providers/player_provider.dart';
import 'package:reimix/presentation/widgets/mini_player.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

// Minimal router needed because MiniPlayer uses context.push
final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const _TestShell()),
    GoRoute(path: '/now-playing', builder: (_, __) => const Scaffold()),
  ],
);

class _TestShell extends StatelessWidget {
  const _TestShell();
  @override
  Widget build(BuildContext context) => const MiniPlayer();
}


void main() {
  late MockReimixAudioHandler mockHandler;

  setUpAll(() {
    registerFallbackValue(song1);
    registerFallbackValue(<Song>[]);
  });

  setUp(() {
    mockHandler = MockReimixAudioHandler();
    when(() => mockHandler.mediaItem).thenAnswer((_) => BehaviorSubject<MediaItem?>.seeded(null));
  });

  group('MiniPlayer – when no song is playing', () {
    testWidgets('renders nothing (SizedBox.shrink)', (tester) async {
      final playbackSubject = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
      when(() => mockHandler.positionStream).thenAnswer((_) => const Stream.empty());
      when(() => mockHandler.playingStream).thenAnswer((_) => const Stream.empty());
      when(() => mockHandler.playbackState).thenAnswer((_) => playbackSubject);

      final container = ProviderContainer(
        overrides: [audioHandlerProvider.overrideWithValue(mockHandler)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router),
        ),
      );
      await tester.pump();

      // MiniPlayer widget is in the tree but renders SizedBox.shrink()
      expect(find.byType(MiniPlayer), findsOneWidget);
      // No song title text should appear
      expect(find.text(song1.title), findsNothing);
    });
  });

  group('MiniPlayer – when a song is playing', () {
    late ProviderContainer container;

    setUp(() {
      final playbackSubject = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
      when(() => mockHandler.positionStream).thenAnswer((_) => const Stream.empty());
      when(() => mockHandler.playingStream).thenAnswer((_) => const Stream.empty());
      when(() => mockHandler.playbackState).thenAnswer((_) => playbackSubject);
      when(
        () => mockHandler.playFromSong(
          any(),
          queue: any(named: 'queue'),
          queueIndex: any(named: 'queueIndex'),
        ),
      ).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [audioHandlerProvider.overrideWithValue(mockHandler)],
      );
    });

    tearDown(() => container.dispose());

    testWidgets('shows song title after play()', (tester) async {
      await container.read(playerProvider.notifier).play(song1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(song1.title), findsOneWidget);
    });

    testWidgets('shows artist name after play()', (tester) async {
      await container.read(playerProvider.notifier).play(song1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(song1.artist!), findsOneWidget);
    });
  });
}
