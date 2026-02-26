// ─── App Constants ──────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const String appName = 'Lumina Gallery';
  static const String appFullName = 'Lumina Gallery: Photo & Share';
  static const String appDescription =
      'Lightning-fast gallery. Hide photos & share to PC/TV instantly via Wi-Fi!';
  static const String appVersion = '1.0.0';

  // Media grid
  static const int gridBatchSize = 100;
  static const int gridCrossAxisCountDefault = 3;
  static const int gridCrossAxisCountMin = 2;
  static const int gridCrossAxisCountMax = 6;
  static const double gridSpacing = 2.0;
  static const double thumbnailSize = 200.0;

  // LAN Sharing
  static const int lanServerPort = 8080;
  static const String lanServerPath = '/gallery';

  // Vault
  static const String vaultAlbumName = '.LuminaVault';
  static const String vaultPrefsKey = 'vault_enabled';

  // Preferences keys
  static const String prefsDarkMode = 'dark_mode';
  static const String prefsPerformanceMode = 'performance_mode';
  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsVaultSetup = 'vault_setup';
  static const String prefsGridColumns = 'grid_columns';

  // Supported media types (for reference — photo_manager handles all of these)
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'bmp',
    'gif',
    'tiff',
    'tif',
    'raw',
    'dng',
    'cr2',
    'nef',
    'arw',
    'rw2',
    'orf',
    'sr2',
    'pef',
    'svg',
  ];

  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'mkv',
    'avi',
    'webm',
    '3gp',
    'flv',
    'wmv',
    'm4v',
    'ts',
  ];
}
