import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_listening_stats.dart';
import 'library_provider.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class StatsNotifier extends AsyncNotifier<ListeningStats> {
  @override
  Future<ListeningStats> build() async {
    // Watch library so stats refresh when songs change
    final songs = await ref.watch(libraryProvider.future);
    return const GetListeningStats()(songs);
  }

  /// Force a refresh (e.g. called after a song finishes playing).
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, ListeningStats>(StatsNotifier.new);
