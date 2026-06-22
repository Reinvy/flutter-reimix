import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories_impl/lyrics_repository_impl.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/entities/song.dart';
import '../../main.dart' show objectBox;

// ── Repository Provider ───────────────────────────────────────────────────────

final lyricsRepositoryProvider = Provider<LyricsRepositoryImpl>((_) {
  return LyricsRepositoryImpl(objectBox);
});

// ── Lyrics Notifier ───────────────────────────────────────────────────────────

/// State for the lyrics loading process.
class LyricsState {
  final bool isLoading;
  final Lyrics? lyrics;
  final bool notFound;

  const LyricsState({
    this.isLoading = false,
    this.lyrics,
    this.notFound = false,
  });

  LyricsState copyWith({bool? isLoading, Lyrics? lyrics, bool? notFound}) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      lyrics: lyrics ?? this.lyrics,
      notFound: notFound ?? this.notFound,
    );
  }
}

class LyricsNotifier extends StateNotifier<LyricsState> {
  final LyricsRepositoryImpl _repo;

  LyricsNotifier(this._repo) : super(const LyricsState());

  /// Loads lyrics for [song], first from cache, then from LRCLIB if not found.
  Future<void> loadLyrics(Song song) async {
    if (state.isLoading) return;
    state = const LyricsState(isLoading: true);

    // Try cache first
    final cached = await _repo.getCachedLyrics(song.id);
    if (cached != null) {
      state = LyricsState(lyrics: cached);
      return;
    }

    // Fetch from LRCLIB
    final title = song.title;
    final artist = song.artist ?? '';
    final durationSec = song.durationMs > 0 ? song.durationMs ~/ 1000 : null;

    final fetched = await _repo.fetchLyrics(
      songId: song.id,
      title: title,
      artist: artist,
      durationSeconds: durationSec,
    );

    if (fetched != null) {
      state = LyricsState(lyrics: fetched);
    } else {
      state = const LyricsState(notFound: true);
    }
  }

  /// Clears the current lyrics state (e.g., when the song changes).
  void clear() => state = const LyricsState();
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  return LyricsNotifier(ref.read(lyricsRepositoryProvider));
});
