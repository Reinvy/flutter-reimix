import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:reimix/domain/usecases/scan_local_songs.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockSongRepository mockRepo;
  late ScanLocalSongs usecase;

  setUp(() {
    mockRepo = MockSongRepository();
    usecase = ScanLocalSongs(mockRepo);
  });

  group('ScanLocalSongs', () {
    test('returns list of songs from repository', () async {
      final expected = [song1, song2, song3];
      when(() => mockRepo.scanAndSave()).thenAnswer((_) async => expected);

      final result = await usecase();

      expect(result, equals(expected));
      verify(() => mockRepo.scanAndSave()).called(1);
    });

    test('returns empty list when no songs found', () async {
      when(() => mockRepo.scanAndSave()).thenAnswer((_) async => []);

      final result = await usecase();

      expect(result, isEmpty);
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.scanAndSave()).thenThrow(Exception('Scan failed'));

      expect(() => usecase(), throwsException);
    });
  });
}
