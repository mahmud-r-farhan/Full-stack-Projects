import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/settings/providers/settings_provider.dart';
import '../../../../shared/widgets/glass_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  Onboarding Screen — Permission walkthrough with
//  integrated media access request
// ═══════════════════════════════════════════════════════════

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _permissionGranted = false;
  bool _requestingPermission = false;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      icon: Icons.photo_library_rounded,
      gradient: AppColors.heroGradient,
      title: 'Welcome to Lumina',
      subtitle:
          'Your photos & videos, beautifully organized, entirely on your device. No cloud. No subscriptions. Pure digital sovereignty.',
    ),
    _OnboardPage(
      icon: Icons.wifi_tethering_rounded,
      gradient: AppColors.shareGradient,
      title: 'Share Instantly',
      subtitle:
          'Cast your gallery to any device on the same Wi-Fi. Your PC, tablet, or Smart TV gets a live browsable gallery, no app needed.',
    ),
    _OnboardPage(
      icon: Icons.lock_rounded,
      gradient: AppColors.vaultGradient,
      title: 'The Vault',
      subtitle:
          'A biometric-protected sanctuary. Move your most private moments here, they become invisible to other apps and prying eyes.',
    ),
    _OnboardPage(
      icon: Icons.folder_open_rounded,
      gradient: AppColors.heroGradient,
      title: 'Media Access',
      subtitle:
          'Lumina needs permission to display your photos & videos. We never upload, never track, and never sell your data. Your media stays yours.',
      isPermissionPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _requestingPermission = true);

    try {
      final state = await PhotoManager.requestPermissionExtend();
      if (mounted) {
        setState(() {
          _permissionGranted = state.isAuth;
          _requestingPermission = false;
        });

        if (state.isAuth) {
          // Auto-advance after permission granted
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _finish();
        } else if (state == PermissionState.denied) {
          // Show dialog suggesting to open settings
          if (mounted) _showPermissionDeniedDialog();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _requestingPermission = false);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Lumina Gallery needs media access to display your photos and videos. '
          'Please grant permission in your device settings.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              PhotoManager.openSetting();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              // ── Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (ctx, i) => _OnboardPageView(
                    page: _pages[i],
                    permissionGranted: _permissionGranted,
                    requestingPermission: _requestingPermission,
                    onRequestPermission: _requestPermission,
                  ),
                ),
              ),

              // ── Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: _currentPage == i
                          ? const LinearGradient(colors: AppColors.heroGradient)
                          : null,
                      color: _currentPage == i ? null : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── CTA Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _currentPage == _pages.length - 1
                    ? Column(
                        children: [
                          if (!_permissionGranted)
                            GlassButton(
                              label: 'Grant Access',
                              icon: Icons.folder_open_rounded,
                              width: double.infinity,
                              isLoading: _requestingPermission,
                              onPressed: _requestPermission,
                            )
                          else
                            GlassButton(
                              label: 'Get Started',
                              icon: Icons.rocket_launch_rounded,
                              width: double.infinity,
                              onPressed: _finish,
                            ),
                          if (!_permissionGranted) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _finish,
                              child: const Text(
                                'Continue without access →',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    : GlassButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        width: double.infinity,
                        onPressed: _next,
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.isPermissionPage = false,
  });
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final bool isPermissionPage;
}

class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({
    required this.page,
    this.permissionGranted = false,
    this.requestingPermission = false,
    this.onRequestPermission,
  });
  final _OnboardPage page;
  final bool permissionGranted;
  final bool requestingPermission;
  final VoidCallback? onRequestPermission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon
          Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradient.first.withValues(alpha: 0.5),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: page.isPermissionPage && permissionGranted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 72,
                        color: Colors.white,
                      )
                    : Icon(page.icon, size: 72, color: Colors.white),
              )
              .animate()
              .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 48),
          GradientText(
                page.title,
                gradient: LinearGradient(colors: page.gradient),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .slideY(begin: 0.2, curve: Curves.easeOut)
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 20),
          Text(
                page.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .slideY(begin: 0.3, curve: Curves.easeOut)
              .fadeIn(delay: 200.ms),

          // Permission status badge
          if (page.isPermissionPage) ...[
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: permissionGranted
                  ? Container(
                      key: const ValueKey('granted'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.success.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Access Granted ✓',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('not_granted')),
            ),
          ],
        ],
      ),
    );
  }
}
