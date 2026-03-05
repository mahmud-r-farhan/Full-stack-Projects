import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  Settings Providers — Riverpod
// ═══════════════════════════════════════════════════════════

// ─── SharedPreferences instance ──────────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// ─── App Settings Notifier ───────────────────────────────
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPrefsProvider);
    return AppSettings(
      isDarkMode: prefs.getBool(AppConstants.prefsDarkMode) ?? true,
      isPerformanceMode:
          prefs.getBool(AppConstants.prefsPerformanceMode) ?? false,
      isLiquidDesign: prefs.getBool(AppConstants.prefsLiquidDesign) ?? true,
      onboardingComplete:
          prefs.getBool(AppConstants.prefsOnboardingDone) ?? false,
      vaultEnabled: prefs.getBool(AppConstants.prefsVaultSetup) ?? false,
      gridColumns:
          prefs.getInt(AppConstants.prefsGridColumns) ??
          AppConstants.gridCrossAxisCountDefault,
    );
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.prefsDarkMode, value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> setLiquidDesign(bool value) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.prefsLiquidDesign, value);
    state = state.copyWith(isLiquidDesign: value);
  }

  Future<void> setPerformanceMode(bool value) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.prefsPerformanceMode, value);
    state = state.copyWith(isPerformanceMode: value);
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.prefsOnboardingDone, true);
    state = state.copyWith(onboardingComplete: true);
  }

  Future<void> setVaultEnabled(bool value) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.prefsVaultSetup, value);
    state = state.copyWith(vaultEnabled: value);
  }

  Future<void> setGridColumns(int value) async {
    final clamped = value.clamp(
      AppConstants.gridCrossAxisCountMin,
      AppConstants.gridCrossAxisCountMax,
    );
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(AppConstants.prefsGridColumns, clamped);
    state = state.copyWith(gridColumns: clamped);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
