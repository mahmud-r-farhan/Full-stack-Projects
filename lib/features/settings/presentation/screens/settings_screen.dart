import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../settings/providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════
//  Settings Screen — Lumina Gallery
// ═══════════════════════════════════════════════════════════

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title
              GradientText(
                'Settings',
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentWarm],
                ),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customize your Lumina Gallery experience.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // ── Appearance
              const _SectionHeader(label: 'APPEARANCE'),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.primary,
                title: 'Dark Mode',
                subtitle: 'Enable dark theme (recommended)',
                trailing: Switch.adaptive(
                  value: settings.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (v) => notifier.setDarkMode(v),
                ),
              ),

              const SizedBox(height: 8),

              _SettingsTile(
                icon: Icons.speed_rounded,
                iconColor: AppColors.accent,
                title: 'Performance Mode',
                subtitle: 'Reduce blur/animations for low-end devices',
                trailing: Switch.adaptive(
                  value: settings.isPerformanceMode,
                  activeColor: AppColors.accent,
                  onChanged: (v) => notifier.setPerformanceMode(v),
                ),
              ),

              const SizedBox(height: 24),

              // ── Grid
              const _SectionHeader(label: 'GRID LAYOUT'),
              const SizedBox(height: 12),

              _GridColumnPicker(
                current: settings.gridColumns,
                onChanged: (v) => notifier.setGridColumns(v),
              ),

              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '💡 Tip: Pinch-to-zoom on the gallery grid to quickly change columns',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Privacy
              const _SectionHeader(label: 'PRIVACY & DATA'),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.lock_rounded,
                iconColor: AppColors.accentWarm,
                title: 'Secure Vault',
                subtitle: settings.vaultEnabled
                    ? 'Vault is active — biometrics/PIN protected'
                    : 'Enable biometric-protected media vault',
                trailing: Switch.adaptive(
                  value: settings.vaultEnabled,
                  activeColor: AppColors.accentWarm,
                  onChanged: (v) => notifier.setVaultEnabled(v),
                ),
              ),

              const SizedBox(height: 8),

              _SettingsTile(
                icon: Icons.analytics_outlined,
                iconColor: AppColors.textMuted,
                title: 'Crash Reporting',
                subtitle:
                    'Opt-in: Send anonymous crash logs to help improve the app',
                trailing: Switch.adaptive(
                  value: settings.crashReportingOptIn,
                  activeColor: AppColors.primary,
                  onChanged: (v) {},
                ),
              ),

              const SizedBox(height: 24),

              // ── Supported Formats
              const _SectionHeader(label: 'SUPPORTED FORMATS'),
              const SizedBox(height: 12),
              _FormatsCard(),

              const SizedBox(height: 24),

              // ── About
              const _SectionHeader(label: 'ABOUT'),
              const SizedBox(height: 12),

              _AboutCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withOpacity(0.15),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
          trailing,
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}

// ─── Grid Column Picker ───────────────────────────────────
class _GridColumnPicker extends StatelessWidget {
  const _GridColumnPicker({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Columns per row',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [2, 3, 4, 5, 6].map((n) {
              final selected = current == n;
              return GestureDetector(
                onTap: () => onChanged(n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: selected
                        ? const LinearGradient(colors: AppColors.heroGradient)
                        : null,
                    color: selected ? null : AppColors.glassDark,
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$n',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'cols',
                        style: TextStyle(
                          color: selected
                              ? Colors.white70
                              : AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Supported Formats Card ───────────────────────────────
class _FormatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.accent.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Images',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: AppConstants.supportedImageFormats
                .take(12)
                .map((f) => _FormatChip(f))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Videos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: AppConstants.supportedVideoFormats
                .map((f) => _FormatChip(f))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip(this.format);
  final String format;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Text(
        format.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── About Card ───────────────────────────────────────────
class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        colors: [Color(0x1A6C63FF), Color(0x1A00D9FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: AppColors.heroGradient,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lumina Gallery',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 16),
          const Text(
            '✦ Pure Privacy — Digital Sovereignty\n'
            '🔒 Vault-protected privacy. No cloud. No tracking.\n'
            '📡 LAN Share gives a cloud-like experience, locally.\n'
            '⚡ Lightning-fast gallery with gesture controls.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
