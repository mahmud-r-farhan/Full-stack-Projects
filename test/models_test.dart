import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:liquidsync_gallery/data/models/models.dart';

void main() {
  group('MediaAsset Tests', () {
    test('MediaAsset serialization to/from vault metadata map', () {
      final now = DateTime(2026, 2, 26, 12, 0, 0);
      final asset = MediaAsset(
        customId: 'test_asset_123',
        customType: AssetType.video,
        customCreateDateTime: now,
        customWidth: 1920,
        customHeight: 1080,
        customVideoDuration: const Duration(seconds: 120),
        isVaulted: true,
        vaultFilePath: '/path/to/vault/file.mp4',
        vaultThumbPath: '/path/to/vault/thumb.jpg',
        originalFilePath: '/path/to/original/file.mp4',
      );

      expect(asset.id, 'test_asset_123');
      expect(asset.type, AssetType.video);
      expect(asset.createDateTime, now);
      expect(asset.width, 1920);
      expect(asset.height, 1080);
      expect(asset.videoDuration, const Duration(seconds: 120));

      final map = asset.toVaultMetadataMap();
      expect(map['id'], 'test_asset_123');
      expect(map['type'], 'video');
      expect(map['vaultFilePath'], '/path/to/vault/file.mp4');
      expect(map['vaultThumbPath'], '/path/to/vault/thumb.jpg');
      expect(map['originalFilePath'], '/path/to/original/file.mp4');

      final reconstructed = MediaAsset.fromVaultMetadataMap(map);
      expect(reconstructed.id, asset.id);
      expect(reconstructed.type, asset.type);
      expect(reconstructed.createDateTime, asset.createDateTime);
      expect(reconstructed.width, asset.width);
      expect(reconstructed.height, asset.height);
      expect(reconstructed.videoDuration, asset.videoDuration);
      expect(reconstructed.vaultFilePath, asset.vaultFilePath);
      expect(reconstructed.vaultThumbPath, asset.vaultThumbPath);
      expect(reconstructed.originalFilePath, asset.originalFilePath);
    });

    test('MediaGroup formattedDate returns correct string', () {
      final now = DateTime.now();
      final todayGroup = MediaGroup(date: now, assets: []);
      expect(todayGroup.formattedDate, 'Today');

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayGroup = MediaGroup(date: yesterday, assets: []);
      expect(yesterdayGroup.formattedDate, 'Yesterday');
    });
  });

  group('AppSettings Tests', () {
    test('AppSettings copyWith works correctly', () {
      const settings = AppSettings();
      expect(settings.isDarkMode, true);
      expect(settings.gridColumns, 3);

      final updated = settings.copyWith(isDarkMode: false, gridColumns: 4);
      expect(updated.isDarkMode, false);
      expect(updated.gridColumns, 4);
      expect(updated.isPerformanceMode, false);
    });
  });

  group('VaultStats & Exception Tests', () {
    test('VaultStats size formatting', () {
      const statsBytes = VaultStats(itemCount: 1, totalSize: 500, vaultPath: '/p');
      expect(statsBytes.sizeFormatted, '500 B');

      const statsKb = VaultStats(itemCount: 2, totalSize: 2048, vaultPath: '/p');
      expect(statsKb.sizeFormatted, '2.0 KB');

      const statsMb = VaultStats(itemCount: 5, totalSize: 10485760, vaultPath: '/p');
      expect(statsMb.sizeFormatted, '10.0 MB');
    });

    test('VaultException toString output', () {
      final ex = VaultException('Test error');
      expect(ex.toString(), 'VaultException: Test error');
    });
  });
}
