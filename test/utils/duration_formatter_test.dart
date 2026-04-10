import 'package:flutter_test/flutter_test.dart';

import 'package:reimix/core/utils/duration_formatter.dart';

void main() {
  group('formatDuration', () {
    test('zero duration returns "0:00"', () {
      expect(formatDuration(Duration.zero), '0:00');
    });

    test('less than a minute', () {
      expect(formatDuration(const Duration(seconds: 45)), '0:45');
    });

    test('exactly one minute', () {
      expect(formatDuration(const Duration(minutes: 1)), '1:00');
    });

    test('90 seconds returns "1:30"', () {
      expect(formatDuration(const Duration(seconds: 90)), '1:30');
    });

    test('59 minutes 59 seconds', () {
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('exactly one hour returns "1:00:00"', () {
      expect(formatDuration(const Duration(hours: 1)), '1:00:00');
    });

    test('1h 5m 7s returns "1:05:07"', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 5, seconds: 7)), '1:05:07');
    });

    test('2h 0m 0s returns "2:00:00"', () {
      expect(formatDuration(const Duration(hours: 2)), '2:00:00');
    });

    test('hours do not get zero-padded', () {
      expect(formatDuration(const Duration(hours: 12, minutes: 3, seconds: 4)), '12:03:04');
    });
  });
}
