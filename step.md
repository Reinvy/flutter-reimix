# 🚀 Reimix — Implementation Steps (6 Phases to Production)

---

## Step 1 — Foundation & Design System

**Target: Week 1–2**

### 1.1 Project Setup

- [ ] Replace `main.dart` with ProviderScope + app entry point
- [ ] Create `lib/app.dart` — MaterialApp with go_router and Riverpod
- [ ] Add all dependencies to `pubspec.yaml` (just_audio, audio_service, flutter_riverpod, objectbox, on_audio_query, go_router, google_fonts, lucide_icons, permission_handler, shimmer, palette_generator, lottie, wakelock_plus, share_plus, flutter_local_notifications, image_picker, cached_network_image, flutter_svg, animated_background)
- [ ] Run `flutter pub get` and verify build passes

### 1.2 Core Constants

- [ ] `lib/core/constants/app_colors.dart` — light/dark color tokens
- [ ] `lib/core/constants/app_text_styles.dart` — Nunito typography scale
- [ ] `lib/core/constants/app_dimensions.dart` — spacing, radius, sizes
- [ ] `lib/core/constants/app_strings.dart` — all English UI strings

### 1.3 Theme

- [ ] `lib/core/theme/app_theme.dart` — ThemeData light + dark using tokens
- [ ] `lib/core/theme/mood_theme.dart` — 5 mood color overrides (Calm, Sad, Energetic, Night, Focus)

### 1.4 Database

- [ ] `lib/data/models/song_model.dart` — ObjectBox `@Entity` with all fields
- [ ] `lib/data/models/playlist_model.dart` — ObjectBox `@Entity`
- [ ] `lib/data/models/stats_model.dart` — ObjectBox `@Entity`
- [ ] Run `flutter pub run build_runner build` to generate ObjectBox store
- [ ] `lib/data/datasources/local/objectbox_datasource.dart` — store init + box accessors

### 1.5 Router

- [ ] `lib/core/router/app_router.dart` — all routes: `/splash`, `/onboarding/permission`, `/home`, `/library`, `/playlists`, `/search`, `/now-playing`, `/focus-mode`, `/stats`, `/settings`

### 1.6 Splash Screen

- [ ] `lib/presentation/screens/splash/splash_screen.dart` — 2.5s timer, Lottie sakura, logo fade-in
- [ ] First-launch detection via SharedPreferences → navigate to permission or home

---

## Step 2 — Library Scanning & Audio Engine

**Target: Week 3**

### 2.1 Domain Layer

- [ ] `lib/domain/entities/song.dart`, `album.dart`, `artist.dart`, `playlist.dart`, `listening_stat.dart`
- [ ] `lib/domain/repositories/song_repository.dart` — abstract interface
- [ ] `lib/domain/repositories/playlist_repository.dart` — abstract interface
- [ ] `lib/domain/repositories/stats_repository.dart` — abstract interface
- [ ] `lib/domain/usecases/scan_local_songs.dart`
- [ ] `lib/domain/usecases/get_songs_by_artist.dart`, `get_songs_by_album.dart`
- [ ] `lib/domain/usecases/toggle_favorite.dart`

### 2.2 Permission & Onboarding

- [ ] `lib/presentation/screens/onboarding/permission_screen.dart` — cherry blossom illustration, "Grant Access" CTA
- [ ] Handle READ_MEDIA_AUDIO (API ≥ 33) / READ_EXTERNAL_STORAGE (API < 33)
- [ ] Denied state: rationale dialog with "Open Settings"
- [ ] On grant: trigger scan → navigate to `/home`
- [ ] `android/app/src/main/AndroidManifest.xml` — add all required permissions

### 2.3 MediaStore Datasource

- [ ] `lib/data/datasources/local/media_store_datasource.dart` — on_audio_query wrapper, paginated (200/page)
- [ ] Supported formats: MP3, FLAC, AAC, M4A, OGG, WAV
- [ ] Extract: title, artist, album, duration, art, track number, year, genre

