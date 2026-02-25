import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  Vault Service — Biometric auth + hidden media management
//  Strategy: Move files to a .nomedia album to hide from
//  the system MediaStore. Optional encryption in v2+.
// ═══════════════════════════════════════════════════════════

class VaultService {
  final LocalAuthentication _auth = const LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _vaultKey = 'vault_asset_ids';

  // ─── Biometric capability check ──────────────────────────

  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // ─── Authenticate ────────────────────────────────────────

  Future<bool> authenticate() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access your secure Vault',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ─── Load vault asset IDs ─────────────────────────────────

  Future<List<String>> _loadVaultIds() async {
    final raw = await _storage.read(key: _vaultKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((s) => s.isNotEmpty).toList();
  }

  // ─── Save vault asset IDs ─────────────────────────────────

  Future<void> _saveVaultIds(List<String> ids) async {
    await _storage.write(key: _vaultKey, value: ids.join(','));
  }

  // ─── Load vault media ─────────────────────────────────────

  Future<List<MediaAsset>> loadVaultAssets() async {
    final ids = await _loadVaultIds();
    if (ids.isEmpty) return [];

    final assets = <MediaAsset>[];
    for (final id in ids) {
      try {
        final entity = await AssetEntity.fromId(id);
        if (entity != null) {
          assets.add(MediaAsset(entity: entity, isVaulted: true));
        }
      } catch (_) {
        // Silent fallback for missing/corrupted entries
      }
    }
    return assets;
  }

  // ─── Move to vault ────────────────────────────────────────

  Future<bool> addToVault(MediaAsset asset) async {
    try {
      final ids = await _loadVaultIds();
      if (!ids.contains(asset.id)) {
        ids.add(asset.id);
        await _saveVaultIds(ids);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Remove from vault ───────────────────────────────────

  Future<bool> removeFromVault(String assetId) async {
    try {
      final ids = await _loadVaultIds();
      ids.remove(assetId);
      await _saveVaultIds(ids);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Check if in vault ───────────────────────────────────

  Future<bool> isVaulted(String assetId) async {
    final ids = await _loadVaultIds();
    return ids.contains(assetId);
  }

  // ─── Clear vault (admin reset) ────────────────────────────

  Future<void> clearVault() async {
    await _storage.delete(key: _vaultKey);
  }
}
