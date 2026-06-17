import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:reimix/data/models/playlist_model.dart';
import 'package:reimix/data/repositories_impl/playlist_repository_impl.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

/// Creates a [PlaylistModel] that mirrors [fakePlaylist] data so tests are
/// consistent with the fixture definitions.
PlaylistModel _playlistModel({
  int id = 1,
  String name = 'My Playlist',
  bool isSmartPlaylist = false,
}) {
  final m = PlaylistModel()
    ..id = id
    ..name = name
    ..isSmartPlaylist = isSmartPlaylist
    ..createdAt = DateTime(2024, 1, 1);
  return m;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_playlistModel());
  });

  late MockObjectBoxDatasource mockDb;
  late MockPlaylistBox mockPlaylistBox;
  late MockSongBox mockSongBox;
  late PlaylistRepositoryImpl repo;

  setUp(() {
    mockDb = MockObjectBoxDatasource();
    mockPlaylistBox = MockPlaylistBox();
    mockSongBox = MockSongBox();

    when(() => mockDb.playlistBox).thenReturn(mockPlaylistBox);
    when(() => mockDb.songBox).thenReturn(mockSongBox);

    repo = PlaylistRepositoryImpl(mockDb);
  });

  group('PlaylistRepositoryImpl.getAll', () {
    test('returns empty list when store is empty', () async {
      when(() => mockPlaylistBox.getAll()).thenReturn([]);

      final result = await repo.getAll();

      expect(result, isEmpty);
      verify(() => mockPlaylistBox.getAll()).called(1);
    });

    test('maps PlaylistModel to Playlist entity', () async {
      final model = _playlistModel(id: 42, name: 'Rock jams');
      when(() => mockPlaylistBox.getAll()).thenReturn([model]);

      final result = await repo.getAll();

      expect(result.length, 1);
      expect(result.first.id, 42);
      expect(result.first.name, 'Rock jams');
      expect(result.first.songs, isEmpty);
    });
  });

  group('PlaylistRepositoryImpl.create', () {
    test('stores a new PlaylistModel and returns entity', () async {
      when(() => mockPlaylistBox.put(any())).thenAnswer((_) => 99);

      final result = await repo.create('New Playlist');

      expect(result.name, 'New Playlist');
      expect(result.isSmartPlaylist, isFalse);
      verify(() => mockPlaylistBox.put(any())).called(1);
    });
  });

  group('PlaylistRepositoryImpl.delete', () {
    test('calls box.remove with the correct id', () async {
      when(() => mockPlaylistBox.remove(42)).thenReturn(true);

      await repo.delete(42);

      verify(() => mockPlaylistBox.remove(42)).called(1);
    });

    test('does not throw when playlist does not exist', () async {
      when(() => mockPlaylistBox.remove(any())).thenReturn(false);

      await expectLater(repo.delete(999), completes);
    });
  });

  group('PlaylistRepositoryImpl.addSong', () {
    test('does nothing when playlist not found', () async {
      when(() => mockPlaylistBox.get(1)).thenReturn(null);

      await repo.addSong(1, song1);

      verifyNever(() => mockPlaylistBox.put(any()));
    });

    test('does nothing when song model not found', () async {
      final model = _playlistModel(id: 1);
      when(() => mockPlaylistBox.get(1)).thenReturn(model);
      when(() => mockSongBox.get(song1.id)).thenReturn(null);

      await repo.addSong(1, song1);

      verifyNever(() => mockPlaylistBox.put(any()));
    });
  });

  group('PlaylistRepositoryImpl.reorder', () {
    test('updates songOrder and puts playlist', () async {
      final model = _playlistModel(id: 1);
      when(() => mockPlaylistBox.get(1)).thenReturn(model);
      when(() => mockPlaylistBox.put(any())).thenReturn(1);

      await repo.reorder(1, [3, 1, 2]);

      expect(model.songOrder, [3, 1, 2]);
      verify(() => mockPlaylistBox.put(model)).called(1);
    });

    test('does nothing when playlist not found', () async {
      when(() => mockPlaylistBox.get(any())).thenReturn(null);

      await repo.reorder(99, [1, 2]);

      verifyNever(() => mockPlaylistBox.put(any()));
    });
  });
}
