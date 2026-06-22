import 'package:flutter_test/flutter_test.dart';
import 'package:reimix/core/utils/title_sanitizer.dart';

void main() {
  group('TitleSanitizer Tests', () {
    test('removes (Official Video) and formats correctly', () {
      final meta = TitleSanitizer.sanitize('Coldplay - Yellow (Official Video)');
      expect(meta.artist, equals('Coldplay'));
      expect(meta.title, equals('Yellow'));
    });

    test('removes [Official Music Video] and formats correctly', () {
      final meta = TitleSanitizer.sanitize('Linkin Park - Numb [Official Music Video]');
      expect(meta.artist, equals('Linkin Park'));
      expect(meta.title, equals('Numb'));
    });

    test('removes feat. tag and formats correctly', () {
      final meta = TitleSanitizer.sanitize('Alan Walker - Faded (feat. Iselin Solheim)');
      expect(meta.artist, equals('Alan Walker'));
      expect(meta.title, equals('Faded'));
    });

    test('removes ft. tag in bracket and formats correctly', () {
      final meta = TitleSanitizer.sanitize('Alan Walker - Faded [ft. Iselin Solheim]');
      expect(meta.artist, equals('Alan Walker'));
      expect(meta.title, equals('Faded'));
    });

    test('removes live tag and formats correctly', () {
      final meta = TitleSanitizer.sanitize('Radiohead - Karma Police (Live)');
      expect(meta.artist, equals('Radiohead'));
      expect(meta.title, equals('Karma Police'));
    });

    test('removes remaster tag and formats correctly', () {
      final meta = TitleSanitizer.sanitize('The Beatles - Yesterday (2009 Remaster)');
      expect(meta.artist, equals('The Beatles'));
      expect(meta.title, equals('Yesterday'));
    });

    test('handles title without separator using channelName', () {
      final meta = TitleSanitizer.sanitize('Yesterday', channelName: 'The Beatles Official');
      expect(meta.artist, equals('The Beatles'));
      expect(meta.title, equals('Yesterday'));
    });

    test('removes VEVO suffix from channelName', () {
      final meta = TitleSanitizer.sanitize('Cardigan', channelName: 'TaylorSwiftVEVO');
      expect(meta.artist, equals('TaylorSwift'));
      expect(meta.title, equals('Cardigan'));
    });

    test('handles completely clean input', () {
      final meta = TitleSanitizer.sanitize('Queen - Bohemian Rhapsody');
      expect(meta.artist, equals('Queen'));
      expect(meta.title, equals('Bohemian Rhapsody'));
    });
  });
}
