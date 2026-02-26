import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../providers/lan_share_provider.dart';

// ═══════════════════════════════════════════════════════════
//  LAN Sharing Screen
//  The "Killer Feature" — tap, start server, show QR
// ═══════════════════════════════════════════════════════════

class SharingScreen extends ConsumerWidget {
  const SharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverInfo = ref.watch(lanShareProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header
              GradientText(
                'LAN Share',
                gradient: const LinearGradient(colors: AppColors.shareGradient),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share your gallery with any device on your Wi-Fi. No internet needed.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // ── Main share card
              _ShareCard(serverInfo: serverInfo),
              const SizedBox(height: 24),

              // ── How it works
              if (!serverInfo.isRunning) _HowItWorks(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Share Card ───────────────────────────────────────────
class _ShareCard extends ConsumerWidget {
  const _ShareCard({required this.serverInfo});
  final LanServerInfo serverInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Status icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: serverInfo.isRunning
                ? _PulsingIcon(
                    key: const ValueKey('running'),
                    icon: Icons.wifi_tethering_rounded,
                    gradient: AppColors.shareGradient,
                  )
                : serverInfo.status == ServerStatus.starting
                ? const SizedBox(
                    key: ValueKey('starting'),
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 3,
                    ),
                  )
                : Container(
                    key: const ValueKey('stopped'),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glassDark,
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.textMuted,
                      size: 40,
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // Status text
          Text(
            serverInfo.isRunning
                ? 'Server Running'
                : serverInfo.status == ServerStatus.starting
                ? 'Starting…'
                : serverInfo.status == ServerStatus.error
                ? 'Connection Error'
                : 'Server Stopped',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: serverInfo.isRunning
                  ? AppColors.success
                  : serverInfo.status == ServerStatus.error
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),

          // QR code + URL when running
          if (serverInfo.isRunning) ...[
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: serverInfo.url,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0A0A14),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0A0A14),
                ),
              ),
            ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
            const SizedBox(height: 16),
            // URL chip
            GlassContainer(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(
                    Icons.link_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serverInfo.url,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: serverInfo.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan the QR or open the URL on any device',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],

          // Error message
          if (serverInfo.status == ServerStatus.error) ...[
            const SizedBox(height: 12),
            Text(
              serverInfo.errorMessage ?? 'Unknown error',
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // Toggle button
          GlassButton(
            label: serverInfo.isRunning ? 'Stop Sharing' : 'Start Sharing',
            icon: serverInfo.isRunning
                ? Icons.stop_circle_outlined
                : Icons.wifi_tethering_rounded,
            isLoading: serverInfo.status == ServerStatus.starting,
            gradient: serverInfo.isRunning
                ? const LinearGradient(
                    colors: [Color(0xFFFF4C6A), Color(0xFFFF8C42)],
                  )
                : const LinearGradient(colors: AppColors.shareGradient),
            width: double.infinity,
            onPressed: () => ref.read(lanShareProvider.notifier).toggleServer(),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing animated icon ────────────────────────────────
class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({super.key, required this.icon, required this.gradient});
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white24)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          duration: 1000.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.08, 1.08),
          end: const Offset(1.0, 1.0),
          duration: 1000.ms,
        );
  }
}

// ─── How it works section ─────────────────────────────────
class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        Icons.play_circle_outline_rounded,
        AppColors.accent,
        'Tap "Start Sharing"',
        'LiquidSync starts a local HTTP server on your network',
      ),
      (
        Icons.qr_code_scanner_rounded,
        AppColors.primary,
        'Scan the QR Code',
        'Any device on your Wi-Fi can open your gallery instantly',
      ),
      (
        Icons.download_rounded,
        AppColors.success,
        'Browse & Save',
        'View thumbnails and download files directly to any device',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((e) {
          final (icon, color, title, subtitle) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().slideX(begin: 0.1).fadeIn(delay: (e.key * 80).ms),
          );
        }),
      ],
    );
  }
}
