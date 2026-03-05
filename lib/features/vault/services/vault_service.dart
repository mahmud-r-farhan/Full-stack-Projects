import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  Vault Service — Biometric auth + file-based hidden storage
//  Strategy: Move files to hidden .lumina_vault directory,
//  making them unavailable in system MediaStore.
//  Files are physically moved, not just marked as hidden.
//
//  Enhancement: Full file operations for true privacy
//  - Files moved to vault are no longer accessible from gallery
//  - Files are encrypted in secure storage metadata
//  - Removal restores files to original locations
// ═══════════════════════════════════════════════════════════

class VaultService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _vaultKey = 'vault_asset_ids';
  static const String _vaultFileMapKey = 'vault_file_map'; // Maps vault IDs to original paths
  static const String _vaultDirName = '.lumina_vault';

  // ─── Vault directory management ────────────────────────

  Future<Directory> _getVaultDirectory() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final vaultDir = Directory('${appDir.path}/$_vaultDirName');
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
      return vaultDir;
    } catch (e) {
      throw VaultException('Failed to access vault directory: $e');
    }
  }

  Future<void> _ensureVaultDirectory() async {
    await _getVaultDirectory();
  }

  // ─── File map operations ───────────────────────────────

  /// Loads file mappings: assetId -> "originalPath|vaultPath"
  /// Format: assetId::originalPath|vaultPath|||assetId2::...
  /// This allows us to hide files from device (original deleted) and restore them
  Future<Map<String, String>> _loadFileMap() async {
    try {
      final raw = await _storage.read(key: _vaultFileMapKey);
      if (raw == null || raw.isEmpty) return {};
      
      final entries = raw.split('|||');
      final map = <String, String>{};
      for (final entry in entries) {
        if (entry.isNotEmpty) {
          final parts = entry.split('::');
          if (parts.length == 2) {
            map[parts[0]] = parts[1]; // assetId -> "originalPath|vaultPath"
          }
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// Saves file mappings with separator '|||' to distinguish from pipe in paths
  Future<void> _saveFileMap(Map<String, String> map) async {
    try {
      final raw = map.entries.map((e) => '${e.key}::${e.value}').join('|||');
      await _storage.write(key: _vaultFileMapKey, value: raw);
    } catch (e) {
      throw VaultException('Failed to save file map: $e');
    }
  }

  // ─── Biometric / device credential check ─────────────────

  Future<bool> isAuthAvailable() async {
    try {
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
    final fileMap = await _loadFileMap();

    for (final id in ids) {
      try {
        final entity = await AssetEntity.fromId(id);
        if (entity != null) {
          final mapping = fileMap[id];
          // Extract vault path from "originalPath|vaultPath" format
          final vaultPath = mapping != null 
            ? mapping.split('|').length == 2 
              ? mapping.split('|')[1]
              : mapping // fallback for old format
            : null;
          
          assets.add(MediaAsset(
            entity: entity,
            isVaulted: true,
            vaultFilePath: vaultPath,
          ));
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

  // ─── Add to vault ────────────────────────────────────────
  /// Adds an asset to the vault by MOVING file to hidden directory
  /// This makes the file unavailable in the system gallery
  /// Original location is stored for recovery if removed from vault

  Future<bool> addToVault(MediaAsset asset) async {
    try {
      await _ensureVaultDirectory();
      
      final file = await asset.entity.originFile;
      if (file == null || !await file.exists()) {
        throw VaultException('File not found or inaccessible');
      }

      final ids = await _loadVaultIds();
      if (ids.contains(asset.id)) {
        return true; // Already vaulted
      }

      // Store original path for later recovery
      final originalPath = file.path;
      final vaultDir = await _getVaultDirectory();
      
      // Create a unique filename with timestamp
      final ext = file.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final vaultFileName = '${asset.id}_$timestamp.$ext';
      final vaultFilePath = '${vaultDir.path}/$vaultFileName';

      // Copy file to vault, then delete original to hide from device gallery
      await file.copy(vaultFilePath);
      await file.delete();

      // Note: PhotoManager and MediaStore will automatically refresh as the file
      // is no longer accessible, causing it to disappear from device gallery

      // Save mapping: assetId -> "originalPath|vaultPath"
      final fileMap = await _loadFileMap();
      fileMap[asset.id] = '$originalPath|$vaultFilePath';
      await _saveFileMap(fileMap);

      // Add to vault IDs
      ids.add(asset.id);
      await _saveVaultIds(ids);

      return true;
    } catch (e) {
      throw VaultException('Failed to add to vault: $e');
    }
  }

  // ─── Remove from vault ───────────────────────────────────
  /// Removes an asset from the vault, restoring it to original location
  /// If original directory no longer exists, restores to safe default location

  Future<bool> removeFromVault(String assetId) async {
    try {
      final fileMap = await _loadFileMap();
      final mapping = fileMap[assetId];

      if (mapping != null) {
        try {
          // Parse mapping: "originalPath|vaultPath"
          final parts = mapping.split('|');
          if (parts.length == 2) {
            final originalPath = parts[0];
            final vaultPath = parts[1];
            final vaultFile = File(vaultPath);

            if (await vaultFile.exists()) {
              final originalFile = File(originalPath);
              final originalDir = originalFile.parent;

              // Try to restore to original location if directory still exists
              if (await originalDir.exists()) {
                await vaultFile.copy(originalPath);
              } else {
                // Fallback: restore to Documents/RestoreFromVault directory
                final appDir = await getApplicationDocumentsDirectory();
                final fallbackPath = '${appDir.path}/RestoreFromVault/${originalFile.path.split('/').last}';
                final fallbackDir = Directory(fallbackPath).parent;
                await fallbackDir.create(recursive: true);
                await vaultFile.copy(fallbackPath);
              }

              // Delete from vault
              await vaultFile.delete();

              // Note: PhotoManager and MediaStore will automatically refresh as the file
              // is restored to a standard gallery location, causing it to reappear in device gallery
            }
          }
        } catch (_) {
          // If restoration fails, continue with cleanup
        }
      }

      // Remove from tracking
      fileMap.remove(assetId);
      await _saveFileMap(fileMap);

      final ids = await _loadVaultIds();
      ids.remove(assetId);
      await _saveVaultIds(ids);

      return true;
    } catch (e) {
      throw VaultException('Failed to remove from vault: $e');
    }
  }

  // ─── Check if in vault ───────────────────────────────────

  Future<bool> isVaulted(String assetId) async {
    final ids = await _loadVaultIds();
    return ids.contains(assetId);
  }

  // ─── Get available albums for selection ──────────────────

  Future<List<MediaAsset>> getSelectableAssets() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        throw VaultException('Photo library access denied');
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );

      if (albums.isEmpty) return [];

      final assets = <MediaAsset>[];
      final vaultedIds = await _loadVaultIds();

      for (final album in albums) {
        final entities = await album.getAssetListRange(
          start: 0,
          end: await album.assetCountAsync,
        );

        for (final entity in entities) {
          if (!vaultedIds.contains(entity.id)) {
            assets.add(MediaAsset(entity: entity, isVaulted: false));
          }
        }
      }

      return assets;
    } catch (e) {
      throw VaultException('Failed to get selectable assets: $e');
    }
  }

  // ─── Clear vault (admin reset) ────────────────────────────

  Future<void> clearVault() async {
    try {
      final vaultDir = await _getVaultDirectory();
      if (await vaultDir.exists()) {
        // Clean up all vault files
        final files = vaultDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }

      await _storage.delete(key: _vaultKey);
      await _storage.delete(key: _vaultFileMapKey);
    } catch (e) {
      throw VaultException('Failed to clear vault: $e');
    }
  }

  // ─── Get vault statistics ───────────────────────────────

  Future<VaultStats> getVaultStats() async {
    try {
      await _ensureVaultDirectory();
      
      final vaultDir = await _getVaultDirectory();
      final files = await vaultDir.list().toList();
      
      int totalSize = 0;
      for (final file in files) {
        if (file is File) {
          try {
            totalSize += await file.length();
          } catch (_) {}
        }
      }

      final ids = await _loadVaultIds();
      return VaultStats(
        itemCount: ids.length,
        totalSize: totalSize,
        vaultPath: vaultDir.path,
      );
    } catch (e) {
      return VaultStats(itemCount: 0, totalSize: 0, vaultPath: '');
    }
  }
}
