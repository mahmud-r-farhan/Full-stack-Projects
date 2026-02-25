import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models.dart';
import '../../../../features/settings/providers/settings_provider.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../providers/gallery_provider.dart';
import '../widgets/media_tile.dart';

// ═══════════════════════════════════════════════════════════
//  Gallery Screen — Timeline with paginated GridView.builder
// ═══════════════════════════════════════════════════════════

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, ref, filter),
                Expanded(
                  child: galleryState.when(
                    loading: () => const _GalleryShimmer(),
                    error: (e, _) => _buildPermissionError(context, ref),
                    data: (assets) {
                      final displayed = filter == null
                          ? assets
                          : assets.where((a) => a.type == filter).toList();
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
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            ref.read(galleryProvider.notifier).refresh(),
                        child: GridView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(
                            4,
                            4,
                            4,
                            120,
                          ), // space for nav
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: settings.gridColumns,
                                crossAxisSpacing: AppConstants.gridSpacing,
                                mainAxisSpacing: AppConstants.gridSpacing,
                              ),
                          itemCount: displayed.length,
                          itemBuilder: (ctx, i) {
                            final asset = displayed[i];
                            return MediaTile(
                              key: ValueKey(asset.id),
                              asset: asset,
                              index: i,
                              onTap: () => _openViewer(context, displayed, i),
                            );
                          },
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
                            duration: const Duration(milliseconds: 400),
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
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AssetType? filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientText(
                'Gallery',
                gradient: const LinearGradient(colors: AppColors.heroGradient),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // Album picker
              GlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onTap: () => _showAlbumPicker(context),
                child: Row(
                  children: const [
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
          'LiquidSync needs permission to read your photos and videos. We never upload anything.',
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
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Albums', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...albums.map(
              (a) => ListTile(
                leading: const Icon(
                  Icons.photo_album_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  a.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: FutureBuilder<int>(
                  future: a.assetCountAsync,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? '...';
                    return Text(
                      '$count items',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                onTap: () {
                  ref.read(galleryProvider.notifier).switchAlbum(a);
                  Navigator.pop(ctx);
                },
              ),
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
          ),
        ),
      ),
    );
  }
}

// ─── Media Viewer Screen ──────────────────────────────────
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  final List<MediaAsset> assets;
  final int initialIndex;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;
  bool _showUi = true;

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
                return _MediaPage(asset: asset);
              },
            ),
            // Top bar
            AnimatedOpacity(
              opacity: _showUi ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPage extends StatefulWidget {
  const _MediaPage({required this.asset});
  final MediaAsset asset;

  @override
  State<_MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<_MediaPage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.asset.entity.originBytes;
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
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
