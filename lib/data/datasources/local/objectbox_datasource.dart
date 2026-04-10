import '../../../objectbox.g.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../models/stats_model.dart';

/// Singleton wrapper around the ObjectBox Store.
/// Call [ObjectBoxDatasource.create()] once at app startup (in main.dart),
/// then inject the instance via Riverpod.
class ObjectBoxDatasource {
  final Store store;

  late final Box<SongModel> songBox;
  late final Box<PlaylistModel> playlistBox;
  late final Box<AppSettings> settingsBox;

  ObjectBoxDatasource._create(this.store) {
    songBox = store.box<SongModel>();
    playlistBox = store.box<PlaylistModel>();
    settingsBox = store.box<AppSettings>();
  }

  static Future<ObjectBoxDatasource> create() async {
    final store = await openStore();
    return ObjectBoxDatasource._create(store);
  }

  /// Returns the singleton AppSettings row, creating defaults if absent.
  AppSettings getSettings() {
    final existing = settingsBox.getAll().firstOrNull;
    if (existing != null) return existing;
    final defaults = AppSettings();
    settingsBox.put(defaults);
    return defaults;
  }

  void close() => store.close();
}
