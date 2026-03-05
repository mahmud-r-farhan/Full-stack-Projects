import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models.dart';
import '../../../../features/settings/providers/settings_provider.dart';
import '../../../../features/vault/providers/vault_provider.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../providers/gallery_provider.dart';
import '../widgets/media_tile.dart';

// ═══════════════════════════════════════════════════════════
//  Gallery Screen — Pinch-to-zoom grid + Album thumbnails
// ═══════════════════════════════════════════════════════════

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showFab = false;
  bool _sidebarOpen = true;

  // Pinch-to-zoom state
  double _baseScale = 1.0;
  int _pendingColumns = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Check if device is mobile/tablet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSidebarVisibility();
    });
  }

  void _updateSidebarVisibility() {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) {
      // Mobile: hide sidebar by default
      if (mounted && _sidebarOpen) {
        setState(() => _sidebarOpen = false);
      }
    }
  }

  void _onScroll() {
    // Infinite pagination — load next batch when near bottom
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      ref.read(galleryProvider.notifier).loadNextPage();
    }
    // FAB visibility
    final show = _scrollCtrl.offset > 300;
    if (show != _showFab) setState(() => _showFab = show);
  }

  void _onScaleStart(ScaleStartDetails details) {
    final settings = ref.read(appSettingsProvider);
    _baseScale = settings.gridColumns.toDouble();
    _pendingColumns = settings.gridColumns;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Inverted: pinch-in (zoom out) = more columns, pinch-out (zoom in) = fewer columns
    final newColumns = (_baseScale / details.scale).round().clamp(
      AppConstants.gridCrossAxisCountMin,
      AppConstants.gridCrossAxisCountMax,
    );
    if (newColumns != _pendingColumns) {
      _pendingColumns = newColumns;
      HapticFeedback.selectionClick();
      ref.read(appSettingsProvider.notifier).setGridColumns(newColumns);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);
    final filter = ref.watch(mediaFilterProvider);
    final settings = ref.watch(appSettingsProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Sidebar with albums (responsive) — desktop only
                if (!isMobile) _buildSidebar(context, ref, settings),
                // Main content
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(
                            context,
                            ref,
                            filter,
                            settings,
                            isMobile,
                          ),
                          Expanded(
                            child: galleryState.when(
                              loading: () => const _GalleryShimmer(),
                              error: (e, _) =>
                                  _buildPermissionError(context, ref),
                              data: (assets) {
                                final displayed = filter == null
                                    ? assets
                                    : assets
                                          .where((a) => a.type == filter)
                                          .toList();
                                if (displayed.isEmpty) {
                                  return EmptyState(
                                    icon: Icons.photo_library_outlined,
                                    title: 'No Media Found',
                                    subtitle:
                                        'Your gallery appears empty or media access is restricted.',
                                    action: GlassButton(
                                      label: 'Grant Access',
                                      icon: Icons.lock_open_rounded,
                                      onPressed: () async {
                                        await PhotoManager.openSetting();
                                      },
                                    ),
                                  );
                                }
                                return GestureDetector(
                                  onScaleStart: _onScaleStart,
                                  onScaleUpdate: _onScaleUpdate,
                                  child: RefreshIndicator(
                                    color: AppColors.primary,
                                    onRefresh: () => ref
                                        .read(galleryProvider.notifier)
                                        .refresh(),
                                    child: GridView.builder(
                                      controller: _scrollCtrl,
                                      padding: EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        120,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                settings.gridColumns,
                                            crossAxisSpacing:
                                                AppConstants.gridSpacing,
                                            mainAxisSpacing:
                                                AppConstants.gridSpacing,
                                          ),
                                      itemCount: displayed.length,
                                      itemBuilder: (ctx, i) {
                                        final asset = displayed[i];
                                        return MediaTile(
                                          key: ValueKey(asset.id),
                                          asset: asset,
                                          index: i,
                                          onTap: () => _openViewer(
                                            context,
                                            displayed,
                                            i,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // Scroll to top FAB
                      if (_showFab)
                        Positioned(
                          bottom: 110,
                          right: 20,
                          child:
                              GlassContainer(
                                    borderRadius: 20,
                                    padding: const EdgeInsets.all(12),
                                    onTap: () => _scrollCtrl.animateTo(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  )
                                  .animate()
                                  .scale(begin: const Offset(0, 0))
                                  .fadeIn(duration: 200.ms),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Mobile sidebar overlay — positioned on top with proper z-index
            if (isMobile && _sidebarOpen)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: 0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: _buildSidebar(context, ref, settings),
                    ),
                    // Scrim/overlay to close sidebar
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _sidebarOpen = false),
                        child: Container(color: Colors.black26),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      width: isMobile ? 280 : 260,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(
            color: AppColors.glassBorder.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_album_outlined,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Albums',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isMobile)
                  GestureDetector(
                    onTap: () => setState(() => _sidebarOpen = false),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.glassBorder,
            height: 0.5,
            thickness: 0.5,
          ),
          // Albums list
          Expanded(
            child: FutureBuilder<List<AssetPathEntity>>(
              future: PhotoManager.getAssetPathList(
                type: RequestType.common,
                onlyAll: false,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                final albums = snapshot.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: albums.length,
                  itemBuilder: (ctx, i) => _AlbumSidebarItem(
                    album: albums[i],
                    onTap: () {
                      ref.read(galleryProvider.notifier).switchAlbum(albums[i]);
                      // Close sidebar on mobile after selection
                      if (MediaQuery.of(context).size.width < 768) {
                        setState(() => _sidebarOpen = false);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AssetType? filter,
    AppSettings settings,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMobile)
                GestureDetector(
                  onTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GlassContainer(
                      borderRadius: 10,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: GradientText(
                  'Gallery',
                  gradient: const LinearGradient(
                    colors: AppColors.heroGradient,
                  ),
                  style: TextStyle(
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                     
                      const SizedBox(width: 8),
                      // Album picker
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        onTap: () => _showAlbumPicker(context),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.photo_album_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Albums',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () =>
                      ref.read(mediaFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Photos',
                  icon: Icons.image_outlined,
                  selected: filter == AssetType.image,
                  onTap: () => ref.read(mediaFilterProvider.notifier).state =
                      AssetType.image,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Videos',
                  icon: Icons.videocam_outlined,
                  selected: filter == AssetType.video,
                  onTap: () => ref.read(mediaFilterProvider.notifier).state =
                      AssetType.video,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionError(BuildContext context, WidgetRef ref) {
    return EmptyState(
      icon: Icons.lock_outline_rounded,
      title: 'Media Access Needed',
      subtitle:
          'Lumina Gallery needs permission to read your photos and videos. We never upload anything.',
      action: GlassButton(
        label: 'Open Settings',
        icon: Icons.settings_rounded,
        onPressed: () async {
          await PhotoManager.openSetting();
          ref.invalidate(galleryProvider);
        },
      ),
    );
  }

  void _openViewer(BuildContext context, List<MediaAsset> assets, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) =>
            MediaViewerScreen(assets: assets, initialIndex: index),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showAlbumPicker(BuildContext context) {
    final albums = ref.read(albumsProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => GlassContainer(
          borderRadius: 24,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Albums', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: albums.length,
                  itemBuilder: (ctx, i) {
                    final album = albums[i];
                    return _AlbumListTile(
                      album: album,
                      onTap: () {
                        ref.read(galleryProvider.notifier).switchAlbum(album);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Album List Tile with thumbnail ──────────────────────
class _AlbumListTile extends StatefulWidget {
  const _AlbumListTile({required this.album, required this.onTap});
  final AssetPathEntity album;
  final VoidCallback onTap;

  @override
  State<_AlbumListTile> createState() => _AlbumListTileState();
}

class _AlbumListTileState extends State<_AlbumListTile> {
  Uint8List? _coverThumb;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    try {
      final count = await widget.album.assetCountAsync;
      if (count > 0) {
        final assets = await widget.album.getAssetListPaged(page: 0, size: 1);
        if (assets.isNotEmpty) {
          final thumb = await assets.first.thumbnailDataWithSize(
            const ThumbnailSize(120, 120),
            quality: 75,
            format: ThumbnailFormat.jpeg,
          );
          if (mounted) {
            setState(() {
              _coverThumb = thumb;
              _count = count;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _count = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.glassDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Album cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _coverThumb != null
                    ? Image.memory(_coverThumb!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.darkCard,
                        child: const Icon(
                          Icons.photo_album_outlined,
                          color: AppColors.textMuted,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.name.isEmpty
                        ? 'All Photos'
                        : widget.album.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_count items',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: AppColors.heroGradient)
              : null,
          color: selected ? null : AppColors.glassDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.glassBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Album Sidebar Item ──────────────────────────────────
class _AlbumSidebarItem extends StatefulWidget {
  const _AlbumSidebarItem({required this.album, required this.onTap});
  final AssetPathEntity album;
  final VoidCallback onTap;

  @override
  State<_AlbumSidebarItem> createState() => _AlbumSidebarItemState();
}

class _AlbumSidebarItemState extends State<_AlbumSidebarItem> {
  Uint8List? _coverThumb;
  int _count = 0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    try {
      final count = await widget.album.assetCountAsync;
      if (count > 0) {
        final assets = await widget.album.getAssetListPaged(page: 0, size: 1);
        if (assets.isNotEmpty) {
          final thumb = await assets.first.thumbnailDataWithSize(
            const ThumbnailSize(80, 80),
            quality: 70,
            format: ThumbnailFormat.jpeg,
          );
          if (mounted) {
            setState(() {
              _coverThumb = thumb;
              _count = count;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _count = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovering
                ? AppColors.glassDark.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovering ? AppColors.glassBorder : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Album cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: _coverThumb != null
                      ? Image.memory(_coverThumb!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.darkCard,
                          child: const Icon(
                            Icons.photo_album_outlined,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.album.name.isEmpty
                          ? 'All Photos'
                          : widget.album.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_count',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────
class _GalleryShimmer extends StatefulWidget {
  const _GalleryShimmer();

  @override
  State<_GalleryShimmer> createState() => _GalleryShimmerState();
}

class _GalleryShimmerState extends State<_GalleryShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 30,
        itemBuilder: (ctx, i) => Container(
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF1A1A2E),
              const Color(0xFF2A2A3E),
              _ctrl.value,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Media Viewer Screen — Full-screen image + video player
// ═══════════════════════════════════════════════════════════

class MediaViewerScreen extends ConsumerStatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  final List<MediaAsset> assets;
  final int initialIndex;

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;
  bool _showUi = true;
  bool _isAddingToVault = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsset = widget.assets[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showUi = !_showUi),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.assets.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (ctx, i) {
                final asset = widget.assets[i];
                if (asset.type == AssetType.video) {
                  return _VideoPage(asset: asset);
                }
                return _ImagePage(asset: asset);
              },
            ),
            // Top bar
            AnimatedOpacity(
              opacity: _showUi ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showUi,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        GlassContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(10),
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_currentIndex + 1} / ${widget.assets.length}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info button
                        GlassContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(10),
                          onTap: () => _showMediaInfo(context, currentAsset),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom bar with actions
            AnimatedOpacity(
              opacity: _showUi ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showUi,
                child: Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: () => _shareMedia(currentAsset),
                          ),
                          _ActionButton(
                            icon: Icons.lock_outline_rounded,
                            label: 'Vault',
                            onTap: _isAddingToVault ? null : () => _addToVault(context, currentAsset),
                            isLoading: _isAddingToVault,
                          ),
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            onTap: () => _deleteMedia(context, currentAsset),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaInfo(BuildContext context, MediaAsset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Media Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow('Type', asset.type == AssetType.video ? 'Video' : 'Image'),
            _InfoRow('Resolution', '${asset.width} × ${asset.height}'),
            _InfoRow(
              'Date',
              '${asset.createDateTime.day}/${asset.createDateTime.month}/${asset.createDateTime.year} '
                  '${asset.createDateTime.hour}:${asset.createDateTime.minute.toString().padLeft(2, '0')}',
            ),
            if (asset.type == AssetType.video && asset.videoDuration != null)
              _InfoRow('Duration', _formatDuration(asset.videoDuration!)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareMedia(MediaAsset asset) async {
    // Basic share via file
    final file = await asset.entity.originFile;
    if (file != null && mounted) {
      // Use platform-specific share
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing to share...')));
    }
  }

  Future<void> _addToVault(BuildContext context, MediaAsset asset) async {
    setState(() => _isAddingToVault = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(vaultProvider.notifier).addAsset(asset);
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Added to Vault',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentWarm,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add to Vault: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToVault = false);
    }
  }

  Future<void> _deleteMedia(BuildContext context, MediaAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Media?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will move the file to your device\'s trash/recycle bin.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await PhotoManager.editor.deleteWithIds([asset.id]);
      if (result.isNotEmpty && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─── Image Page with InteractiveViewer ────────────────────
class _ImagePage extends StatefulWidget {
  const _ImagePage({required this.asset});
  final MediaAsset asset;

  @override
  State<_ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<_ImagePage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // First load a higher-quality thumbnail quickly
    final thumb = await widget.asset.entity.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
      quality: 90,
      format: ThumbnailFormat.jpeg,
    );
    if (mounted && thumb != null) {
      setState(() {
        _bytes = thumb;
        _loading = false;
      });
    }

    // Then load full resolution in background
    final fullBytes = await widget.asset.entity.originBytes;
    if (mounted && fullBytes != null) {
      setState(() => _bytes = fullBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_bytes == null) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMuted,
          size: 64,
        ),
      );
    }
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(child: Image.memory(_bytes!, fit: BoxFit.contain)),
    );
  }
}

// ─── Video Page with Chewie player ────────────────────────
class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.asset});
  final MediaAsset asset;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final file = await widget.asset.entity.originFile;
      if (file == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Could not load video file.';
          });
        }
        return;
      }

      _videoCtrl = VideoPlayerController.file(file);
      await _videoCtrl!.initialize();

      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true,
        looping: false,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.accent,
          backgroundColor: AppColors.glassDark,
          bufferedColor: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
        errorBuilder: (ctx, errorMsg) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Playback Error',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                errorMsg,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unsupported video format.';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading video…',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: AppColors.textMuted,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_chewieCtrl != null) {
      return Chewie(controller: _chewieCtrl!);
    }

    return const SizedBox.shrink();
  }
}

// ─── Action Button ────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: isLoading ? null : onTap,
        child: AnimatedOpacity(
          opacity: isLoading ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info Row Widget ──────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
