/// All English UI strings for Reimix
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Reimix';

  // Onboarding / Permission
  static const String permissionTitle = "Let's find your music";
  static const String permissionSubtext =
      'Reimix needs access to your audio files to build your library.';
  static const String grantAccess = 'Grant Access';
  static const String openSettings = 'Open Settings';
  static const String permissionDeniedTitle = 'Permission Required';
  static const String permissionDeniedBody =
      'Storage permission is needed to read your audio files. '
      'Please grant it in Settings.';

  // Home
  static const String goodMorning = 'Good morning ☀️';
  static const String goodAfternoon = 'Good afternoon 🌤';
  static const String goodEvening = 'Good evening 🌙';
  static const String homeSubtitle = 'What are you feeling today?';
  static const String recentlyPlayed = 'Recently Played';
  static const String yourFavorites = 'Your Favorites';
  static const String yourPlaylists = 'Your Playlists';
  static const String seeAll = 'See All';
  static const String noSongsPlayedYet = 'No songs played yet — tap a song to begin';
  static const String noFavorites = 'No favorites yet — heart a song';

  // Library tabs
  static const String songs = 'Songs';
  static const String albums = 'Albums';
  static const String artists = 'Artists';
  static const String folders = 'Folders';

  // Library empty states
  static const String noMusicFound =
      'No music found. Make sure your audio files are on your device.';

  // Moods
  static const String moodCalm = '🌸 Calm';
  static const String moodSad = '💔 Sad';
  static const String moodEnergetic = '🔥 Energetic';
  static const String moodNight = '🌙 Night';
  static const String moodFocus = '🎯 Focus';

  // Now Playing
  static const String lyrics = 'Lyrics';
  static const String visualizer = 'Visualizer';
  static const String noLyrics = 'No lyrics available';
  static const String queue = 'Now Playing';

  // Playlists
  static const String playlists = 'Playlists';
  static const String newPlaylist = 'New Playlist';
  static const String playAll = 'Play All';
  static const String shuffle = 'Shuffle';
  static const String recentlyPlayedPlaylist = 'Recently Played';
  static const String mostPlayedPlaylist = 'Most Played';
  static const String favoritesPlaylist = 'Favorites';
  static const String createPlaylist = 'Create Playlist';
  static const String playlistNameHint = 'Playlist name';
  static const String addCover = 'Add Cover';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';

  // Search
  static const String search = 'Search';
  static const String searchHint = 'Songs, artists, albums…';
  static const String recentSearches = 'Recent Searches';
  static const String noResults = "No results for";

  // Focus Mode / Sleep Timer
  static const String focusMode = 'Focus Mode';
  static const String sleepTimer = 'Sleep Timer';
  static const String sleepTimerEnded = 'Reimix sleep timer ended';
  static const String endOfSong = 'End of song';
  static const String custom = 'Custom';

  // Settings
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
  static const String defaultMood = 'Default Mood';
  static const String audioFocusBehavior = 'Audio Focus Behavior';
  static const String about = 'About';
  static const String errorLog = 'Error Log';

  // Stats
  static const String stats = 'Stats';
  static const String thisWeek = 'This Week';
  static const String topSongs = 'Top Songs';
  static const String topArtists = 'Top Artists';
  static const String totalTime = 'Total Time';
  static const String streak = 'Streak';

  // Errors / Snackbars
  static const String fileNotFound = 'File not found.';
  static const String libraryRebuilt = 'Library rebuilt.';
  static const String storagePermissionBanner = 'Storage access required. Tap to grant.';

  // Context menu
  static const String addToPlaylist = 'Add to Playlist';
  static const String favorite = 'Favorite';
  static const String share = 'Share';
  static const String songInfo = 'Song Info';
  static const String removeFromPlaylist = 'Remove from Playlist';

  // SharedPreferences keys
  static const String prefOnboardingComplete = 'onboarding_complete';
}
