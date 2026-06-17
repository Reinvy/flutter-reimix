import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reimix/core/theme/mood_theme.dart';
import 'package:reimix/presentation/providers/mood_provider.dart';

void main() {
  ProviderContainer makeContainer(MoodType initial) {
    return ProviderContainer(
      overrides: [moodProvider.overrideWith((ref) => MoodNotifier.withInitialState(initial))],
    );
  }

  tearDown(() {});

  group('MoodProvider – initial state', () {
    for (final mood in MoodType.values) {
      test('withInitialState($mood) → state is $mood', () {
        final container = makeContainer(mood);
        addTearDown(container.dispose);

        expect(container.read(moodProvider), equals(mood));
      });
    }
  });

  group('MoodNotifier.setMood', () {
    test('setMood(sad) updates state to sad', () {
      final container = makeContainer(MoodType.calm);
      addTearDown(container.dispose);

      // Wrap in override that skips ObjectBox persistence
      final notifier = MoodNotifier.withInitialState(MoodType.calm);
      notifier.setMoodWithoutPersistence(MoodType.sad);

      expect(notifier.state, MoodType.sad);
    });

    test('all 5 moods can be set without error', () {
      for (final mood in MoodType.values) {
        final notifier = MoodNotifier.withInitialState(MoodType.calm);

        expect(() => notifier.setMoodWithoutPersistence(mood), returnsNormally);
        expect(notifier.state, mood);
      }
    });
  });
}
