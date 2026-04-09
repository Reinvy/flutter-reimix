import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/datasources/local/objectbox_datasource.dart';

late ObjectBoxDatasource objectBox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBoxDatasource.create();
  runApp(
    const ProviderScope(
      child: ReimixApp(),
    ),
  );
}