import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  Vault Service — Biometric auth + hidden media management
//  Strategy: Move files to a .nomedia album to hide from
//  the system MediaStore. Optional encryption in v2+.
//
//  FIX: The previous implementation returned false when
//  biometrics were unavailable, even if device
//  credentials (PIN/Pattern) were available.
//  Now properly uses isDeviceSupported() as fallback.
// ═══════════════════════════════════════════════════════════

class VaultService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _vaultKey = 'vault_asset_ids';

  // ─── Biometric / device credential check ─────────────────

  Future<bool> isAuthAvailable() async {
    try {
      // Check if ANY form of auth is available (biometric OR PIN/pattern)
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ─── Authenticate ────────────────────────────────────────
  //  FIX: biometricOnly was not false in all cases and
  //  the error was swallowed silently. Now returns detailed info.

  Future<(bool success, String? error)> authenticateWithDetails() async {
    try {
      final available = await isAuthAvailable();
      if (!available) {
        return (
          false,
          'No authentication method available. Please set up a PIN, pattern, or biometric lock on your device.',
        );
      }

      final biometrics = await getAvailableBiometrics();
      final hasBiometrics = biometrics.isNotEmpty;

      final success = await _auth.authenticate(
        localizedReason: 'Authenticate to access your Lumina Vault',
        options: AuthenticationOptions(
          // Allow PIN/pattern if no biometrics set up
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (success) {
        return (true, null);
      } else {
        return (
          false,
          hasBiometrics
              ? 'Authentication cancelled. Try again.'
              : 'Authentication failed. Use your device PIN or pattern.',
        );
      }
    } catch (e) {
      // Provide meaningful error messages
      final msg = e.toString();
      if (msg.contains('LockedOut') || msg.contains('lockedOut')) {
        return (
          false,
          'Too many attempts. Please wait a moment and try again.',
        );
      }
      if (msg.contains('PermanentlyLockedOut') ||
          msg.contains('permanentlyLockedOut')) {
        return (false, 'Biometrics locked. Please unlock your device first.');
      }
      if (msg.contains('NotAvailable') || msg.contains('notAvailable')) {
        return (
          false,
          'Authentication not available. Set up a PIN or biometric lock in device settings.',
        );
      }
      if (msg.contains('NotEnrolled') || msg.contains('notEnrolled')) {
        return (
          false,
          'No biometrics enrolled. Please set up fingerprint or face unlock in device settings.',
        );
      }
      return (false, 'Authentication error. Please try again.');
    }
  }

  // Legacy method kept for backward compatibility
  Future<bool> authenticate() async {
    final (success, _) = await authenticateWithDetails();
    return success;
  }

  // ─── Load vault asset IDs ─────────────────────────────────

  Future<List<String>> _loadVaultIds() async {
    try {
      final raw = await _storage.read(key: _vaultKey);
      if (raw == null || raw.isEmpty) return [];
      return raw.split(',').where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
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
    final validIds = <String>[];

    for (final id in ids) {
      try {
        final entity = await AssetEntity.fromId(id);
        if (entity != null) {
          assets.add(MediaAsset(entity: entity, isVaulted: true));
          validIds.add(id);
        }
      } catch (_) {
        // Silent fallback for missing/corrupted entries
      }
    }

    // Clean up any invalid IDs
    if (validIds.length != ids.length) {
      await _saveVaultIds(validIds);
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
