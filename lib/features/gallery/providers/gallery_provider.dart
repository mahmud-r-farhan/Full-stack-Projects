import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/media_repository.dart';

// ═══════════════════════════════════════════════════════════
//  Gallery Providers — Riverpod
// ═══════════════════════════════════════════════════════════

// ─── Repository singleton ────────────────────────────────
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository();
});

// ─── Permission state ────────────────────────────────────
final permissionProvider = FutureProvider<PermissionState>((ref) async {
  final repo = ref.read(mediaRepositoryProvider);
  return repo.getPermissionState();
});

// ─── All albums ──────────────────────────────────────────
final albumsProvider = FutureProvider<List<AssetPathEntity>>((ref) async {
  final repo = ref.read(mediaRepositoryProvider);
  return repo.loadAlbums();
});

// ─── Selected album ──────────────────────────────────────
final selectedAlbumProvider = StateProvider<AssetPathEntity?>((ref) => null);

// ─── Filter type ─────────────────────────────────────────
final mediaFilterProvider = StateProvider<AssetType?>((ref) => null);

// ─── Gallery Notifier (paginated) ────────────────────────
class GalleryNotifier extends AsyncNotifier<List<MediaAsset>> {
  int _currentPage = 0;
  bool _hasMore = true;
  AssetPathEntity? _activeAlbum;

  @override
  Future<List<MediaAsset>> build() async {
    return _loadInitial();
  }

  Future<List<MediaAsset>> _loadInitial() async {
    _currentPage = 0;
    _hasMore = true;
    final repo = ref.read(mediaRepositoryProvider);
    final albums = await repo.loadAlbums();
    if (albums.isEmpty) return [];
    _activeAlbum = albums.first;
    final assets = await repo.loadPage(album: _activeAlbum!, page: 0);
    _currentPage = 1;
    _hasMore = assets.length >= 100;
    return assets;
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || state is AsyncLoading) return;
    if (_activeAlbum == null) return;
    final current = state.valueOrNull ?? [];
    final repo = ref.read(mediaRepositoryProvider);
    final newAssets = await repo.loadPage(
      album: _activeAlbum!,
      page: _currentPage,
    );
    if (newAssets.isEmpty) {
      _hasMore = false;
      return;
    }
    _currentPage++;
    _hasMore = newAssets.length >= 100;
    state = AsyncData([...current, ...newAssets]);
  }

  Future<void> switchAlbum(AssetPathEntity album) async {
    _activeAlbum = album;
    state = const AsyncLoading();
    _currentPage = 0;
    _hasMore = true;
    final repo = ref.read(mediaRepositoryProvider);
    final assets = await repo.loadPage(album: album, page: 0);
    _currentPage = 1;
    _hasMore = assets.length >= 100;
    state = AsyncData(assets);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadInitial());
  }

  bool get hasMore => _hasMore;
}

final galleryProvider =
    AsyncNotifierProvider<GalleryNotifier, List<MediaAsset>>(
      GalleryNotifier.new,
    );

// ─── Date-grouped gallery ────────────────────────────────
final groupedGalleryProvider = FutureProvider<List<MediaGroup>>((ref) async {
  final assets = ref.watch(galleryProvider).valueOrNull ?? [];
  if (assets.isEmpty) return [];
  final repo = ref.read(mediaRepositoryProvider);
  return repo.groupByDate(assets);
});

// ─── Filtered gallery ────────────────────────────────────
final filteredGalleryProvider = Provider<List<MediaAsset>>((ref) {
  final assets = ref.watch(galleryProvider).valueOrNull ?? [];
  final filter = ref.watch(mediaFilterProvider);
  if (filter == null) return assets;
  return assets.where((a) => a.type == filter).toList();
});
