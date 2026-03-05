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
//  LAN Sharing Screen — Improved UI/UX
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header with icon
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: AppColors.shareGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shareGradient.first.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          'LAN Share',
                          gradient: const LinearGradient(
                            colors: AppColors.shareGradient,
                          ),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Share locally — no internet needed',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.05),
              const SizedBox(height: 28),

              // ── Main share card
              _ShareCard(serverInfo: serverInfo),
              const SizedBox(height: 20),

              // ── Features / How it works
              if (serverInfo.isRunning) _RunningFeatures() else _HowItWorks(),
              const SizedBox(height: 20),

              // ── Directory Selection (if not running)
              if (!serverInfo.isRunning) _FolderDropdownSelector(),
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
      borderRadius:
          (Theme.of(
                context,
              ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
              true)
          ? 32
          : 16,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: serverInfo.isRunning
                ? _ActiveServerView(serverInfo: serverInfo)
                : serverInfo.status == ServerStatus.starting
                ? const _StartingView()
                : const _StoppedView(),
          ),

          const SizedBox(height: 24),

          // Error message
          if (serverInfo.status == ServerStatus.error) ...[
            _ErrorBanner(message: serverInfo.errorMessage ?? 'Unknown error'),
            const SizedBox(height: 16),
          ],

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

// ─── Active Server View ──────────────────────────────────
class _ActiveServerView extends StatelessWidget {
  const _ActiveServerView({required this.serverInfo});
  final LanServerInfo serverInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('active'),
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(
              (Theme.of(
                        context,
                      ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                      true)
                  ? 24
                  : 12,
            ),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Server Active',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 20),

        // QR Code
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              Theme.of(
                        context,
                      ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                      true
                  ? 24
                  : 12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.08,
                ),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: QrImageView(
            data: serverInfo.url,
            version: QrVersions.auto,
            size: 180,
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
        ).animate().scale(begin: const Offset(0.85, 0.85)).fadeIn(),
        const SizedBox(height: 16),

        // URL chip with copy button
        GlassContainer(
          borderRadius:
              (Theme.of(
                    context,
                  ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                  true)
              ? 20
              : 8,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  serverInfo.url,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(url: serverInfo.url),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Scan the QR code or open the URL on any device\non the same Wi-Fi network',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Copy button with feedback ───────────────────────────
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.url});
  final String url;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? const Icon(
                Icons.check_rounded,
                key: ValueKey('check'),
                color: AppColors.success,
                size: 18,
              )
            : const Icon(
                Icons.copy_rounded,
                key: ValueKey('copy'),
                color: AppColors.textSecondary,
                size: 16,
              ),
      ),
    );
  }
}

// ─── Starting View ────────────────────────────────────────
class _StartingView extends StatelessWidget {
  const _StartingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('starting'),
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Starting server…',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: 0.6,
          child: const Text(
            'Setting up local network',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─── Stopped View ─────────────────────────────────────────
class _StoppedView extends StatelessWidget {
  const _StoppedView();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('stopped'),
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.glassDark
                : AppColors.glassLight,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.glassBorder
                  : AppColors.glassLightBorder,
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.textMuted,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Server Stopped',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the button below to start sharing\nyour gallery on the local network',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius:
          (Theme.of(
                context,
              ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
              true)
          ? 20
          : 8,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

// ─── Running Features ─────────────────────────────────────
class _RunningFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.devices_rounded,
        AppColors.accent,
        'Any Device',
        'Works on phones, tablets, PCs, and Smart TVs',
      ),
      (
        Icons.videocam_rounded,
        AppColors.primary,
        'Video Streaming',
        'Play videos directly in the browser',
      ),
      (
        Icons.download_rounded,
        AppColors.success,
        'Direct Download',
        'Save any photo or video to connected devices',
      ),
      (
        Icons.shield_rounded,
        AppColors.accentWarm,
        'Private & Local',
        'No internet required — stays on your network',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.shareGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Active Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...features.asMap().entries.map((e) {
          final (icon, color, title, subtitle) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              borderRadius:
                  (Theme.of(
                        context,
                      ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                      true)
                  ? 24
                  : 12,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ).animate().slideX(begin: 0.08).fadeIn(delay: (e.key * 70).ms),
          );
        }),
      ],
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
        '1. Start Sharing',
        'Lumina starts a local HTTP server on your network',
      ),
      (
        Icons.qr_code_scanner_rounded,
        AppColors.primary,
        '2. Scan the QR Code',
        'Any device on your Wi-Fi can open your gallery',
      ),
      (
        Icons.download_rounded,
        AppColors.success,
        '3. Browse & Save',
        'View photos, stream videos, and download files',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'How it works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...steps.asMap().entries.map((e) {
          final (icon, color, title, subtitle) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              borderRadius:
                  (Theme.of(
                        context,
                      ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                      true)
                  ? 24
                  : 12,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
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
            ).animate().slideX(begin: 0.08).fadeIn(delay: (e.key * 80).ms),
          );
        }),

        // Privacy note at bottom
        const SizedBox(height: 16),
        Center(
          child: GlassContainer(
            borderRadius:
                (Theme.of(
                      context,
                    ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                    true)
                ? 24
                : 12,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Pure Privacy — Digital Sovereignty',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ),
      ],
    );
  }
}

