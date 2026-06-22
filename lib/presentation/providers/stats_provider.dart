import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/play_history.dart';
import '../../domain/usecases/get_listening_stats.dart';
import 'library_provider.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final playHistoryStreamProvider = StreamProvider<List<PlayHistory>>((ref) {
  return ref.watch(statsRepositoryProvider).watchPlayHistory();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class StatsNotifier extends AsyncNotifier<ListeningStats> {
  @override
  Future<ListeningStats> build() async {
    // Watch library so stats refresh when songs change
    final songs = await ref.watch(libraryProvider.future);
    // Watch play history so stats refresh on new play events
    final history = await ref.watch(playHistoryStreamProvider.future);
    return const GetListeningStats()(songs, history);
  }

  /// Force a refresh (e.g. called after a song finishes playing).
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, ListeningStats>(StatsNotifier.new);
