import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

// ═══════════════════════════════════════════════════════════
//  Media Repository — wraps photo_manager safely
//  Rule: NEVER use direct file system traversal for media.
// ═══════════════════════════════════════════════════════════

class MediaRepository {
  static const int _pageSize = AppConstants.gridBatchSize;

  // ─── Permission ───────────────────────────────────────────

  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth;
  }

  Future<PermissionState> getPermissionState() async {
    return PhotoManager.requestPermissionExtend();
  }

  // ─── Load albums ─────────────────────────────────────────

  Future<List<AssetPathEntity>> loadAlbums({
    RequestType type = RequestType.common,
  }) async {
    return PhotoManager.getAssetPathList(type: type, hasAll: true);
  }

  // ─── Paginated asset loading ──────────────────────────────
  //  Runs on an isolate via compute() to avoid blocking the UI thread.

  Future<List<MediaAsset>> loadPage({
    required AssetPathEntity album,
    required int page,
    int pageSize = _pageSize,
  }) async {
    final entities = await album.getAssetListPaged(page: page, size: pageSize);
    // Map to our domain model off the main isolate
    return compute(_mapEntities, entities);
  }

  // ─── Thumbnail (micro-render, blazing fast) ───────────────

  Future<Uint8List?> getThumbnail(
    AssetEntity entity, {
    int width = 200,
    int height = 200,
  }) async {
    return entity.thumbnailDataWithSize(
      ThumbnailSize(width, height),
      quality: 80,
      format: ThumbnailFormat.jpeg,
    );
  }

  // ─── Full-size data ───────────────────────────────────────

  Future<Uint8List?> getFullData(AssetEntity entity) async {
    return entity.originBytes;
  }

  // ─── Group by date (off main thread) ─────────────────────

  Future<List<MediaGroup>> groupByDate(List<MediaAsset> assets) async {
    return compute(_groupByDate, assets);
  }

  // ─── Latest assets for home grid ─────────────────────────

  Future<List<MediaAsset>> loadRecent({int count = 60}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
    if (albums.isEmpty) return [];
    final all = albums.first;
    final entities = await all.getAssetListPaged(page: 0, size: count);
    return compute(_mapEntities, entities);
  }

  // ─── Total asset count ────────────────────────────────────

  Future<int> getTotalCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
    if (albums.isEmpty) return 0;
    return await albums.first.assetCountAsync;
  }

  // ─── Isolate-safe static helpers ─────────────────────────

  static List<MediaAsset> _mapEntities(List<AssetEntity> entities) {
    return entities.map((e) => MediaAsset(entity: e)).toList();
  }

  static List<MediaGroup> _groupByDate(List<MediaAsset> assets) {
    final Map<String, List<MediaAsset>> grouped = {};
    for (final asset in assets) {
      final dt = asset.createDateTime;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(asset);
    }
    final groups = grouped.entries.map((e) {
      final parts = e.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return MediaGroup(date: date, assets: e.value);
    }).toList();
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }
}