// ─── Simple Folder Dropdown Selector ──────────────────────
/// Quick folder selection dropdown to start sharing instantly
class _FolderDropdownSelector extends ConsumerStatefulWidget {
  const _FolderDropdownSelector();

  @override
  ConsumerState<_FolderDropdownSelector> createState() =>
      _FolderDropdownSelectorState();
}

class _FolderDropdownSelectorState
    extends ConsumerState<_FolderDropdownSelector> {
  ShareableDirectory? selectedFolder;

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(folderBrowserProvider);

    return foldersAsync.when(
      data: (folders) {
        // Set default selection if not already set
        if (selectedFolder == null && folders.isNotEmpty) {
          selectedFolder = folders.first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 6,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.shareGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Select Folder to Share',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Choose a folder or use All Photos as default',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.glassBorder
                              : AppColors.glassLightBorder)
                          .withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(
                  (Theme.of(
                            context,
                          ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                          true)
                      ? 20
                      : 10,
                ),
                color:
                    (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.glassDark
                            : AppColors.glassLight)
                        .withValues(alpha: 0.4),
              ),
              child: DropdownButton<ShareableDirectory>(
                value: selectedFolder,
                isExpanded: true,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: folders
                    .map(
                      (folder) => DropdownMenuItem(
                        value: folder,
                        child: Row(
                          children: [
                            Text(
                              folder.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    folder.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    folder.displayPath,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (folder) {
                  setState(() {
                    selectedFolder = folder;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),

            // Start Sharing Button
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: selectedFolder != null
                      ? () {
                          final path = selectedFolder!.path == 'PHOTOS_SYSTEM'
                              ? null
                              : selectedFolder!.path;
                          ref
                              .read(lanShareProvider.notifier)
                              .startServer(sharePath: path);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Started sharing from ${selectedFolder!.name}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 3),
                              margin: const EdgeInsets.all(16),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (Theme.of(context)
                                              .extension<LiquidThemeExtension>()
                                              ?.isLiquidDesign ??
                                          true)
                                      ? 24
                                      : 12,
                                ),
                              ),
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(
                    (Theme.of(context)
                                .extension<LiquidThemeExtension>()
                                ?.isLiquidDesign ??
                            true)
                        ? 24
                        : 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: selectedFolder == null
                          ? LinearGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.3),
                                AppColors.primary.withValues(alpha: 0.3),
                              ],
                            )
                          : const LinearGradient(
                              colors: AppColors.shareGradient,
                            ),
                      borderRadius: BorderRadius.circular(
                        (Theme.of(context)
                                    .extension<LiquidThemeExtension>()
                                    ?.isLiquidDesign ??
                                true)
                            ? 24
                            : 12,
                      ),
                      boxShadow: selectedFolder == null
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Start Sharing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentWarm.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                  (Theme.of(
                            context,
                          ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                          true)
                      ? 20
                      : 8,
                ),
                border: Border.all(
                  color: AppColors.accentWarm.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentWarm,
                    size: 16,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Files will be served only from the selected folder and its subfolders.',
                      style: TextStyle(
                        color: AppColors.accentWarm,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            (Theme.of(
                      context,
                    ).extension<LiquidThemeExtension>()?.isLiquidDesign ??
                    true)
                ? 20
                : 8,
          ),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Error loading folders: $err',
                style: const TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
