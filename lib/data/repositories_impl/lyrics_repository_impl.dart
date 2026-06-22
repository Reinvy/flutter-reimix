import 'dart:convert';
import 'dart:io';

import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';
import '../datasources/local/objectbox_datasource.dart';
import '../models/lyrics_model.dart';
import '../../objectbox.g.dart';

/// LRC timestamp format: [mm:ss.xx] or [mm:ss.xxx]
final _lrcLineRegex = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)$');

/// Parses a raw LRC string into a list of [LyricLine] objects.
List<LyricLine> parseLrc(String lrc) {
  final lines = <LyricLine>[];
  for (final raw in lrc.split('\n')) {
    final match = _lrcLineRegex.firstMatch(raw.trim());
    if (match == null) continue;
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final centis = match.group(3)!;
    final ms = int.parse(centis.padRight(3, '0').substring(0, 3));
    final text = match.group(4)!.trim();
    lines.add(LyricLine(
      timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
      text: text,
    ));
  }
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

/// Converts a [LyricsModel] to a [Lyrics] domain entity.
Lyrics _toEntity(LyricsModel m) {
  return Lyrics(
    songId: m.songId,
    plainText: m.plainText,
    syncedLines: m.syncedLrc != null ? parseLrc(m.syncedLrc!) : null,
    fetchedAt: m.fetchedAt,
  );
}

class LyricsRepositoryImpl implements LyricsRepository {
  final ObjectBoxDatasource _db;

  /// LRCLIB base URL. No API key required.
  static const _baseUrl = 'https://lrclib.net/api/get';

  LyricsRepositoryImpl(this._db);

  @override
  Future<Lyrics?> getCachedLyrics(int songId) async {
    final query = _db.lyricsBox.query(LyricsModel_.songId.equals(songId)).build();
    final existing = query.findFirst();
    query.close();
    if (existing == null) return null;
    return _toEntity(existing);
  }

  @override
  Future<Lyrics?> fetchLyrics({
    required int songId,
    required String title,
    required String artist,
    int? durationSeconds,
  }) async {
    try {
      final params = {
        'track_name': title,
        'artist_name': artist,
        if (durationSeconds != null) 'duration': '$durationSeconds',
      };
      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Reimix/1.0 (music player)');
      final response = await request.close();

      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final syncedLrc = json['syncedLyrics'] as String?;
      final plainText = json['plainLyrics'] as String?;

      if (syncedLrc == null && plainText == null) return null;

      final lyrics = Lyrics(
        songId: songId,
        plainText: plainText,
        syncedLines: syncedLrc != null ? parseLrc(syncedLrc) : null,
        fetchedAt: DateTime.now(),
      );

      // Cache it
      await cacheLyrics(lyrics);
      return lyrics;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheLyrics(Lyrics lyrics) async {
    // Upsert: remove old cached entry first
    final query = _db.lyricsBox.query(LyricsModel_.songId.equals(lyrics.songId)).build();
    final existing = query.findFirst();
    query.close();
    if (existing != null) {
      _db.lyricsBox.remove(existing.id);
    }

    final model = LyricsModel()
      ..songId = lyrics.songId
      ..plainText = lyrics.plainText
      ..syncedLrc = lyrics.syncedLines != null
          ? _lyricLinesToLrc(lyrics.syncedLines!)
          : null
      ..fetchedAt = lyrics.fetchedAt;
    _db.lyricsBox.put(model);
  }

  /// Converts parsed [LyricLine] objects back to raw LRC format for storage.
  String _lyricLinesToLrc(List<LyricLine> lines) {
    return lines.map((l) {
      final m = l.timestamp.inMinutes.toString().padLeft(2, '0');
      final s = (l.timestamp.inSeconds % 60).toString().padLeft(2, '0');
      final ms = (l.timestamp.inMilliseconds % 1000).toString().padLeft(3, '0');
      return '[$m:$s.$ms]${l.text}';
    }).join('\n');
  }
}
