import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reimix/core/errors/app_exceptions.dart';
import 'package:reimix/presentation/providers/error_log_provider.dart';
import 'package:reimix/presentation/providers/player_provider.dart';

void main() {
  group('ErrorLogNotifier Unit Tests', () {
    test('initial state is empty list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final logs = container.read(errorLogProvider);
      expect(logs, isEmpty);
    });

    test('logError appends a log entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(errorLogProvider.notifier);
      
      notifier.logError('Test Error Message', details: 'Stack trace details');
      
      final logs = container.read(errorLogProvider);
      expect(logs, hasLength(1));
      expect(logs[0].message, equals('Test Error Message'));
      expect(logs[0].details, equals('Stack trace details'));
      expect(logs[0].timestamp, isNotNull);
    });

    test('clearLogs empties the log list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(errorLogProvider.notifier);
      
      notifier.logError('Error 1');
      notifier.logError('Error 2');
      
      expect(container.read(errorLogProvider), hasLength(2));
      
      notifier.clearLogs();
      
      expect(container.read(errorLogProvider), isEmpty);
    });
  });

  group('errorLogProvider Stream Integration Test', () {
    test('automatically logs exceptions from audioErrorStreamProvider', () async {
      final controller = StreamController<AudioException>();
      final container = ProviderContainer(
        overrides: [
          audioErrorStreamProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });

      // We must read/listen to errorLogProvider to initialize the listener.
      final logsList = <List<ErrorLogEntry>>[];
      final unsubscribe = container.listen<List<ErrorLogEntry>>(errorLogProvider, (prev, next) {
        logsList.add(next);
      });
      addTearDown(unsubscribe.close);

      // Verify initial state is empty
      expect(container.read(errorLogProvider), isEmpty);

      // Add an exception to the stream
      const exception = AudioException('Fail to load audio source', cause: 'File not found');
      controller.add(exception);

      // Wait a microtask / tick for stream event propagation and state notifier update.
      await Future<void>.delayed(Duration.zero);

      final currentLogs = container.read(errorLogProvider);
      expect(currentLogs, hasLength(1));
      expect(currentLogs[0].message, equals('Fail to load audio source'));
      expect(currentLogs[0].details, equals('File not found'));
    });
  });
}
