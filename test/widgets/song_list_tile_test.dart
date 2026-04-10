import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reimix/presentation/widgets/song_list_tile.dart';

import '../helpers/test_fixtures.dart';

/// Wraps [child] in the minimum widget tree required for [SongListTile].
Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SongListTile – rendering', () {
    testWidgets('displays song title', (tester) async {
      await tester.pumpWidget(_wrap(SongListTile(song: song1)));

      expect(find.text(song1.title), findsOneWidget);
    });

    testWidgets('displays artist name', (tester) async {
      await tester.pumpWidget(_wrap(SongListTile(song: song1)));

      expect(find.text(song1.artist!), findsOneWidget);
    });

    testWidgets('shows "Unknown Artist" when artist is null', (tester) async {
      await tester.pumpWidget(_wrap(SongListTile(song: songNoArtist)));

      expect(find.text('Unknown Artist'), findsOneWidget);
    });

    testWidgets('does not throw for song with minimal data', (tester) async {
      final minimal = fakeSong(
        id: 99,
        title: 'Minimal',
        artist: null,
        album: null,
        albumArtPath: null,
      );

      await tester.pumpWidget(_wrap(SongListTile(song: minimal)));
      expect(find.byType(SongListTile), findsOneWidget);
    });
  });

  group('SongListTile – interactions', () {
    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(SongListTile(song: song1, onTap: () => tapped = true)));

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders without crash when isPlaying is true', (tester) async {
      await tester.pumpWidget(_wrap(SongListTile(song: song1, isPlaying: true)));
      expect(find.byType(SongListTile), findsOneWidget);
    });
  });
}
