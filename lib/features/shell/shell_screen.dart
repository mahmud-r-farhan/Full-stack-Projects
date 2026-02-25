import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../gallery/presentation/screens/gallery_screen.dart';
import '../sharing/presentation/screens/sharing_screen.dart';
import '../vault/presentation/screens/vault_screen.dart';
import '../settings/presentation/screens/settings_screen.dart';

// ═══════════════════════════════════════════════════════════
//  Shell Screen — Main navigation host
//  Floating glass bottom nav bar preserves page state via
//  IndexedStack so each tab stays alive.
// ═══════════════════════════════════════════════════════════

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  static const _pages = [
    GalleryScreen(),
    SharingScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ── Page content (IndexedStack keeps pages alive)
            IndexedStack(index: _selectedIndex, children: _pages),

            // ── Floating glassmorphism navigation bar
            GlassNavBar(
              selectedIndex: _selectedIndex,
              onTap: (i) {
                HapticFeedback.lightImpact();
                setState(() => _selectedIndex = i);
              },
            ),
          ],
        ),
      ),
    );
  }
}
