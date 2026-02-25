import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/settings/providers/settings_provider.dart';
import '../../../../shared/widgets/glass_widgets.dart';

// ═══════════════════════════════════════════════════════════
//  Onboarding Screen — Clean permission walkthrough
// ═══════════════════════════════════════════════════════════

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      icon: Icons.photo_library_rounded,
      gradient: AppColors.heroGradient,
      title: 'Your Sanctuary',
      subtitle:
          'LiquidSync keeps your photos & videos beautifully organized — entirely on your device. No cloud. No subscriptions. No anxiety.',
    ),
    _OnboardPage(
      icon: Icons.wifi_tethering_rounded,
      gradient: AppColors.shareGradient,
      title: 'Share Instantly',
      subtitle:
          'Cast your gallery to any device on the same Wi-Fi with a single tap. Your PC, tablet, or Smart TV gets a live browsable gallery — no app needed.',
    ),
    _OnboardPage(
      icon: Icons.lock_rounded,
      gradient: AppColors.vaultGradient,
      title: 'The Vault',
      subtitle:
          'A biometric-protected sanctuary within a sanctuary. Move your most private moments here and they become invisible to everything else.',
    ),
    _OnboardPage(
      icon: Icons.check_circle_rounded,
      gradient: AppColors.heroGradient,
      title: 'One Permission',
      subtitle:
          'We only ask for media access — to display YOUR photos. Nothing else. We never upload, never track, and never sell your data.',
      isLast: true,
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
                  child: Text(
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
                  itemBuilder: (ctx, i) => _OnboardPageView(page: _pages[i]),
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
                child: GlassButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Continue',
                  icon: _currentPage == _pages.length - 1
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
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
    this.isLast = false,
  });
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final bool isLast;
}

class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({required this.page});
  final _OnboardPage page;

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
                      color: page.gradient.first.withOpacity(0.5),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(page.icon, size: 72, color: Colors.white),
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
        ],
      ),
    );
  }
}