### 2.4 Repository Implementations

- [ ] `lib/data/repositories_impl/song_repository_impl.dart`
- [ ] `lib/data/repositories_impl/playlist_repository_impl.dart`
- [ ] `lib/data/repositories_impl/stats_repository_impl.dart`

### 2.5 Audio Engine

- [ ] `lib/data/datasources/audio/audio_handler.dart` — AudioHandler subclass (audio_service + just_audio)
- [ ] Background playback, lock screen controls, media session
- [ ] Queue management: play, pause, next, previous, seek, shuffle, repeat modes
- [ ] Audio focus handling (pause on call, resume on regain)

### 2.6 Providers

- [ ] `lib/presentation/providers/library_provider.dart` — scan + song list state
- [ ] `lib/presentation/providers/player_provider.dart` — PlayerState with current song, queue, position, shuffle, repeat, volume
- [ ] `lib/presentation/providers/mood_provider.dart` — current mood (StateProvider)
- [ ] `lib/presentation/providers/theme_provider.dart` — light/dark toggle

---

## Step 3 — Core Screens (Library, Now Playing, Mini Player)

**Target: Week 4–5**

### 3.1 Shared Widgets

- [ ] `lib/presentation/widgets/song_list_tile.dart` — album art (12dp radius), title, artist, duration, long-press context menu
- [ ] `lib/presentation/widgets/album_card.dart` — 120×120dp, 20dp radius, shimmer loading
- [ ] `lib/presentation/widgets/glassmorphic_card.dart` — backdrop blur + pink frosted overlay
- [ ] `lib/presentation/widgets/sakura_overlay.dart` — CustomPainter 8–12 petal particles (RepaintBoundary)

### 3.2 Home Screen

- [ ] `lib/presentation/screens/home/home_screen.dart`
- [ ] Time-based greeting, settings icon
- [ ] Mood selector chips (horizontal scroll, animated color tween 600ms)
- [ ] Recently Played horizontal scroll (last 20, sorted by lastPlayedAt)
- [ ] Favorites horizontal scroll (max 10 isFavorite songs)
- [ ] Playlists horizontal scroll with "New Playlist" shortcut card

### 3.3 Library Screen

- [ ] `lib/presentation/screens/library/library_screen.dart` — TabBar (Songs / Albums / Artists / Folders)
- [ ] `songs_tab.dart` — ListView.builder, sort bottom sheet, pull-to-refresh
- [ ] `albums_tab.dart` — 2-column GridView, tap → album detail
- [ ] `artists_tab.dart` — ListView with artist name + song count
- [ ] `folders_tab.dart` — filesystem tree of audio folders

### 3.4 Now Playing Screen

- [ ] `lib/presentation/screens/now_playing/now_playing_screen.dart`
- [ ] Blurred album art background (sigmaX/Y: 40) + dominant color gradient via palette_generator
- [ ] Album art: slow rotation while playing, cross-fade + scale on song change (400ms)
- [ ] Seekbar, duration labels, volume slider
- [ ] Controls: previous (seek-if-3s logic), play/pause (scale bounce 150ms), next, shuffle, repeat cycle
- [ ] Favorite button (animated heart fill + particle burst)
- [ ] Gestures: swipe left/right (next/prev), swipe up (queue sheet), tap art (lyrics/visualizer tab)
- [ ] Queue bottom sheet — ReorderableListView, swipe-to-dismiss
- [ ] Lyrics tab — LRC parsing + synchronized line highlight
- [ ] Visualizer tab — 30–40 bar CustomPainter on amplitude stream

### 3.5 Mini Player

- [ ] `lib/presentation/widgets/mini_player.dart` — 68dp height, glassmorphic, above BottomNavBar
- [ ] AlbumArt (44dp) | Title / Artist | Play/Pause | Next
- [ ] Tap → `/now-playing`, swipe-to-dismiss → stop playback
- [ ] Hidden on Now Playing screen

---

## Step 4 — Playlists, Search & Advanced Features

