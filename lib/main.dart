import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/datasources/audio/audio_handler.dart';
import 'data/datasources/local/objectbox_datasource.dart';

late ObjectBoxDatasource objectBox;
late ReimixAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBoxDatasource.create();
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
