import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../services/vault_service.dart';

// ═══════════════════════════════════════════════════════════
//  Vault Providers — Enhanced with add/remove functionality
// ═══════════════════════════════════════════════════════════

final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

// Get available assets that can be added to vault
final selectableAssetsProvider = FutureProvider<List<MediaAsset>>((ref) async {
  try {
    final service = ref.watch(vaultServiceProvider);
    return await service.getSelectableAssets();
  } catch (e) {
    return [];
  }
});

// Get vault statistics
final vaultStatsProvider = FutureProvider<VaultStats>((ref) async {
  final service = ref.watch(vaultServiceProvider);
  return await service.getVaultStats();
});

class VaultNotifier extends Notifier<VaultState> {
  @override
  VaultState build() => VaultState.initial;

  Future<void> authenticate() async {
    state = state.copyWith(
      authState: VaultAuthState.unlocking,
      errorMessage: null,
    );

    final service = ref.read(vaultServiceProvider);
    final (success, errorMsg) = await service.authenticateWithDetails();

    if (!success) {
      state = state.copyWith(
        authState: VaultAuthState.error,
        errorMessage: errorMsg ?? 'Authentication failed. Try again.',
      );
      return;
    }

    // Auth successful — load vault assets
    try {
      final assets = await service.loadVaultAssets();
      state = VaultState(authState: VaultAuthState.unlocked, assets: assets);
    } catch (e) {
      state = VaultState(authState: VaultAuthState.unlocked, assets: const []);
    }
  }

  Future<void> addAsset(MediaAsset asset) async {
    try {
      final service = ref.read(vaultServiceProvider);
      await service.addToVault(asset);
      if (state.isUnlocked) {
        state = state.copyWith(assets: [...state.assets, asset]);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add to vault: $e',
      );
    }
  }

  Future<void> addMultipleAssets(List<MediaAsset> assets) async {
    try {
      final service = ref.read(vaultServiceProvider);
      for (final asset in assets) {
        await service.addToVault(asset);
      }
      if (state.isUnlocked) {
        state = state.copyWith(assets: [...state.assets, ...assets]);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add assets to vault: $e',
      );
    }
  }

  Future<void> removeAsset(String assetId) async {
    try {
      final service = ref.read(vaultServiceProvider);
      await service.removeFromVault(assetId);
      if (state.isUnlocked) {
        state = state.copyWith(
          assets: state.assets.where((a) => a.id != assetId).toList(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to remove from vault: $e',
      );
    }
  }

  void lock() {
    state = VaultState.initial;
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, VaultState>(
  VaultNotifier.new,
);
