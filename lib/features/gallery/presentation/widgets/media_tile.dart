import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  MediaTile — blazing-fast thumbnail cell
//  Uses AssetEntity.thumbnailData (micro-render strategy)
//  Runs within GridView.builder for lazy rendering.
// ═══════════════════════════════════════════════════════════

class MediaTile extends StatefulWidget {
  const MediaTile({
    super.key,
    required this.asset,
    required this.index,
    required this.onTap,
  });

  final MediaAsset asset;
  final int index;
  final VoidCallback onTap;

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _thumb;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true; // Keep rendered cells in memory

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    // Thumbnail generation is already fast but we keep it off-frame
    // by awaiting after the first frame builds
    await Future.delayed(Duration(milliseconds: widget.index < 30 ? 0 : 16));
    if (!mounted) return;

    final bytes = await widget.asset.entity.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 80,
      format: ThumbnailFormat.jpeg,
    );
    if (mounted) {
      setState(() {
        _thumb = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ext = Theme.of(context).extension<LiquidThemeExtension>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = (ext?.isLiquidDesign ?? true) ? 16.0 : 4.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail image
            if (_loading)
              Container(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.black.withValues(alpha: 0.05),
              )
            else if (_thumb != null)
              Image.memory(_thumb!, fit: BoxFit.cover, gaplessPlayback: true)
            else
              Container(
                color: isDark
                    ? const Color(0xFF12121F)
                    : Colors.black.withValues(alpha: 0.08),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: isDark
                      ? AppColors.textMuted
                      : AppColors.textMutedLight,
                ),
              ),

            // ── Video overlay badge
            if (widget.asset.type == AssetType.video)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatDuration(widget.asset.videoDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Vaulted indicator
            if (widget.asset.isVaulted)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.accentWarm,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
