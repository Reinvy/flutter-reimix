import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

import 'package:reimix/data/datasources/audio/audio_handler.dart';
import 'package:reimix/data/datasources/local/objectbox_datasource.dart';
import 'package:reimix/data/models/playlist_model.dart';
import 'package:reimix/data/models/song_model.dart';
import 'package:reimix/data/models/stats_model.dart';
import 'package:reimix/domain/repositories/playlist_repository.dart';
import 'package:reimix/domain/repositories/song_repository.dart';
import 'package:reimix/domain/repositories/stats_repository.dart';

// ── Repository mocks ──────────────────────────────────────────────────────────

class MockSongRepository extends Mock implements SongRepository {}

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

class MockStatsRepository extends Mock implements StatsRepository {}

// ── Datasource / ObjectBox mocks ──────────────────────────────────────────────

class MockObjectBoxDatasource extends Mock implements ObjectBoxDatasource {}

class MockSongBox extends Mock implements Box<SongModel> {}

class MockPlaylistBox extends Mock implements Box<PlaylistModel> {}

class MockAppSettingsBox extends Mock implements Box<AppSettings> {}

// ── Audio handler mock ────────────────────────────────────────────────────────

/// Mocktail mock for [ReimixAudioHandler].
///
/// Stub streams before constructing [PlayerNotifier]:
/// ```dart
/// when(() => mock.positionStream).thenAnswer((_) => const Stream.empty());
/// when(() => mock.playingStream).thenAnswer((_) => const Stream.empty());
/// when(() => mock.playbackState).thenReturn(BehaviorSubject.seeded(const PlaybackState()));
/// ```
class MockReimixAudioHandler extends Mock implements ReimixAudioHandler {}
