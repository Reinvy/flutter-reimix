import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'data/datasources/audio/audio_handler.dart';
import 'data/datasources/local/objectbox_datasource.dart';

late ObjectBoxDatasource objectBox;
late ReimixAudioHandler audioHandler;

/// Set to [true] if the ObjectBox store was deleted and recreated on startup.
/// The main shell checks this flag and shows a toast on first build.
bool libraryWasRebuilt = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open ObjectBox store; recover from corruption by deleting and re-creating.
  try {
    objectBox = await ObjectBoxDatasource.create();
  } catch (_) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final storeDir = Directory('${dir.path}/objectbox');
      if (await storeDir.exists()) await storeDir.delete(recursive: true);
      objectBox = await ObjectBoxDatasource.create();
      libraryWasRebuilt = true;
    } catch (e) {
      rethrow;
    }
  }

  audioHandler = await AudioService.init(
    builder: () => ReimixAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.reimix.channel.audio',
      androidNotificationChannelName: 'Reimix Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(const ProviderScope(child: ReimixApp()));
}
