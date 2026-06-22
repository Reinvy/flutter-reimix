import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reimix/domain/entities/song.dart';
import 'package:reimix/presentation/providers/online_provider.dart';

import '../helpers/test_fixtures.dart';

class MockWidgetRef extends Mock implements WidgetRef {}

void main() {
  late MockWidgetRef mockRef;

  setUp(() {
    mockRef = MockWidgetRef();
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadQueueNotifier Concurrency & Queue Tests', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(downloadQueueProvider);
      expect(state, isEmpty);
    });

    test('first 3 downloads start immediately with 0.0 progress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(downloadQueueProvider.notifier);

      final s1 = fakeSong(id: 101, filePath: 'youtube://vid1');
      final s2 = fakeSong(id: 102, filePath: 'youtube://vid2');
      final s3 = fakeSong(id: 103, filePath: 'youtube://vid3');

      notifier.download(s1, mockRef);
      notifier.download(s2, mockRef);
      notifier.download(s3, mockRef);

      final state = container.read(downloadQueueProvider);
      expect(state['vid1'], equals(0.0));
      expect(state['vid2'], equals(0.0));
      expect(state['vid3'], equals(0.0));
    });

    test('4th and subsequent downloads are queued with -1.0 progress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(downloadQueueProvider.notifier);

      final s1 = fakeSong(id: 101, filePath: 'youtube://vid1');
      final s2 = fakeSong(id: 102, filePath: 'youtube://vid2');
      final s3 = fakeSong(id: 103, filePath: 'youtube://vid3');
      final s4 = fakeSong(id: 104, filePath: 'youtube://vid4');
      final s5 = fakeSong(id: 105, filePath: 'youtube://vid5');

      notifier.download(s1, mockRef);
      notifier.download(s2, mockRef);
      notifier.download(s3, mockRef);
      notifier.download(s4, mockRef);
      notifier.download(s5, mockRef);

      final state = container.read(downloadQueueProvider);
      expect(state['vid1'], equals(0.0));
      expect(state['vid2'], equals(0.0));
      expect(state['vid3'], equals(0.0));
      expect(state['vid4'], equals(-1.0)); // Queued
      expect(state['vid5'], equals(-1.0)); // Queued

      expect(notifier.isQueued('vid4'), isTrue);
      expect(notifier.isQueued('vid1'), isFalse);
    });
  });
}
