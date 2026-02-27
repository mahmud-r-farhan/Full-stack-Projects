import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../providers/vault_provider.dart';

// ═══════════════════════════════════════════════════════════
//  Vault Screen — Biometric gate + hidden media grid
// ═══════════════════════════════════════════════════════════

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: switch (vaultState.authState) {
          VaultAuthState.locked || VaultAuthState.error => _LockedView(
            errorMessage: vaultState.errorMessage,
          ),
          VaultAuthState.unlocking => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accentWarm),
                SizedBox(height: 20),
                Text(
                  'Authenticating…',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          VaultAuthState.unlocked => _UnlockedView(state: vaultState),
        },
      ),
    );
  }
}

// ─── Locked View ─────────────────────────────────────────
class _LockedView extends ConsumerWidget {
  const _LockedView({this.errorMessage});
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Vault icon
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.vaultGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentWarm.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              )
              .animate()
              .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 32),
          GradientText(
            'The Vault',
            gradient: const LinearGradient(colors: AppColors.vaultGradient),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your most private moments, protected by biometrics or device PIN.\nNothing stored here is visible to other apps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ],
          const SizedBox(height: 40),
          GlassButton(
            label: 'Unlock Vault',
            icon: Icons.fingerprint_rounded,
            gradient: const LinearGradient(colors: AppColors.vaultGradient),
            width: double.infinity,
            onPressed: () => ref.read(vaultProvider.notifier).authenticate(),
          ).animate().slideY(begin: 0.3).fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          GlassContainer(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Biometrics, PIN, or pattern accepted',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 20),
          // Privacy assurance
          const Text(
            '🛡️ Pure Privacy — Digital Sovereignty',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

// ─── Unlocked View ────────────────────────────────────────
class _UnlockedView extends ConsumerWidget {
  const _UnlockedView({required this.state});
  final VaultState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Icon(
                Icons.lock_open_rounded,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 10),
              GradientText(
                'Vault',
                gradient: const LinearGradient(colors: AppColors.vaultGradient),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // Count badge
              if (state.assets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentWarm.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.assets.length}',
                    style: const TextStyle(
                      color: AppColors.accentWarm,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              // Lock button
              GlassContainer(
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onTap: () => ref.read(vaultProvider.notifier).lock(),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: AppColors.accentWarm,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Lock',
                      style: TextStyle(
                        color: AppColors.accentWarm,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: state.assets.isEmpty
              ? EmptyState(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'Vault is Empty',
                  subtitle:
                      'Long-press any photo in your gallery and select "Move to Vault" to hide it here.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: state.assets.length,
                  itemBuilder: (ctx, i) {
                    final a = state.assets[i];
                    return _VaultTile(
                      key: ValueKey(a.id),
                      asset: a,
                      onRemove: () =>
                          ref.read(vaultProvider.notifier).removeAsset(a.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Vault Tile ───────────────────────────────────────────
class _VaultTile extends StatefulWidget {
  const _VaultTile({super.key, required this.asset, required this.onRemove});
  final MediaAsset asset;
  final VoidCallback onRemove;

  @override
  State<_VaultTile> createState() => _VaultTileState();
}

class _VaultTileState extends State<_VaultTile> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.asset.entity.thumbnailDataWithSize(
      const ThumbnailSize.square(200),
      quality: 80,
    );
    if (mounted) setState(() => _thumb = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumb != null)
            Image.memory(_thumb!, fit: BoxFit.cover)
          else
            Container(color: const Color(0xFF1A1A2E)),
          // Vault overlay tint
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accentWarm.withValues(alpha: 0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Lock badge
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.lock_rounded,
              color: AppColors.accentWarm,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.lock_open_rounded,
                color: AppColors.success,
              ),
              title: const Text(
                'Remove from Vault',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Move back to main gallery',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () {
                widget.onRemove();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
