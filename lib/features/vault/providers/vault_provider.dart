import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../services/vault_service.dart';

// ═══════════════════════════════════════════════════════════
//  Vault Providers
// ═══════════════════════════════════════════════════════════

final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());

class VaultNotifier extends Notifier<VaultState> {
  @override
  VaultState build() => VaultState.initial;

  Future<void> authenticate() async {
    state = state.copyWith(authState: VaultAuthState.unlocking);
    final service = ref.read(vaultServiceProvider);
    final success = await service.authenticate();
    if (!success) {
      state = state.copyWith(
        authState: VaultAuthState.error,
        errorMessage: 'Authentication failed. Try again.',
      );
      return;
    }
    final assets = await service.loadVaultAssets();
    state = VaultState(authState: VaultAuthState.unlocked, assets: assets);
  }

  Future<void> addAsset(MediaAsset asset) async {
    final service = ref.read(vaultServiceProvider);
    final ok = await service.addToVault(asset);
    if (ok && state.isUnlocked) {
      state = state.copyWith(assets: [...state.assets, asset]);
    }
  }

  Future<void> removeAsset(String assetId) async {
    final service = ref.read(vaultServiceProvider);
    await service.removeFromVault(assetId);
    if (state.isUnlocked) {
      state = state.copyWith(
        assets: state.assets.where((a) => a.id != assetId).toList(),
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