**Target: Week 6**

### 4.1 Playlist Feature

- [ ] `lib/domain/usecases/create_playlist.dart`, `add_song_to_playlist.dart`
- [ ] `lib/presentation/providers/playlist_provider.dart` — CRUD state
- [ ] `lib/presentation/screens/playlist/playlists_screen.dart` — smart playlists pinned top, FAB "+"
- [ ] `lib/presentation/screens/playlist/playlist_detail_screen.dart` — header collage, Play All, Shuffle, ReorderableListView, long-press remove
- [ ] Create playlist dialog — name field (max 60 chars), optional image_picker cover
- [ ] Smart playlists: Recently Played (last 50), Most Played (playCount > 5), Favorites

### 4.2 Search

- [ ] `lib/presentation/providers/search_provider.dart` — debounced 300ms query
- [ ] `lib/presentation/screens/search/search_screen.dart` — auto-focus bar, grouped results (Songs 20 / Albums 10 / Artists 10 / Playlists 5)
- [ ] Recent searches chips (empty state)
- [ ] No-results illustration + friendly copy

### 4.3 Focus Mode & Sleep Timer

- [ ] `lib/presentation/screens/focus_mode/focus_mode_screen.dart` — minimal dark overlay, HH:MM clock, blurred art 160dp, countdown ring
- [ ] Sleep Timer options: 15/30/45/60 min, End of song, Custom
- [ ] 10-second fade-out on expiry → stop → dismiss
- [ ] wakelock_plus: screen stays on, status bar hidden
- [ ] flutter_local_notifications: "Sleep timer ended" notification

### 4.4 Mood Animations

- [ ] Calm — Sakura overlay (SakuraOverlay widget, SVG petals)
- [ ] Sad — slow rain particle CustomPainter
- [ ] Energetic — fast pulse ripple animation
- [ ] Night — star twinkle CustomPainter
- [ ] Focus — minimal breath pulse animation
- [ ] AnimatedTheme wrapping MaterialApp for 600ms color tween on mood switch
- [ ] Persist selected mood in ObjectBox AppSettings

### 4.5 Listening Stats

- [ ] `lib/domain/usecases/get_listening_stats.dart`
- [ ] `lib/presentation/providers/stats_provider.dart`
- [ ] `lib/presentation/screens/stats/stats_screen.dart` — bar chart (7 days), top songs, top artists, total time, streak
- [ ] Increment playCount + totalListenedMs when song plays past 80%

---

## Step 5 — Polish, Error Handling & Performance

**Target: Week 7**

### 5.1 Error Handling

- [ ] `lib/core/errors/app_exceptions.dart` — typed exceptions
- [ ] No audio files found → empty state illustration + copy
- [ ] Corrupt file → skip during scan, log in Settings > About
- [ ] Storage permission denied → persistent banner with "Tap to grant"
- [ ] File moved/deleted → snackbar "File not found", skip to next, mark missing in DB
- [ ] ObjectBox corruption → clear + re-scan, show "Library rebuilt" toast

### 5.2 Performance Optimizations

- [ ] RepaintBoundary on MiniPlayer, SakuraOverlay, AudioVisualizer
- [ ] ListView.builder on all song lists (no itemExtent-based layouts)
- [ ] Album art: cached_network_image to local filesystem, < 300ms uncached
- [ ] ObjectBox queries on background isolate
- [ ] on_audio_query paginated (page size: 200)

### 5.3 Animation Polish

- [ ] Screen transitions: slide + fade 300ms Curves.easeInOutCubic
- [ ] Play/Pause: scale pulse 150ms Curves.elasticOut
- [ ] Album art swap: cross-fade + scale 400ms Curves.easeInOutQuart
- [ ] Like button: heart bounce 300ms Curves.bounceOut
- [ ] Bottom sheet open: slide up 350ms Curves.easeOutCubic
- [ ] Mood switch: animated color tween 600ms Curves.easeInOut

### 5.4 Micro-interactions

