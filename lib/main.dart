import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/shell/shell_screen.dart';

// ═══════════════════════════════════════════════════════════
//  Entry Point
// ═══════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Pre-warm photo manager (suppresses cold-start jank)
  PhotoManager.setLog(false);

  // ── Load shared prefs synchronously for first frame
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject SharedPreferences into the provider tree
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const LiquidSyncApp(),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  Root App Widget
// ═══════════════════════════════════════════════════════════

class LiquidSyncApp extends ConsumerWidget {
  const LiquidSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    // Material You — DynamicColorBuilder wraps for Android 12+ Monet support
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // ── Themes
          theme: AppTheme.light(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // ── Performance mode: propagate to theme extension
          builder: (context, child) {
            final base = Theme.of(context);
            final ext = base.extension<LiquidThemeExtension>();
            return Theme(
              data: base.copyWith(
                extensions: [
                  (ext ?? const LiquidThemeExtension.dark()).copyWith(
                    isPerformanceMode: settings.isPerformanceMode,
                    blurSigma: settings.isPerformanceMode ? 0 : 20,
                  ),
                ],
              ),
              child: child!,
            );
          },

          // ── Router: Onboarding gate
          home: settings.onboardingComplete
              ? const ShellScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
