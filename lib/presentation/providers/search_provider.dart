import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import 'library_provider.dart';
import 'playlist_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final List<String> recentSearches;

  const SearchState({this.query = '', this.recentSearches = const []});

  SearchState copyWith({String? query, List<String>? recentSearches}) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  Timer? _debounce;

  SearchNotifier() : super(const SearchState());

  void setQuery(String q) {
    _debounce?.cancel();
    state = state.copyWith(query: q);
    if (q.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Force providers watching this state to recompute
      state = state.copyWith(query: q);
    });
  }

  void selectRecent(String q) {
    state = state.copyWith(query: q);
  }

  void commitSearch(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.recentSearches.where((s) => s != trimmed)].take(10).toList();
    state = state.copyWith(query: trimmed, recentSearches: updated);
  }

  void removeRecent(String q) {
    state = state.copyWith(recentSearches: state.recentSearches.where((s) => s != q).toList());
  }

  void clearRecents() {
    state = state.copyWith(recentSearches: []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((_) => SearchNotifier());

// ── Result model ──────────────────────────────────────────────────────────────

class SearchResults {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  const SearchResults({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  bool get isEmpty => songs.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;
}

// ── Results provider ──────────────────────────────────────────────────────────

final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final q = ref.watch(searchProvider).query.trim().toLowerCase();
  if (q.isEmpty) return const SearchResults();

  final songsAsync = await ref.watch(libraryProvider.future);
  final playlistsAsync = await ref.watch(playlistProvider.future);

  final songs = songsAsync
      .where(
        (s) =>
            s.title.toLowerCase().contains(q) ||
            (s.artist?.toLowerCase().contains(q) ?? false) ||
            (s.album?.toLowerCase().contains(q) ?? false),
      )
      .take(20)
      .toList();

  // Derive albums & artists from all songs
  final albumMap = <String, Album>{};
  for (final s in songsAsync) {
    final albumName = s.album;
    if (albumName != null && albumName.toLowerCase().contains(q)) {
      albumMap.putIfAbsent(
        albumName,
        () => Album(name: albumName, artist: s.artist ?? '', artPath: s.albumArtPath, songCount: 0),
      );
    }
  }
  final albums = albumMap.values.take(10).toList();

  final artistMap = <String, Artist>{};
  for (final s in songsAsync) {
    final artistName = s.artist;
    if (artistName != null && artistName.toLowerCase().contains(q)) {
      final existing = artistMap[artistName];
      artistMap[artistName] = Artist(name: artistName, songCount: (existing?.songCount ?? 0) + 1);
    }
  }
  final artists = artistMap.values.take(10).toList();

  final playlists = playlistsAsync.where((p) => p.name.toLowerCase().contains(q)).take(5).toList();

  return SearchResults(songs: songs, albums: albums, artists: artists, playlists: playlists);
});
