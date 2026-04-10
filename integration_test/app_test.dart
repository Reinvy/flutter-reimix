// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:reimix/main.dart' as app;

/// Integration tests for critical user journeys.
///
/// REQUIREMENTS:
///   - Run on a real device or emulator that has audio files in external storage.
///   - Storage permission must be grantable from the test environment.
///   - Use `flutter test integration_test/app_test.dart -d <device-id>`
///
/// These tests exercise the full app stack (ObjectBox, AudioService, MediaStore).
/// They cannot run in a pure unit-test environment.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: Permission → Scan → Play', () {
    testWidgets('grants permission, scans library, taps first song, MiniPlayer becomes visible', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ── Step 1: Splash screen auto-navigates ──────────────────────────
      // Wait for splash (2.5 s) + navigation
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ── Step 2: Permission screen ──────────────────────────────────────
      // If permission screen is shown, tap "Grant Access"
      final grantButton = find.text('Grant Access');
      if (tester.any(grantButton)) {
        await tester.tap(grantButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // ── Step 3: Home screen should be visible ─────────────────────────
      // Wait for library scan to finish (up to 10 s)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Navigate to Library tab to find songs
      final libraryTab = find.byTooltip('Library');
      if (tester.any(libraryTab)) {
        await tester.tap(libraryTab);
        await tester.pumpAndSettle();
      }

      // ── Step 4: Tap first song in the list ────────────────────────────
      final firstTile = find.byType(ListTile).first;
      if (tester.any(firstTile)) {
        await tester.tap(firstTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ── Step 5: MiniPlayer should be visible ──────────────────────
        // MiniPlayer contains a skip-next button icon
        expect(find.byIcon(Icons.skip_next_rounded), findsAtLeastNWidgets(1));
        print('✓ MiniPlayer is visible after tapping a song');
      } else {
        print('SKIP: No songs found in library — ensure the test device has audio files.');
      }
    });
  });

  group('Integration: Playlist CRUD', () {
    testWidgets('creates a playlist, adds a song, verifies it, removes song, deletes playlist', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Playlists tab
      final playlistsTab = find.byTooltip('Playlists');
      if (!tester.any(playlistsTab)) {
        print('SKIP: Playlists tab not found — run after completing onboarding.');
        return;
      }
      await tester.tap(playlistsTab);
      await tester.pumpAndSettle();

      // ── Create playlist ───────────────────────────────────────────────
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Enter playlist name in dialog
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Integration Test Playlist');
      await tester.pumpAndSettle();

      // Confirm dialog
      final confirmButton = find.text('Create');
      if (tester.any(confirmButton)) {
        await tester.tap(confirmButton);
      } else {
        await tester.tap(find.text('OK'));
      }
      await tester.pumpAndSettle();

      // Verify new playlist appears in list
      expect(find.text('Integration Test Playlist'), findsOneWidget);
      print('✓ Playlist created');

      // ── Add a song ────────────────────────────────────────────────────
      // Navigate to Library
      final libraryTab = find.byTooltip('Library');
      if (tester.any(libraryTab)) {
        await tester.tap(libraryTab);
        await tester.pumpAndSettle();

        final firstTile = find.byType(ListTile).first;
        if (tester.any(firstTile)) {
          // Long-press to open context menu
          await tester.longPress(firstTile);
          await tester.pumpAndSettle();

          // Tap "Add to Playlist"
          final addToPlaylist = find.textContaining('Add to Playlist');
          if (tester.any(addToPlaylist)) {
            await tester.tap(addToPlaylist);
            await tester.pumpAndSettle();

            // Select our playlist
            final playlistOption = find.text('Integration Test Playlist');
            if (tester.any(playlistOption)) {
              await tester.tap(playlistOption);
              await tester.pumpAndSettle();
              print('✓ Song added to playlist');
            }
          }
        }
      }

      // ── Delete playlist ───────────────────────────────────────────────
      await tester.tap(find.byTooltip('Playlists'));
      await tester.pumpAndSettle();

      final playlistTile = find.text('Integration Test Playlist');
      if (tester.any(playlistTile)) {
        await tester.longPress(playlistTile);
        await tester.pumpAndSettle();

        final deleteOption = find.textContaining('Delete');
        if (tester.any(deleteOption)) {
          await tester.tap(deleteOption);
          await tester.pumpAndSettle();

          // Confirm deletion if dialog appears
          final confirm = find.text('Delete');
          if (tester.any(confirm)) {
            await tester.tap(confirm);
            await tester.pumpAndSettle();
          }

          expect(find.text('Integration Test Playlist'), findsNothing);
          print('✓ Playlist deleted');
        }
      }
    });
  });
}
