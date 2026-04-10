# 🌸 PRD – Reimix (Music Player App)

**App Name:** Reimix
**Platform:** Flutter (Android & iOS)
**App Language:** English
**Theme:** Cherry Blossom — soft pink, elegant, calming, subtly romantic
**Version:** 1.0.0
**Document Status:** Ready for Development
**Last Updated:** April 10, 2026

---

## 📋 Table of Contents

1. [Vision & Purpose](#1-vision--purpose)
2. [Target Users](#2-target-users)
3. [Design System](#3-design-system)
4. [App Architecture](#4-app-architecture)
5. [Navigation Structure](#5-navigation-structure)
6. [Core Features](#6-core-features)
7. [Advanced Features](#7-advanced-features)
8. [Data Models](#8-data-models)
9. [Permissions & Platform Requirements](#9-permissions--platform-requirements)
10. [User Flows](#10-user-flows)
11. [Error Handling](#11-error-handling)
12. [Performance Requirements](#12-performance-requirements)
13. [Testing Strategy](#13-testing-strategy)
14. [Monetization](#14-monetization)
15. [Success Metrics](#15-success-metrics)
16. [Release Roadmap](#16-release-roadmap)

---

## 💡 1. Vision & Purpose

Reimix is a modern local music player that delivers an emotional listening experience — calm, aesthetic, and deeply personal. It is not just a player; it is an ambient companion that adapts its look and feel to the user's current mood.

**Core Value Proposition:**

| Pillar          | Description                                             |
| --------------- | ------------------------------------------------------- |
| Aesthetic       | Cherry blossom-inspired UI that feels alive and warm    |
| Performance     | Smooth 60fps animations, fast library scanning          |
| Personalization | Mood-based themes, smart playlists, custom covers       |
| Emotional UX    | Micro-interactions, particle effects, sakura animations |

---

## 🎯 2. Target Users

**Primary Audience:** Ages 16–35 who value aesthetic digital experiences.

**User Personas:**

### Persona A – "The Focus Worker"

- Uses music to concentrate while studying or working
- Needs: Focus Mode, Sleep Timer, minimal distractions
- Device: Mid-to-high-end Android / iPhone

### Persona B – "The Chill Listener"

- Browses local music for mood-based listening
- Needs: Mood selector, beautiful Now Playing, smooth browsing
- Device: Any modern smartphone

### Persona C – "The Music Curator"

- Organizes playlists meticulously
- Needs: Playlist management, drag-reorder, metadata editing
- Device: Any modern smartphone

---

## 🌸 3. Design System

### 3.1 Color Palette

#### Light Mode

| Token               | Hex       | Usage                           |
| ------------------- | --------- | ------------------------------- |
| `colorPrimary`      | `#FADADD` | Primary backgrounds, cards      |
| `colorSecondary`    | `#F8C8DC` | Accent surfaces                 |
| `colorAccent`       | `#FF8DAA` | CTAs, active states, highlights |
| `colorBackground`   | `#FFF5F7` | App background                  |
| `colorSurface`      | `#FFFFFF` | Card / bottom sheet surface     |
| `colorOnPrimary`    | `#6B3A4A` | Text on primary                 |
| `colorOnBackground` | `#3D1F2A` | Primary text                    |
| `colorSubtext`      | `#A07080` | Secondary / helper text         |
| `colorDivider`      | `#F0D8DE` | Dividers, borders               |

#### Dark Mode

| Token               | Hex       | Usage                               |
| ------------------- | --------- | ----------------------------------- |
| `colorBackground`   | `#1E1A1D` | App background                      |
| `colorSurface`      | `#2A2328` | Card surface                        |
| `colorPrimary`      | `#3D2A30` | Primary surfaces                    |
| `colorAccent`       | `#FF8DAA` | CTAs (same accent, remains vibrant) |
| `colorOnBackground` | `#F5E6EA` | Primary text                        |
| `colorSubtext`      | `#C49EAA` | Secondary text                      |

### 3.2 Typography

| Style            | Font   | Weight         | Size | Usage                     |
| ---------------- | ------ | -------------- | ---- | ------------------------- |
| `headlineLarge`  | Nunito | Bold (700)     | 28sp | Screen titles             |
| `headlineMedium` | Nunito | SemiBold (600) | 22sp | Section headers           |
| `titleLarge`     | Nunito | SemiBold (600) | 18sp | Song title in Now Playing |
| `titleMedium`    | Nunito | Medium (500)   | 16sp | Song titles in list       |
| `bodyMedium`     | Nunito | Regular (400)  | 14sp | Body text, subtitles      |
| `labelSmall`     | Nunito | Regular (400)  | 12sp | Timestamps, metadata      |

Font package: google_fonts - Nunito

### 3.3 Spacing & Layout

- **Base unit:** 4dp
- **Common spacings:** 4, 8, 12, 16, 20, 24, 32, 48dp
- **Screen horizontal padding:** 20dp
- **Card padding:** 16dp
- **Bottom navigation bar height:** 64dp
- **Mini player height:** 68dp

### 3.4 Border Radius

| Component               | Radius               |
| ----------------------- | -------------------- |
| Cards                   | 20dp                 |
| Buttons (primary)       | 30dp (fully rounded) |
| Album art (Now Playing) | 24dp                 |
| Album art (list item)   | 12dp                 |
| Bottom Sheet            | 28dp (top corners)   |
| Chip / Tag              | 20dp                 |
| Mini Player             | 20dp                 |

### 3.5 Elevation & Glassmorphism

- **Glass card:** BackdropFilter with ImageFilter.blur(sigmaX: 10, sigmaY: 10) + Color.withOpacity(0.15) frosted white/pink overlay
- **Soft shadow:** BoxShadow(color: Color(0x1AFF8DAA), blurRadius: 20, offset: Offset(0, 8))
- **Now Playing blur background:** ImageFilter.blur(sigmaX: 40, sigmaY: 40) from album art dominant color

### 3.6 Animation Guidelines

| Event             | Animation             | Duration    | Curve                 |
| ----------------- | --------------------- | ----------- | --------------------- |
| Screen transition | Slide + fade          | 300ms       | Curves.easeInOutCubic |
| Play/Pause toggle | Scale pulse           | 150ms       | Curves.elasticOut     |
| Album art swap    | Cross-fade + scale    | 400ms       | Curves.easeInOutQuart |
| Like button tap   | Heart bounce          | 300ms       | Curves.bounceOut      |
| Bottom sheet open | Slide up              | 350ms       | Curves.easeOutCubic   |
| Sakura petal fall | Custom path animation | 3000-6000ms | Curves.easeInQuad     |
| Mood switch       | Animated color tween  | 600ms       | Curves.easeInOut      |

### 3.7 Icons

- Primary icon set: Lucide icons via lucide_icons package
- Fallback: Material Icons
- Icon sizes: 20dp (nav), 24dp (actions), 28dp (Now Playing controls)

---

## 🧩 4. App Architecture

### 4.1 Folder Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, theme, router setup
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_dimensions.dart
│   │   └── app_strings.dart          # All UI strings (English)
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData light and dark
│   │   └── mood_theme.dart           # Mood-based color overrides
│   ├── router/
│   │   └── app_router.dart           # go_router route definitions
│   ├── utils/
│   │   ├── duration_formatter.dart
│   │   ├── file_utils.dart
│   │   └── metadata_parser.dart
│   └── errors/
│       └── app_exceptions.dart
├── domain/
│   ├── entities/
│   │   ├── song.dart
│   │   ├── playlist.dart
│   │   ├── album.dart
│   │   ├── artist.dart
│   │   └── listening_stat.dart
│   ├── repositories/
│   │   ├── song_repository.dart       # abstract
│   │   ├── playlist_repository.dart   # abstract
│   │   └── stats_repository.dart      # abstract
│   └── usecases/
│       ├── scan_local_songs.dart
│       ├── get_songs_by_artist.dart
│       ├── get_songs_by_album.dart
│       ├── create_playlist.dart
│       ├── add_song_to_playlist.dart
│       ├── toggle_favorite.dart
│       └── get_listening_stats.dart
├── data/
│   ├── models/
│   │   ├── song_model.dart            # ObjectBox entity
│   │   ├── playlist_model.dart        # ObjectBox entity
│   │   └── stats_model.dart           # ObjectBox entity
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── objectbox_datasource.dart
│   │   │   └── media_store_datasource.dart
│   │   └── audio/
│   │       └── audio_handler.dart     # AudioHandler (audio_service)
│   └── repositories_impl/
│       ├── song_repository_impl.dart
│       ├── playlist_repository_impl.dart
│       └── stats_repository_impl.dart
└── presentation/
    ├── providers/                     # Riverpod providers
    │   ├── player_provider.dart
    │   ├── library_provider.dart
    │   ├── playlist_provider.dart
    │   ├── mood_provider.dart
    │   ├── search_provider.dart
    │   └── stats_provider.dart
    ├── screens/
    │   ├── splash/splash_screen.dart
    │   ├── onboarding/permission_screen.dart
    │   ├── home/home_screen.dart
    │   ├── library/
    │   │   ├── library_screen.dart
    │   │   ├── songs_tab.dart
    │   │   ├── albums_tab.dart
    │   │   ├── artists_tab.dart
    │   │   └── folders_tab.dart
    │   ├── now_playing/now_playing_screen.dart
    │   ├── playlist/
    │   │   ├── playlists_screen.dart
    │   │   └── playlist_detail_screen.dart
    │   ├── search/search_screen.dart
    │   ├── focus_mode/focus_mode_screen.dart
    │   └── stats/stats_screen.dart
    └── widgets/
        ├── mini_player.dart
        ├── song_list_tile.dart
        ├── album_card.dart
        ├── mood_selector.dart
        ├── sakura_overlay.dart
        ├── audio_visualizer.dart
        └── glassmorphic_card.dart
```

### 4.2 State Management — Riverpod

| Provider           | Type                                   | Responsibility                                 |
| ------------------ | -------------------------------------- | ---------------------------------------------- |
| `playerProvider`   | StateNotifierProvider                  | Playback state (current song, position, queue) |
| `libraryProvider`  | FutureProvider / StateNotifierProvider | Song scanning, library list                    |
| `playlistProvider` | StateNotifierProvider                  | CRUD playlists                                 |
| `moodProvider`     | StateProvider                          | Current mood selection                         |
| `searchProvider`   | StateNotifierProvider                  | Search query + results                         |
| `themeProvider`    | StateProvider                          | Light / dark mode toggle                       |
| `statsProvider`    | FutureProvider                         | Listening stats aggregation                    |

### 4.3 Packages & Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Audio
  just_audio: ^0.9.40
  audio_service: ^0.18.14
  just_audio_background: ^0.0.1-beta.12

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Database
  objectbox: ^4.0.0
  objectbox_flutter_libs: ^4.0.0

  # File & metadata
  on_audio_query: ^2.9.0
  path_provider: ^2.1.3
  flutter_media_metadata: ^1.0.0+1

  # Navigation
  go_router: ^13.2.0

  # UI
  google_fonts: ^6.2.1
  cached_network_image: ^3.3.1
  flutter_svg: ^2.0.10+1
  lucide_icons: ^0.5.0
  shimmer: ^3.0.0
  palette_generator: ^0.3.3+3

  # Animations
  lottie: ^3.1.0
  animated_background: ^2.0.0

  # Utilities
  permission_handler: ^11.3.1
  wakelock_plus: ^1.2.0
  share_plus: ^9.0.0
  package_info_plus: ^8.0.0
  flutter_local_notifications: ^17.2.1
  image_picker: ^1.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  objectbox_generator: ^4.0.0
  riverpod_generator: ^2.4.0
```

---

## 🗺️ 5. Navigation Structure

### 5.1 Route Map

```
/splash
/onboarding/permission
/home                         (root shell — shows BottomNavBar + MiniPlayer)
  /home/index
  /library
    /library/songs
    /library/albums
    /library/artists
    /library/folders
  /playlists
    /playlists/detail/:id
  /search
/now-playing                  (full-screen modal, no bottom nav)
/focus-mode                   (full-screen modal)
/stats
/settings
```

### 5.2 Bottom Navigation Tabs

| Index | Label     | Icon         | Route       |
| ----- | --------- | ------------ | ----------- |
| 0     | Home      | home         | /home/index |
| 1     | Library   | music_note_2 | /library    |
| 2     | Playlists | list_music   | /playlists  |
| 3     | Search    | search       | /search     |

---

## 📱 6. Core Features

### 6.1 Splash Screen

- Duration: 2.5 seconds
- Background: colorBackground
- Center: App logo + "Reimix" wordmark in headlineLarge style
- Animation: Lottie sakura petals falling from top, logo fades in at 500ms
- After timer: Navigate to /onboarding/permission (first launch) or /home (returning user)
- First-launch detection: Check shared preferences key onboarding_complete

---

### 6.2 Permission & Onboarding Screen

**Permissions required:**

| Permission       | Android                                                         | iOS                          |
| ---------------- | --------------------------------------------------------------- | ---------------------------- |
| Read audio files | READ_EXTERNAL_STORAGE (API < 33) / READ_MEDIA_AUDIO (API >= 33) | NSAppleMusicUsageDescription |
| Notifications    | POST_NOTIFICATIONS (API >= 33)                                  | UNUserNotificationCenter     |

**UI:**

- Full-screen cherry blossom illustration (Lottie or SVG)
- Headline: "Let's find your music"
- Subtext: "Reimix needs access to your audio files to build your library."
- CTA button: "Grant Access" — triggers permission_handler request
- If denied: show rationale dialog with "Open Settings" button
- On granted: trigger scanLocalSongs use case — navigate to /home

---

### 6.3 Home Screen

**Sections (top to bottom):**

1. **Header**
   - Greeting: "Good morning, ☀️" / "Good evening, 🌙" (time-based)
   - Subtitle: "What are you feeling today?"
   - Settings icon (top right)

2. **Mood Selector** (horizontal scroll, pill chips)
   - Options: 🌸 Calm · 💔 Sad · 🔥 Energetic · 🌙 Night · 🎯 Focus
   - Tapping a mood updates moodProvider, triggers animated color tween (600ms)

3. **Recently Played** (horizontal scroll, album cards 120x120dp)
   - Source: last 20 played songs sorted by lastPlayedAt desc
   - Empty state: "No songs played yet — tap a song to begin"

4. **Your Favorites** (horizontal scroll, album cards)
   - Source: songs where isFavorite == true, max 10
   - "See All" button → /library/songs?filter=favorites

5. **Your Playlists** (horizontal scroll, playlist cards 140x140dp)
   - Shows user-created + smart playlists
   - "New Playlist" shortcut card at position 0
   - "See All" → /playlists

---

### 6.4 Library Screen

**Tab bar:** Songs · Albums · Artists · Folders

#### Songs Tab

- Scrollable ListView with SongListTile
- Sort options (bottom sheet): A–Z, Z–A, Recently Added, Duration
- Long-press tile → context menu: Add to Playlist, Favorite, Share, Song Info
- Pull-to-refresh triggers re-scan

#### Albums Tab

- 2-column GridView with AlbumCard
- Tap → Album detail screen (song list filtered by album)

#### Artists Tab

- ListView with artist name + song count + top album art
- Tap → Artist detail screen

#### Folders Tab

- Tree view of filesystem folders containing audio files
- Tap folder → song list for that folder

**Scan behavior:**

- Uses on_audio_query to query MediaStore (Android) / Music Library (iOS)
- Supported formats: MP3, FLAC, AAC, M4A, OGG, WAV
- Metadata extracted: title, artist, album, duration, album art, track number, year, genre

---

### 6.5 Now Playing Screen

**Layout (portrait):**

```
┌─────────────────────────────────┐
│  [blurred album art background] │
│                                 │
│  ← Back title         ⋮ menu   │
│                                 │
│      ┌───────────────┐          │
│      │  Album Art    │  280dp   │
│      │  (animated)   │  radius 24dp
│      └───────────────┘          │
│                                 │
│  Song Title          ❤ Like    │
│  Artist Name                    │
│                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  0:42                    3:18   │
│                                 │
│  shuffle  prev  play  next  repeat  │
│                                 │
│  vol- ───────●──────────── vol+ │
│                                 │
│  [ Lyrics ]  [ Visualizer ]     │
│                                 │
└─────────────────────────────────┘
```

**Blur background:** Extract dominant color from album art using palette_generator. Apply as LinearGradient overlay on blurred album art (sigmaX/Y: 40).

**Album art animation:**

- On song change: rotate-out + fade old → rotate-in + fade new (400ms)
- While playing: subtle slow rotation (1 revolution / 30s), pauses on pause

**Controls spec:**

| Control    | Action                                           |
| ---------- | ------------------------------------------------ |
| Previous   | If position > 3s → seek to 0; else previous song |
| Play/Pause | Toggle playback (scale animation on tap)         |
| Next       | Play next in queue                               |
| Shuffle    | Toggle shuffle mode (accent color when active)   |
| Repeat     | Cycle: Off → Repeat All → Repeat One             |
| Favorite   | Toggle isFavorite (animated heart fill)          |

**Gestures:**

| Gesture              | Action                         |
| -------------------- | ------------------------------ |
| Swipe left           | Next song                      |
| Swipe right          | Previous song                  |
| Swipe up             | Open queue bottom sheet        |
| Tap album art        | Toggle lyrics / visualizer tab |
| Long press album art | Show song info dialog          |

**Queue bottom sheet:**

- Drag handle at top
- "Now Playing" header + current song highlighted in accent
- ReorderableListView for drag-to-reorder
- Swipe-to-dismiss removes from queue

**Lyrics tab:**

- Reads embedded LRC / SYLT tag from file metadata (if available)
- No lyrics: shows "No lyrics available"
- Synchronized highlighting: current line in accent color

**Visualizer tab:**

- Bar visualizer using just_audio amplitude stream
- 30–40 bars, colored in accent gradient

---

### 6.6 Mini Player

- **Visibility:** All bottom-nav screens when a song is loaded. Hidden on Now Playing screen.
- **Height:** 68dp, sits directly above BottomNavigationBar
- **Layout:** [AlbumArt 44dp] | Title / Artist | Play/Pause | Next
- Tap → navigate to /now-playing
- Swipe-to-dismiss → stops playback
- Background: glassmorphic with blur

---

### 6.7 Playlist Screen

**Smart Playlists (pinned top):**

- **Recently Played** — last 50 songs by lastPlayedAt
- **Most Played** — playCount > 5, sorted by count
- **Favorites** — all isFavorite == true songs

**My Playlists:** user-created playlists, FAB "+" to create

**Create playlist dialog:**

- Text field: Playlist name (max 60 chars)
- Optional: Pick cover image from gallery (image_picker)
- Confirm → creates playlist in ObjectBox

**Playlist detail screen:**

- Header: cover art / auto-collage from first 4 songs
- Playlist name, song count, total duration
- "Play All" and "Shuffle" buttons
- ReorderableListView of songs
- Long-press song → Remove from playlist

---

### 6.8 Search Screen

- Search bar: auto-focused, debounced 300ms
- Results grouped by: Songs (max 20), Albums (max 10), Artists (max 10), Playlists (max 5)
- Empty query: Show "Recent Searches" chips
- No results: Illustration + "No results for '[query]'"
- Tap result → navigate to detail or play song

---

### 6.9 Focus Mode Screen

Accessed from: Now Playing kebab menu

**Layout:**

- Minimal full-screen dark overlay
- Clock (HH:MM) top center
- Blurred album art (160x160dp)
- Play controls only (no extra chrome)
- Sleep Timer countdown ring around album art

**Sleep Timer options:** 15 min · 30 min · 45 min · 1 hour · End of song · Custom

- On expiry: 10-second fade-out → stop playback → dismiss
- Notification: "Reimix sleep timer ended"
- Screen stays awake (wakelock_plus)
- Status bar hidden

---

## 🚀 7. Advanced Features

### 7.1 Mood-Based UI System

| Mood         | Light BG | Dark BG | Accent  | Animation                        |
| ------------ | -------- | ------- | ------- | -------------------------------- |
| 🌸 Calm      | #FFF5F7  | #1E1A1D | #FF8DAA | Slow floating petals (Sakura ON) |
| 💔 Sad       | #F0F4FF  | #1A1C2E | #8DA8FF | Slow rain particles              |
| 🔥 Energetic | #FFF8F0  | #1E1A10 | #FF7043 | Fast pulse ripples               |
| 🌙 Night     | #F0EFF8  | #0D0F14 | #9B8EC4 | Star twinkle                     |
| 🎯 Focus     | #F4F9F4  | #141A14 | #5BAF7A | Minimal breath pulse             |

- Mood change triggers AnimatedTheme rebuild app-wide (600ms)
- Active mood persisted in ObjectBox AppSettings

### 7.2 Sakura Mode (Signature Feature)

- Active only in Calm mood
- Stack overlay on Now Playing and Home screens
- Custom CustomPainter petal particle system:
  - 8–12 particles on screen at a time
  - Each petal: random size (12–28dp), opacity (0.4–0.9), rotation speed
  - Fall path: parabolic with horizontal drift (wind simulation)
  - Lifecycle: 4–8s fall, fade out at bottom, respawn at top
  - Asset: SVG sakura petal
- RepaintBoundary isolation for performance

### 7.3 Audio Visualizer

- Custom CustomPainter + amplitude stream from just_audio
- Styles (user-selectable):
  - **Wave** — sine wave synced to beat
  - **Bars** — 32 vertical bars with smoothed amplitude
  - **Sakura** (Premium) — petals orbit center in sync with beat
- Shown in Now Playing visualizer tab and Focus Mode background

### 7.4 Sleep Timer

See section 6.9.

### 7.5 Listening Stats Screen

1. **This Week** — Bar chart (7 days x listening minutes)
2. **Top Songs** — Ranked list with play count
3. **Top Artists** — Ranked with total minutes listened
4. **Total Time** — e.g. "12h 34m this month"
5. **Streak** — Consecutive days with at least 1 song played

Data collection: increment playCount and totalListenedMs when song is played past 80% of duration.

---

## 🗃️ 8. Data Models

### 8.1 SongModel (ObjectBox)

```dart
@Entity()
class SongModel {
  @Id()
  int id = 0;
  late String filePath;
  late String title;
  String? artist;
  String? album;
  String? genre;
  int? year;
  int? trackNumber;
  late int durationMs;
  String? albumArtPath;
  bool isFavorite = false;
  int playCount = 0;
  DateTime? lastPlayedAt;
  int totalListenedMs = 0;
  late DateTime dateAdded;
}
```

### 8.2 PlaylistModel (ObjectBox)

```dart
@Entity()
class PlaylistModel {
  @Id()
  int id = 0;
  late String name;
  String? coverImagePath;
  late DateTime createdAt;
  DateTime? updatedAt;
  bool isSmartPlaylist = false;
  String? smartPlaylistType; // 'recently_played' | 'most_played' | 'favorites'
  @Backlink('playlist')
  final songs = ToMany<SongModel>();
  List<int> songOrder = [];
}
```

### 8.3 AppSettings (ObjectBox — singleton id: 1)

```dart
@Entity()
class AppSettings {
  @Id()
  int id = 1;
  String themeMode = 'system';  // 'light' | 'dark' | 'system'
  String activeMood = 'calm';
  bool sakuraModeEnabled = true;
  bool equalizerEnabled = false;
  int sleepTimerMinutes = 0;
  double volumeLevel = 1.0;
  String repeatMode = 'off';    // 'off' | 'all' | 'one'
  bool shuffleEnabled = false;
  bool onboardingComplete = false;
}
```

### 8.4 PlayerState (Riverpod in-memory)

```dart
class PlayerState {
  final SongModel? currentSong;
  final List<SongModel> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final RepeatMode repeatMode;  // off | all | one
  final bool shuffleEnabled;
  final double volume;          // 0.0–1.0
}
```

---

## 🔒 9. Permissions & Platform Requirements

### 9.1 Android — AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)

### 9.2 iOS — Info.plist

```xml
<key>NSAppleMusicUsageDescription</key>
<string>Reimix needs access to your music library to play your songs.</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

- Minimum iOS version: 14.0

---

## 🔄 10. User Flows

### 10.1 First Launch

```
App Launch
    Check onboarding_complete
        false → Splash (2.5s) → Permission Screen
                   Grant → Scan Library → /home
                   Deny  → Rationale dialog → (retry or limited mode)
        true  → Splash (2.5s) → /home
```

### 10.2 Play a Song

```
Library / Home / Playlist / Search
    Tap SongListTile
        playerProvider.playSong(song, queue: currentList)
            AudioHandler.playMediaItem(...)
            Update lastPlayedAt, increment playCount
            Navigate to /now-playing (or show MiniPlayer)
```

### 10.3 Create Playlist

```
Playlists → FAB "+"
    CreatePlaylistDialog
        Enter name + optional cover
        Confirm → PlaylistRepository.create(playlist)
            Navigate to PlaylistDetailScreen (empty)
                "Add Songs" → Song picker (multi-select) → Add
```

### 10.4 Sleep Timer

```
Now Playing kebab menu → "Sleep Timer"
    Timer options bottom sheet
        Select duration
            SleepTimer.start(duration)
                fadeOut(10s) → stopPlayback → notification
```

---

## ⚠️ 11. Error Handling

| Scenario                   | Behavior                                                                      |
| -------------------------- | ----------------------------------------------------------------------------- |
| No audio files found       | Empty state: "No music found. Make sure your audio files are on your device." |
| Corrupt / unsupported file | Skip during scan; log accessible in Settings > About                          |
| Storage permission denied  | Persistent banner: "Storage access required. Tap to grant."                   |
| Song file moved / deleted  | Snackbar: "File not found." Skip to next. Mark missing in DB                  |
| Audio focus lost (call)    | Pause playback. Resume on audio focus regained (configurable)                 |
| ObjectBox store corruption | Clear and re-scan library; show "Library rebuilt" toast                       |

---

## ⚡ 12. Performance Requirements

| Metric                     | Target                           |
| -------------------------- | -------------------------------- |
| Cold start to Home         | < 2s (excluding permission flow) |
| Library scan (1,000 songs) | < 5s                             |
| Screen transition          | 60fps consistently               |
| Now Playing load           | < 100ms from tap                 |
| Album art (cached)         | < 50ms                           |
| Album art (uncached)       | < 300ms                          |
| Memory (idle)              | < 100MB                          |
| Memory (playing)           | < 150MB                          |
| Sakura overlay fps         | >= 55fps on mid-range devices    |

**Optimizations:**

- Album art cached to local filesystem
- RepaintBoundary on MiniPlayer, SakuraOverlay, AudioVisualizer
- ListView.builder for all song lists (lazy rendering)
- ObjectBox queries run on background isolate
- on_audio_query paginated (page size: 200)

---

## 🧪 13. Testing Strategy

### 13.1 Unit Tests

| Module                  | Tests                                  |
| ----------------------- | -------------------------------------- |
| ScanLocalSongs use case | Parses metadata, handles empty list    |
| PlaylistRepository      | CRUD, song ordering                    |
| PlayerProvider          | Play/pause state, queue, shuffle logic |
| DurationFormatter       | Edge cases: 0s, >1h                    |
| MoodProvider            | Mood switch → correct theme output     |

### 13.2 Widget Tests

- SongListTile renders with full/partial metadata
- MiniPlayer shows correct info, play/pause toggles
- MoodSelector chips update selected state
- NowPlayingScreen seekbar interaction

### 13.3 Integration Tests

- Full flow: Permission → Scan → Play song → Verify MiniPlayer
- Create playlist → Add songs → Reorder → Delete

### 13.4 Manual QA Checklist (pre-release)

- [ ] Audio plays in background when app is minimized
- [ ] Lock screen media controls work
- [ ] Sleep timer fires and fades audio correctly
- [ ] Dark mode switches all screens correctly
- [ ] All 5 moods change theme colors correctly
- [ ] Sakura overlay renders without frame drops (low-end device)
- [ ] No crash on corrupt audio file
- [ ] Swipe gestures on Now Playing work consistently

---

## 💰 14. Monetization

### Free Tier

- Full local music playback
- Unlimited playlists
- Library management
- All 5 mood themes
- Sakura Mode
- Listening stats (current week)
- Sleep timer

### Reimix Premium

| Feature                    | Description                           |
| -------------------------- | ------------------------------------- |
| Wave & Particle Visualizer | Full audio visualizer styles          |
| Sakura Visualizer          | Beat-synced sakura petal orbit effect |
| Theme customization        | Custom accent colors beyond presets   |
| Extended stats             | Full history, monthly/yearly recap    |
| Song metadata editor       | Edit title, artist, album, cover art  |
| Cloud sync (V3)            | Sync playlists and favorites          |
| Ad-free                    | If ads are introduced                 |

Pricing (placeholder): $2.99/month or $14.99/year
Payment: Google Play Billing / in_app_purchase Flutter plugin

---

## 📊 15. Success Metrics

| Metric                    | V1 Target (3 months post-launch) |
| ------------------------- | -------------------------------- |
| Total Installs            | 10,000                           |
| Day-7 Retention           | >= 35%                           |
| Day-30 Retention          | >= 20%                           |
| Avg. Daily Listening Time | >= 25 minutes                    |
| Playlist Creation Rate    | >= 40% of active users           |
| Crash-free Rate           | >= 99.5%                         |
| App Store Rating          | >= 4.5 stars                     |
| Premium Conversion        | >= 5% of active users            |

---

## 🗓️ 16. Release Roadmap

### V1.0 — Core Experience (8 weeks)

**Sprint 1 (Week 1–2): Foundation**

- [ ] Clean Architecture + Riverpod project setup
- [ ] Design system (colors, typography, theme light/dark)
- [ ] ObjectBox database + models
- [ ] Onboarding / permission screen
- [ ] Library scanning (on_audio_query)

**Sprint 2 (Week 3–4): Library & Playback**

- [ ] Songs / Albums / Artists / Folders tabs
- [ ] Audio engine (just_audio + audio_service)
- [ ] Background playback + lock screen controls
- [ ] Now Playing screen (basic)

**Sprint 3 (Week 5–6): Now Playing & Mood**

- [ ] Now Playing full UI (blur background, gestures, queue)
- [ ] Mini player
- [ ] Mood selector + animated theme switching
- [ ] Playlist CRUD + smart playlists

**Sprint 4 (Week 7–8): Polish & Launch**

- [ ] Home screen (recently played, favorites, mood sections)
- [ ] Search screen
- [ ] Focus Mode + Sleep Timer
- [ ] Sakura overlay animation
- [ ] Bug fixes + performance pass
- [ ] App icon, splash screen, store assets

### V2.0 — Killer Features (+6 weeks after V1)

- [ ] Audio visualizer (Wave + Bars)
- [ ] Listening stats screen
- [ ] Song metadata editor
- [ ] Lyrics display (LRC embedded)
- [ ] Advanced mood animations (rain, pulse, stars)

### V3.0 — Smart & Social (+3 months after V2)

- [ ] AI-based "Reimix For You" recommendations
- [ ] Cloud playlist / favorites sync
- [ ] Social sharing (now-playing card as image)
- [ ] Android home screen widget
- [ ] Apple Watch / Wear OS companion controls

---

## 💖 Appendix — Emotional UX ("Magic Touch")

| Interaction                 | Micro-interaction                       |
| --------------------------- | --------------------------------------- |
| Tap Play button             | Scale bounce: 0.9 → 1.1 → 1.0 (150ms)   |
| Tap Favorite (heart)        | Heart fill + particle burst             |
| Song change (swipe)         | Album art slides out, new art slides in |
| Mood switch                 | Full-screen animated color tween flood  |
| Library scan complete       | Petal burst toast notification          |
| Empty library on first open | Animated illustration + friendly copy   |
| Long press album art        | Haptic feedback (medium impact)         |
| Add song to playlist        | Checkmark animation on tile             |
| Tap sakura petal            | Petal spins and fades                   |
