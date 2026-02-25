// ─── App Constants ──────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const String appName = 'LiquidSync Gallery';
  static const String appVersion = '1.0.0';

  // Media grid
  static const int gridBatchSize = 100;
  static const int gridCrossAxisCount = 3;
  static const double gridSpacing = 2.0;
  static const double thumbnailSize = 200.0;

  // LAN Sharing
  static const int lanServerPort = 8080;
  static const String lanServerPath = '/gallery';

  // Vault
  static const String vaultAlbumName = '.LiquidVault';
  static const String vaultPrefsKey = 'vault_enabled';

  // Preferences keys
  static const String prefsDarkMode = 'dark_mode';
  static const String prefsPerformanceMode = 'performance_mode';
  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsVaultSetup = 'vault_setup';
}