- [ ] Add to playlist → checkmark animation on tile
- [ ] Library scan complete → petal burst toast
- [ ] Long press album art → haptic feedback (medium impact)
- [ ] Tap sakura petal → petal spins and fades
- [ ] Empty library on first open → animated illustration + copy

### 5.5 iOS & Android Platform Config

- [ ] `ios/Runner/Info.plist` — NSAppleMusicUsageDescription, UIBackgroundModes audio
- [ ] `android/app/build.gradle.kts` — minSdk 21, targetSdk 34
- [ ] Verify foreground service + media session on both platforms
- [ ] Test lock screen controls on physical devices

### 5.6 Settings Screen

- [ ] `lib/presentation/screens/settings/settings_screen.dart`
- [ ] Theme toggle (light/dark), default mood, audio focus behavior toggle
- [ ] About section: app version (package_info_plus), error log viewer

---

## Step 6 — Testing, Store Assets & Production Release

**Target: Week 8**

### 6.1 Unit Tests

- [ ] `test/usecases/scan_local_songs_test.dart` — metadata parse, empty list
- [ ] `test/repositories/playlist_repository_test.dart` — CRUD, song ordering
- [ ] `test/providers/player_provider_test.dart` — play/pause, queue, shuffle
- [ ] `test/utils/duration_formatter_test.dart` — 0s, >1h edge cases
- [ ] `test/providers/mood_provider_test.dart` — mood → correct theme output

### 6.2 Widget Tests

- [ ] SongListTile — full/partial metadata render
- [ ] MiniPlayer — correct info display, play/pause toggle
- [ ] MoodSelector — chip selection updates state
- [ ] NowPlayingScreen — seekbar interaction

### 6.3 Integration Tests

- [ ] Permission → Scan → Play song → Verify MiniPlayer visible
- [ ] Create playlist → Add songs → Reorder → Delete

### 6.4 Manual QA Checklist

- [ ] Audio plays in background when app is minimized
- [ ] Lock screen media controls work (Android + iOS)
- [ ] Sleep timer fires and fades audio correctly
- [ ] Dark mode switches all screens correctly
- [ ] All 5 moods change theme colors correctly
- [ ] Sakura overlay renders without frame drops (low-end device)
- [ ] No crash on corrupt audio file
- [ ] Swipe gestures on Now Playing work consistently
- [ ] Cold start to Home < 2s
- [ ] Library scan 1,000 songs < 5s

### 6.5 Store Assets

- [ ] App icon (1024×1024 PNG) — cherry blossom mark
- [ ] Splash screen assets (Android 12 adaptive, iOS launch storyboard)
- [ ] Play Store: feature graphic (1024×500), screenshots (phone + tablet), short description, full description, keywords
- [ ] App Store: screenshots (6.7", 6.1", iPad), privacy policy URL, age rating

### 6.6 Build & Release

- [ ] `flutter build apk --release --split-per-abi` (Android)
- [ ] `flutter build appbundle --release` (Play Store)
- [ ] `flutter build ipa --release` (App Store)
- [ ] Sign Android with production keystore (store in secure vault, NOT in repo)
- [ ] Sign iOS with Distribution certificate + App Store provisioning profile
- [ ] Verify ProGuard / R8 rules do not strip ObjectBox or audio_service classes
- [ ] Upload to Google Play internal track → promote to production
- [ ] Upload to App Store Connect → submit for review

---

## Summary

| Step | Focus                           | Output                                             |
| ---- | ------------------------------- | -------------------------------------------------- |
| 1    | Foundation & Design System      | Running app skeleton, theme, DB, router, splash    |
| 2    | Library Scanning & Audio Engine | Songs scannable, audio plays in background         |
| 3    | Core Screens                    | Home, Library, Now Playing, Mini Player functional |
| 4    | Playlists, Search & Advanced    | All main features complete                         |
| 5    | Polish, Errors & Performance    | Production-quality UX, 60fps, error-resilient      |
| 6    | Testing, Store Assets & Release | Published on Play Store + App Store                |
