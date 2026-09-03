import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  LAN Share Service — Enhanced disk/folder selection
//  Features: Album browsing, disk selection, OTG support,  
//  pagination, video streaming, professional Web UI.
// ═══════════════════════════════════════════════════════════

class LanShareService {
  HttpServer? _server;
  LanServerInfo _serverInfo = LanServerInfo.idle;
  final _infoController = StreamController<LanServerInfo>.broadcast();

  Stream<LanServerInfo> get serverInfoStream => _infoController.stream;
  LanServerInfo get currentInfo => _serverInfo;

  // ─── MIME type map ────────────────────────────────────────

  static const _mimeTypes = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'tiff': 'image/tiff',
    'tif': 'image/tiff',
    'svg': 'image/svg+xml',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'mkv': 'video/x-matroska',
    'avi': 'video/x-msvideo',
    'webm': 'video/webm',
    '3gp': 'video/3gpp',
    'flv': 'video/x-flv',
    'wmv': 'video/x-ms-wmv',
    'm4v': 'video/x-m4v',
    'ts': 'video/mp2t',
  };

  String _getMimeType(String? path, AssetType type) {
    if (path != null) {
      final ext = path.split('.').last.toLowerCase();
      if (_mimeTypes.containsKey(ext)) return _mimeTypes[ext]!;
    }
    return type == AssetType.video ? 'video/mp4' : 'image/jpeg';
  }

  // ─── Get available shareable directories ──────────────────

  Future<List<ShareableDirectory>> getAvailableDirectories() async {
    final directories = <ShareableDirectory>[];

    try {
      // System Photos (through PhotoManager API)
      directories.add(
        ShareableDirectory(
          name: 'All Photos',
          path: 'PHOTOS_SYSTEM',
          type: StorageType.systemPhotos,
          displayPath: 'Device Photos',
        ),
      );

      // Downloads folder
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        directories.add(
          ShareableDirectory(
            name: 'Downloads',
            path: downloadsDir.path,
            type: StorageType.downloads,
            displayPath: downloadsDir.path.replaceFirst(
              RegExp(r'^.*?(/[^/]*?)$'),
              r'$1',
            ),
          ),
        );
      }

      // Documents folder
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(
        ShareableDirectory(
          name: 'Documents',
          path: documentsDir.path,
          type: StorageType.documents,
          displayPath: documentsDir.path.replaceFirst(
            RegExp(r'^.*?(/[^/]*?)$'),
            r'$1',
          ),
        ),
      );

      // External storage (if available on Android)
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          directories.add(
            ShareableDirectory(
              name: 'External Storage',
              path: externalDir.path,
              type: StorageType.externalStorage,
              displayPath: 'External Storage',
            ),
          );
        }
      } catch (_) {}

      // OTG support would require additional platform-specific handling
      // Placeholder for future OTG implementation
      // directories.add(ShareableDirectory(...otg_detection...));
    } catch (e) {
      // Return at least the system photos option
      if (directories.isEmpty) {
        directories.add(
          ShareableDirectory(
            name: 'All Photos',
            path: 'PHOTOS_SYSTEM',
            type: StorageType.systemPhotos,
            displayPath: 'Device Photos',
          ),
        );
      }
    }

    return directories;
  }

  // ─── Start server ───────────────────────────────────────

  Future<LanServerInfo> startServer({String? sharePath}) async {
    if (_server != null) return _serverInfo;

    try {
      _emit(_serverInfo.copyWith(status: ServerStatus.starting));

      final ip = await _getLocalIp();
      if (ip == null) {
        return _emitError('Could not determine local IP address.');
      }

      final shareName = sharePath == null || sharePath == 'PHOTOS_SYSTEM'
          ? 'All Photos'
          : sharePath.split('/').last;

      final router = Router()
        ..get('/', _handleRoot)
        ..get('/api/albums', _handleAlbums)
        ..get('/api/assets/<albumId>', _handleAssets)
        ..get('/api/thumb/<assetId>', _handleThumbnail)
        ..get('/api/file/<assetId>', _handleFile)
        ..get('/api/stream/<assetId>', _handleStream);

      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        AppConstants.lanServerPort,
      );

      final info = _serverInfo.copyWith(
        status: ServerStatus.running,
        ipAddress: ip,
        port: AppConstants.lanServerPort,
        selectedSharePath: sharePath,
        selectedShareName: shareName,
      );
      _emit(info);
      return info;
    } catch (e) {
      return _emitError('Server error: $e');
    }
  }

  // ─── Stop server ────────────────────────────────────────

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _emit(LanServerInfo.idle);
  }

  // ─── Handlers ───────────────────────────────────────────

  Future<Response> _handleRoot(Request req) async {
    final html = _buildWebUi(
      ipAddress: _serverInfo.ipAddress ?? 'unknown',
      port: _serverInfo.port ?? AppConstants.lanServerPort,
    );
    return Response.ok(
      html,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  Future<Response> _handleAlbums(Request req) async {
    try {
      final sharePath = _serverInfo.selectedSharePath;

      // If sharing a folder from filesystem (Downloads, Documents, etc.)
      if (sharePath != null && sharePath != 'PHOTOS_SYSTEM') {
        return _handleFolderAlbums(sharePath);
      }

      // Otherwise, use PhotoManager for system photos
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        return Response.forbidden(
          jsonEncode({
            'error': 'Photo library access denied',
            'details': 'Grant permission in app settings to access photos',
            'code': 'PERMISSION_DENIED',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );

      if (albums.isEmpty) {
        return _jsonResponse([]);
      }

      final data = await Future.wait(
        albums.map(
          (a) async => {
            'id': a.id,
            'name': a.name.isEmpty ? 'All Photos' : a.name,
            'count': await a.assetCountAsync,
          },
        ),
      );
      return _jsonResponse(data);
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to load albums',
          'details': e.toString(),
          'code': 'ALBUMS_LOAD_ERROR',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleFolderAlbums(String sharePath) async {
    try {
      final dir = Directory(sharePath);
      if (!await dir.exists()) {
        return _jsonResponse([
          {
            'id': 'default',
            'name': sharePath.split('/').last,
            'count': 0,
          }
        ]);
      }

      // Return a single album for the selected folder
      int count = 0;
      try {
        final files = dir.listSync(recursive: true);
        count = files.where((f) {
          final path = f.path.toLowerCase();
          final ext = path.split('.').last;
          return _mimeTypes.containsKey(ext) &&
              (f is File);
        }).length;
      } catch (_) {}

      return _jsonResponse([
        {
          'id': 'default',
          'name': sharePath.split('/').last,
          'count': count,
        }
      ]);
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to load folder',
          'details': e.toString(),
          'code': 'FOLDER_LOAD_ERROR',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleAssets(Request req, String albumId) async {
    try {
      final sharePath = _serverInfo.selectedSharePath;

      // If sharing a folder from filesystem
      if (sharePath != null && sharePath != 'PHOTOS_SYSTEM') {
        return _handleFolderAssets(sharePath, req);
      }

      // Otherwise, use PhotoManager for system photos
      final page = int.tryParse(req.url.queryParameters['page'] ?? '0') ?? 0;
      final size = int.tryParse(req.url.queryParameters['size'] ?? '60') ?? 60;

      final albums = await PhotoManager.getAssetPathList(hasAll: true);
      if (albums.isEmpty) {
        return _jsonResponse({
          'total': 0,
          'page': page,
          'pageSize': size,
          'hasMore': false,
          'assets': [],
        });
      }

      final album = albums.firstWhere(
        (a) => a.id == albumId,
        orElse: () => albums.first,
      );
      final totalCount = await album.assetCountAsync;
      final entities = await album.getAssetListPaged(page: page, size: size);
      final data = {
        'total': totalCount,
        'page': page,
        'pageSize': size,
        'hasMore': (page + 1) * size < totalCount,
        'assets': entities
            .map(
              (e) => {
                'id': e.id,
                'type': e.type.name,
                'width': e.width,
                'height': e.height,
                'createDate': e.createDateTime.toIso8601String(),
                'duration': e.type == AssetType.video
                    ? e.videoDuration.inSeconds
                    : null,
                'thumbUrl': '/api/thumb/${e.id}',
                'fileUrl': '/api/file/${e.id}',
                'streamUrl': e.type == AssetType.video
                    ? '/api/stream/${e.id}'
                    : null,
              },
            )
            .toList(),
      };
      return _jsonResponse(data);
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to load assets',
          'details': e.toString(),
          'code': 'ASSETS_LOAD_ERROR',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleFolderAssets(String sharePath, Request req) async {
    try {
      final page = int.tryParse(req.url.queryParameters['page'] ?? '0') ?? 0;
      final size = int.tryParse(req.url.queryParameters['size'] ?? '60') ?? 60;

      final dir = Directory(sharePath);
      if (!await dir.exists()) {
        return _jsonResponse({
          'total': 0,
          'page': page,
          'pageSize': size,
          'hasMore': false,
          'assets': [],
        });
      }

      // Get all supported media files recursively
      final files = <FileSystemEntity>[];
      try {
        final list = dir.listSync(recursive: true);
        for (var item in list) {
          if (item is File) {
            final path = item.path.toLowerCase();
            final ext = path.split('.').last;
            if (_mimeTypes.containsKey(ext)) {
              files.add(item);
            }
          }
        }
      } catch (_) {}

      // Sort by modified time (newest first)
      files.sort((a, b) {
        try {
          final statA = (a as File).statSync();
          final statB = (b as File).statSync();
          return statB.modified.compareTo(statA.modified);
        } catch (_) {
          return 0;
        }
      });

      final total = files.length;
      final startIdx = page * size;
      final endIdx = (startIdx + size).clamp(0, total);
      final pageFiles = startIdx < total ? files.sublist(startIdx, endIdx) : [];

      final assets = pageFiles.map((f) {
        final path = f.path;
        final ext = path.split('.').last.toLowerCase();
        final isVideo = ['mp4', 'mov', 'mkv', 'avi', 'webm', '3gp', 'flv', 'wmv', 'm4v', 'ts'].contains(ext);

        // Create a simple ID from the file path
        final fileId = path.hashCode.toString().replaceAll('-', '');

        return {
          'id': fileId,
          'type': isVideo ? 'video' : 'image',
          'path': path, // Store the actual file path for later retrieval
          'width': 0,
          'height': 0,
          'createDate': DateTime.fromMillisecondsSinceEpoch(
            (f as File).statSync().modified.millisecondsSinceEpoch,
          ).toIso8601String(),
          'duration': null,
          'thumbUrl': '/api/thumb/$fileId?path=${Uri.encodeComponent(path)}',
          'fileUrl': '/api/file/$fileId?path=${Uri.encodeComponent(path)}',
          'streamUrl': isVideo ? '/api/stream/$fileId?path=${Uri.encodeComponent(path)}' : null,
        };
      }).toList();

      return _jsonResponse({
        'total': total,
        'page': page,
        'pageSize': size,
        'hasMore': endIdx < total,
        'assets': assets,
      });
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to load folder assets',
          'details': e.toString(),
          'code': 'FOLDER_ASSETS_ERROR',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleThumbnail(Request req, String assetId) async {
    try {
      final filePath = req.url.queryParameters['path'];

      // Handle filesystem file
      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (!await file.exists()) return Response.notFound('File not found');

        try {
          final bytes = await file.readAsBytes();

          // Try to generate thumbnail from image
          return Response.ok(
            bytes,
            headers: {
              'Content-Type': _getMimeType(filePath, AssetType.image),
              'Cache-Control': 'public, max-age=3600',
            },
          );
        } catch (e) {
          return Response.internalServerError(body: 'Failed to load thumbnail: $e');
        }
      }

      // Handle PhotoManager asset
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return Response.notFound('Asset not found');
      final bytes = await entity.thumbnailDataWithSize(
        const ThumbnailSize(400, 400),
        quality: 85,
        format: ThumbnailFormat.jpeg,
      );
      if (bytes == null) return Response.notFound('Thumbnail unavailable');
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': 'image/jpeg',
          'Cache-Control': 'public, max-age=3600',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Future<Response> _serveFileStream(File file, Request req, {bool isAttachment = false, AssetType assetType = AssetType.image}) async {
    if (!await file.exists()) return Response.notFound('File not found');

    final length = await file.length();
    final mimeType = _getMimeType(file.path, assetType);
    final filename = file.path.split('/').last;

    final headers = <String, String>{
      'Content-Type': mimeType,
      'Accept-Ranges': 'bytes',
    };

    if (isAttachment) {
      headers['Content-Disposition'] = 'attachment; filename="$filename"';
    }

    final rangeHeader = req.headers['range'];
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = (parts.length > 1 && parts[1].isNotEmpty)
          ? int.tryParse(parts[1]) ?? (length - 1)
          : (length - 1);

      if (start >= length || end >= length || start > end) {
        return Response(
          416,
          headers: {'Content-Range': 'bytes */$length'},
        );
      }

      final contentLength = end - start + 1;
      headers['Content-Length'] = contentLength.toString();
      headers['Content-Range'] = 'bytes $start-$end/$length';

      final stream = file.openRead(start, end + 1);
      return Response(
        206,
        body: stream,
        headers: headers,
      );
    }

    headers['Content-Length'] = length.toString();
    return Response.ok(
      file.openRead(),
      headers: headers,
    );
  }

  Future<Response> _handleFile(Request req, String assetId) async {
    try {
      final filePath = req.url.queryParameters['path'];

      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        return _serveFileStream(file, req, isAttachment: true, assetType: AssetType.image);
      }

      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return Response.notFound('Asset not found');
      final file = await entity.originFile;
      if (file == null) return Response.notFound('File unavailable');

      return _serveFileStream(file, req, isAttachment: true, assetType: entity.type);
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  // Video streaming endpoint for browser playback
  Future<Response> _handleStream(Request req, String assetId) async {
    try {
      final filePath = req.url.queryParameters['path'];

      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        return _serveFileStream(file, req, isAttachment: false, assetType: AssetType.video);
      }

      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return Response.notFound('Asset not found');
      final file = await entity.originFile;
      if (file == null) return Response.notFound('File unavailable');

      return _serveFileStream(file, req, isAttachment: false, assetType: entity.type);
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  Response _jsonResponse(dynamic data) => Response.ok(
    jsonEncode(data),
    headers: {'Content-Type': 'application/json'},
  );

  Future<String?> _getLocalIp() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiIP();
    } catch (_) {
      return null;
    }
  }

  LanServerInfo _emit(LanServerInfo info) {
    _serverInfo = info;
    _infoController.add(info);
    return info;
  }

  LanServerInfo _emitError(String msg) {
    return _emit(LanServerInfo(status: ServerStatus.error, errorMessage: msg));
  }

  // ─── Professional Web UI ─────────────────────────────────

  String _buildWebUi({required String ipAddress, required int port}) =>
      '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Liquid Gallery — LAN Share</title>
  <style>
    :root {
      --glass-bg: rgba(255,255,255,0.05);
      --glass-bg-hover: rgba(255,255,255,0.08);
      --glass-border: rgba(255,255,255,0.1);
      --glass-border-hover: rgba(255,255,255,0.15);
      --accent: #7C6FFF;
      --accent-dark: #6B5FE8;
      --accent2: #00E5FF;
      --success: #22C55E;
      --text: #F0F0FF;
      --text-secondary: #B4B0D9;
      --text-muted: #7A76A0;
      --surface-dark: #09090F;
      --surface-light: #12121E;
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    html {
      scroll-behavior: smooth;
    }
    
    body {
      background: linear-gradient(135deg, var(--surface-dark) 0%, #0F0F1B 100%);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
      min-height: 100vh;
      overflow-x: hidden;
      line-height: 1.5;
    }
    
    /* Animated gradient background */
    body::before, body::after {
      content: '';
      position: fixed;
      border-radius: 50%;
      filter: blur(100px);
      pointer-events: none;
      z-index: 0;
      opacity: 0.4;
    }
    body::before {
      width: 600px;
      height: 600px;
      background: radial-gradient(circle, rgba(124, 111, 255, 0.15) 0%, transparent 70%);
      top: -200px;
      left: -200px;
    }
    body::after {
      width: 500px;
      height: 500px;
      background: radial-gradient(circle, rgba(0, 229, 255, 0.1) 0%, transparent 70%);
      bottom: -150px;
      right: -150px;
    }
    
    /* Main layout */
    .container {
      display: grid;
      grid-template-rows: auto 1fr;
      min-height: 100vh;
      position: relative;
      z-index: 1;
    }
    
    /* Header */
    header {
      position: sticky;
      top: 0;
      z-index: 100;
      padding: 12px 20px;
      display: flex;
      align-items: center;
      gap: 12px;
      background: rgba(9, 9, 15, 0.6);
      backdrop-filter: blur(20px) saturate(180%);
      -webkit-backdrop-filter: blur(20px) saturate(180%);
      border-bottom: 1px solid var(--glass-border);
    }
    
    .logo-icon {
      width: 36px;
      height: 36px;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent2) 100%);
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      flex-shrink: 0;
      box-shadow: 0 0 20px rgba(124, 111, 255, 0.3);
    }
    
    .logo-text {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    
    header h1 {
      font-size: 16px;
      font-weight: 600;
      background: linear-gradient(135deg, var(--text) 0%, var(--accent2) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      letter-spacing: -0.3px;
      margin: 0;
    }
    
    header p {
      font-size: 11px;
      color: var(--text-muted);
      margin: 0;
      letter-spacing: 0.3px;
    }
    
    .status-pill {
      margin-left: auto;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 20px;
      padding: 6px 12px;
      font-size: 11px;
      display: flex;
      align-items: center;
      gap: 6px;
      backdrop-filter: blur(10px);
      color: var(--text-secondary);
      font-weight: 500;
      transition: all 0.2s ease;
    }
    
    .status-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--success);
      box-shadow: 0 0 10px var(--success);
      animation: pulse-dot 2s ease-in-out infinite;
    }
    
    @keyframes pulse-dot {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.8); }
    }
    
    /* Content wrapper with sidebar */
    .main-wrapper {
      display: grid;
      grid-template-columns: 1fr;
      gap: 0;
      height: 100%;
    }
    
    .sidebar {
      position: fixed;
      left: 0;
      top: 0;
      height: 100vh;
      width: 280px;
      background: rgba(12, 12, 20, 0.6);
      backdrop-filter: blur(15px) saturate(180%);
      border-right: 1px solid var(--glass-border);
      display: flex;
      flex-direction: column;
      z-index: 50;
      padding-top: 60px;
      overflow-y: auto;
      overflow-x: hidden;
      transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      transform: translateX(-100%);
    }
    
    .sidebar.visible {
      transform: translateX(0);
    }
    
    .sidebar-header {
      padding: 12px 16px;
      border-bottom: 1px solid var(--glass-border);
      margin-bottom: 8px;
      font-size: 12px;
      font-weight: 600;
      color: var(--text-muted);
      letter-spacing: 0.5px;
      text-transform: uppercase;
    }
    
    .album-list {
      flex: 1;
      overflow-y: auto;
      padding: 8px;
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    
    .album-item {
      padding: 10px 12px;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s ease;
      border: 1px solid transparent;
      color: var(--text-secondary);
      font-size: 13px;
      user-select: none;
    }
    
    .album-item:hover {
      background: var(--glass-bg-hover);
      border-color: var(--glass-border-hover);
      color: var(--text);
    }
    
    .album-item.active {
      background: linear-gradient(135deg, rgba(124, 111, 255, 0.15) 0%, rgba(0, 229, 255, 0.05) 100%);
      border-color: var(--glass-border-hover);
      color: var(--accent2);
      font-weight: 500;
    }
    
    /* Main content */
    .main-content {
      margin-left: 0;
      transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      padding: 24px;
      max-width: 100%;
      overflow-y: auto;
    }
    
    .content-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 24px;
      gap: 12px;
    }
    
    .content-title {
      display: flex;
      align-items: center;
      gap: 12px;
      flex: 1;
      min-width: 0;
    }
    
    .content-title h2 {
      font-size: 24px;
      font-weight: 600;
      color: var(--text);
      margin: 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    
    .content-info {
      font-size: 12px;
      color: var(--text-muted);
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 6px;
      padding: 6px 10px;
      backdrop-filter: blur(10px);
    }
    
    .toggle-sidebar-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 8px;
      cursor: pointer;
      color: var(--text);
      font-size: 18px;
      transition: all 0.2s ease;
      flex-shrink: 0;
    }
    
    .toggle-sidebar-btn:hover {
      background: var(--glass-bg-hover);
      border-color: var(--glass-border-hover);
    }
    
    /* Grid layout */
    #grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
      gap: 10px;
      margin-bottom: 40px;
    }
    
    .thumb {
      position: relative;
      aspect-ratio: 1;
      border-radius: 10px;
      overflow: hidden;
      cursor: pointer;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      animation: fadeIn 0.4s ease both;
    }
    
    .thumb:hover {
      transform: translateY(-2px) scale(1.01);
      border-color: var(--glass-border-hover);
      box-shadow: 0 12px 24px rgba(124, 111, 255, 0.15);
    }
    
    .thumb-img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    }
    
    .thumb:hover .thumb-img {
      transform: scale(1.05);
    }
    
    .thumb-overlay {
      position: absolute;
      inset: 0;
      background: linear-gradient(to top, rgba(0, 0, 0, 0.8) 0%, transparent 40%);
      opacity: 0;
      transition: opacity 0.25s ease;
      display: flex;
      align-items: flex-end;
      justify-content: space-between;
      padding: 10px;
      gap: 6px;
    }
    
    .thumb:hover .thumb-overlay {
      opacity: 1;
    }
    
    .thumb-badge {
      position: absolute;
      top: 8px;
      right: 8px;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(8px);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 6px;
      padding: 4px 8px;
      font-size: 10px;
      color: #FFF;
      font-weight: 500;
    }
    
    .thumb-btn {
      background: rgba(124, 111, 255, 0.8);
      backdrop-filter: blur(8px);
      border: none;
      color: #FFF;
      border-radius: 6px;
      padding: 6px 10px;
      cursor: pointer;
      font-size: 11px;
      font-weight: 500;
      display: flex;
      align-items: center;
      gap: 4px;
      transition: all 0.2s ease;
      flex: 1;
      justify-content: center;
    }
    
    .thumb-btn:hover {
      background: var(--accent);
      transform: scale(1.05);
    }
    
    /* Lightbox */
    #lightbox {
      position: fixed;
      inset: 0;
      z-index: 1000;
      background: rgba(6, 6, 12, 0.95);
      backdrop-filter: blur(30px) saturate(180%);
      display: flex;
      align-items: center;
      justify-content: center;
      opacity: 0;
      visibility: hidden;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }
    
    #lightbox.active {
      opacity: 1;
      visibility: visible;
    }
    
    .lb-inner {
      position: relative;
      max-width: 94vw;
      max-height: 88vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      animation: scales 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
    }
    
    @keyframes scales {
      from {
        transform: scale(0.9) translateY(20px);
        opacity: 0;
      }
      to {
        transform: scale(1) translateY(0);
        opacity: 1;
      }
    }
    
    #lb-media, #lb-video {
      max-width: 94vw;
      max-height: 85vh;
      border-radius: 12px;
      border: 1px solid var(--glass-border);
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8);
      object-fit: contain;
      background: var(--surface-dark);
    }
    
    .lb-controls {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
      justify-content: center;
    }
    
    .lb-btn {
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      color: var(--text);
      border-radius: 8px;
      padding: 8px 16px;
      font-size: 12px;
      cursor: pointer;
      font-weight: 500;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s ease;
      backdrop-filter: blur(10px);
    }
    
    .lb-btn:hover {
      background: var(--glass-bg-hover);
      border-color: var(--glass-border-hover);
    }
    
    .lb-btn.primary {
      background: linear-gradient(135deg, var(--accent) 0%, rgba(0, 229, 255, 0.4) 100%);
      border-color: transparent;
      color: #FFF;
    }
    
    .lb-btn.primary:hover {
      opacity: 0.9;
      transform: translateY(-1px);
    }
    
    .lb-nav {
      position: fixed;
      top: 50%;
      transform: translateY(-50%);
      width: 40px;
      height: 40px;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 50%;
      color: var(--text);
      font-size: 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s ease;
      backdrop-filter: blur(10px);
      z-index: 10;
    }
    
    .lb-nav:hover {
      background: var(--glass-bg-hover);
      border-color: var(--glass-border-hover);
    }
    
    .lb-nav:disabled {
      opacity: 0.3;
      cursor: not-allowed;
    }
    
    #lb-prev {
      left: 16px;
    }
    
    #lb-next {
      right: 16px;
    }
    
    .lb-close {
      position: absolute;
      top: -16px;
      right: -16px;
      width: 36px;
      height: 36px;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 50%;
      color: var(--text);
      font-size: 18px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s ease;
      backdrop-filter: blur(10px);
    }
    
    .lb-close:hover {
      background: rgba(255, 80, 80, 0.2);
      border-color: rgba(255, 80, 80, 0.4);
      color: #FF6B6B;
    }
    
    /* Loaders */
    .loader {
      text-align: center;
      padding: 60px 20px;
      color: var(--text-muted);
      font-size: 13px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
    }
    
    .spinner {
      width: 32px;
      height: 32px;
      border: 2px solid var(--glass-border);
      border-top-color: var(--accent);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    
    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }
    
    /* Empty state */
    .empty-state {
      text-align: center;
      padding: 80px 20px;
      color: var(--text-muted);
      font-size: 14px;
    }
    
    .empty-state span {
      font-size: 48px;
      display: block;
      margin-bottom: 12px;
    }
    
    /* Footer */
    .privacy-footer {
      text-align: center;
      padding: 32px;
      color: var(--text-muted);
      font-size: 11px;
      border-top: 1px solid var(--glass-border);
      margin-top: 40px;
      line-height: 1.6;
    }
    
    @keyframes fadeIn {
      from {
        opacity: 0;
        transform: translateY(12px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    /* Desktop — sidebar always visible */
    @media (min-width: 769px) {
      .sidebar {
        transform: translateX(0) !important;
      }
      
      .main-content {
        margin-left: 280px;
      }
      
      .toggle-sidebar-btn {
        display: none !important;
      }
      
      .sidebar-overlay {
        display: none !important;
      }
    }
    
    /* Large desktop — wider grid */
    @media (min-width: 1200px) {
      #grid {
        grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
        gap: 12px;
      }
      
      .main-content {
        padding: 32px;
      }
    }
    
    /* Responsive — tablet/mobile */
    @media (max-width: 768px) {
      .sidebar {
        width: 280px;
        z-index: 200;
        box-shadow: 4px 0 30px rgba(0, 0, 0, 0.5);
      }
      
      .sidebar-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        z-index: 199;
        opacity: 0;
        visibility: hidden;
        transition: all 0.3s ease;
      }
      
      .sidebar-overlay.active {
        opacity: 1;
        visibility: visible;
      }
      
      .content-header {
        flex-wrap: wrap;
      }
      
      header h1 {
        font-size: 14px;
      }
      
      #grid {
        grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
        gap: 8px;
      }
      
      .lb-nav {
        width: 36px;
        height: 36px;
        font-size: 16px;
      }
      
      #lb-prev {
        left: 12px;
      }
      
      #lb-next {
        right: 12px;
      }
      
      .privacy-footer {
        font-size: 10px;
        padding: 24px;
      }
    }
    
    @media (max-width: 480px) {
      header {
        padding: 10px 12px;
      }
      
      .logo-icon {
        width: 32px;
        height: 32px;
        font-size: 14px;
      }
      
      header h1 {
        font-size: 13px;
      }
      
      .main-content {
        padding: 16px;
      }
      
      .content-title h2 {
        font-size: 18px;
      }
      
      #grid {
        grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
        gap: 6px;
      }
      
      .lb-inner {
        max-width: 96vw;
        max-height: 90vh;
      }
      
      #lb-media, #lb-video {
        max-width: 96vw;
        max-height: 85vh;
      }
    }
  </style>
</head>
<body>

<div class="container">
  <header>
    <div class="logo-icon">◆</div>
    <div class="logo-text">
      <h1>Liquid Gallery</h1>
      <p>LAN · $ipAddress:$port</p>
    </div>
    <div class="status-pill">
      <span class="status-dot"></span>
      Connected
    </div>
    <button class="toggle-sidebar-btn" id="toggle-sidebar" title="Toggle sidebar">☰</button>
  </header>

  <div class="main-wrapper">
    <div class="sidebar-overlay" id="sidebar-overlay"></div>
    <aside class="sidebar" id="sidebar">
      <div class="sidebar-header">📁 Albums</div>
      <div class="album-list" id="album-list">
        <div class="loader"><div class="spinner"></div></div>
      </div>
    </aside>

    <main class="main-content" id="main-content">
      <div class="content-header">
        <div class="content-title">
          <h2 id="page-title">Albums</h2>
          <span class="content-info" id="content-info" style="display:none;"></span>
        </div>
      </div>
      <div id="albums-grid" class="albums-view">
        <div class="loader"><div class="spinner"></div><span>Loading albums…</span></div>
      </div>
      <div id="assets-grid" style="display:none;">
        <div id="grid"></div>
      </div>
      <div class="privacy-footer">
        🛡️ Liquid Gallery — Pure Privacy · Digital Sovereignty<br/>
        All data stays on your local network. Nothing is uploaded to the internet.
      </div>
    </main>
  </div>
</div>

<div id="lightbox">
  <button class="lb-nav" id="lb-prev" title="Previous (←)">‹</button>
  <button class="lb-nav" id="lb-next" title="Next (→)">›</button>
  <div class="lb-inner">
   <button id="lb-close" class="lb-close" title="Close (Esc)">✕</button>
    <img id="lb-media" alt="media"/>
    <video id="lb-video" controls></video>
    <div class="lb-controls">
      <button class="lb-btn" onclick="closeLightbox()">✕ Close</button>
      <button class="lb-btn primary" id="lb-download" onclick="downloadCurrent()">⬇ Download</button>
    </div>
  </div>
</div>

<script>
  const API_BASE = '/api';
  let allAlbums = [];
  let currentAlbumId = '';
  let currentAlbumName = '';
  let currentAssets = [];
  let currentViewerIndex = 0;
  let currentPage = 0;
  let totalAssets = 0;
  let hasMore = false;
  const ASSETS_PER_PAGE = 100;

  const sidebar = document.getElementById('sidebar');
  const toggleBtn = document.getElementById('toggle-sidebar');
  const mainContent = document.getElementById('main-content');
  const sidebarOverlay = document.getElementById('sidebar-overlay');

  // Toggle sidebar on mobile
  function toggleSidebar() {
    const isVisible = sidebar.classList.contains('visible');
    if (isVisible) {
      sidebar.classList.remove('visible');
      sidebarOverlay.classList.remove('active');
    } else {
      sidebar.classList.add('visible');
      sidebarOverlay.classList.add('active');
    }
  }

  toggleBtn.addEventListener('click', toggleSidebar);
  sidebarOverlay.addEventListener('click', () => {
    sidebar.classList.remove('visible');
    sidebarOverlay.classList.remove('active');
  });

  // Close sidebar when clicking album on mobile
  function closeSidebarOnMobile() {
    if (window.innerWidth <= 768) {
      sidebar.classList.remove('visible');
      sidebarOverlay.classList.remove('active');
    }
  }

  // Load all albums on page init
  async function loadAlbums() {
    try {
      const res = await fetch(API_BASE + '/albums');
      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        const errorMsg = errorData.error || 'Failed to load albums (HTTP ' + res.status + ')';
        const details = errorData.details || (errorData.code === 'PERMISSION_DENIED' ? 'Check app permissions' : 'Server error');
        document.getElementById('album-list').innerHTML = '<div class="empty-state" style="padding:20px;"><span>⚠️</span> ' + errorMsg + '<br/><small>' + details + '</small></div>';
        console.error('Albums API error:', errorData);
        return;
      }
      const albums = await res.json();
      allAlbums = albums;

      const albumList = document.getElementById('album-list');
      albumList.innerHTML = '';

      if (!albums || albums.length === 0) {
        albumList.innerHTML = '<div class="empty-state" style="padding:20px;"><span>📂</span> No albums<br/><small style="color:var(--text-muted);">No photos or videos found</small></div>';
        return;
      }

      allAlbums.forEach((album, idx) => {
        const item = document.createElement('div');
        item.className = 'album-item';
        item.setAttribute('data-album-id', album.id);
        item.textContent = (album.name || 'All Photos') + ' (' + album.count + ')';
        item.onclick = () => loadAlbumAssets(album.id, album.name || 'All Photos');
        albumList.appendChild(item);
      });

      // Auto-load first album
      if (allAlbums.length > 0) {
        loadAlbumAssets(allAlbums[0].id, allAlbums[0].name || 'All Photos');
      }
    } catch (err) {
      document.getElementById('album-list').innerHTML = '<div class="empty-state" style="padding:20px;color:var(--text-muted);"><span>⚠️</span> Error<br/><small>' + (err.message || 'Failed to load') + '</small></div>';
      console.error('Failed to load albums:', err);
    }
  }

  async function loadAlbumAssets(albumId, albumName) {
    currentAlbumId = albumId;
    currentAlbumName = albumName;
    currentPage = 0;
    currentAssets = [];
    totalAssets = 0;

    // Update UI
    document.getElementById('page-title').textContent = albumName;
    document.getElementById('content-info').style.display = 'none';
    document.getElementById('albums-grid').style.display = 'none';
    document.getElementById('assets-grid').style.display = 'block';

    // Update active album in sidebar
    document.querySelectorAll('.album-item').forEach(item => {
      item.classList.remove('active');
      if (item.getAttribute('data-album-id') === albumId) {
        item.classList.add('active');
      }
    });

    closeSidebarOnMobile();

    const grid = document.getElementById('grid');
    grid.innerHTML = '<div class="loader"><div class="spinner"></div><span>Loading assets…</span></div>';

    await loadMoreAssets();
  }

  async function loadMoreAssets() {
    try {
      const url = API_BASE + '/assets/' + currentAlbumId + '?page=' + currentPage + '&size=' + ASSETS_PER_PAGE;
      const res = await fetch(url);
      const data = await res.json();
      const assets = data.assets || [];

      currentAssets = currentPage === 0 ? assets : currentAssets.concat(assets);
      totalAssets = data.total || 0;
      hasMore = data.hasMore || false;

      renderAssets();
      currentPage++;
    } catch (err) {
      console.error('Failed to load assets:', err);
      document.getElementById('grid').innerHTML = '<div class="empty-state"><span>⚠️</span> Failed to load assets</div>';
    }
  }

  function renderAssets() {
    const grid = document.getElementById('grid');
    const info = document.getElementById('content-info');

    if (currentAssets.length === 0) {
      grid.innerHTML = '<div class="empty-state"><span>🖼️</span> No media found</div>';
      info.style.display = 'none';
      return;
    }

    info.textContent = totalAssets + ' total';
    info.style.display = 'block';

    let html = '';
    for (let i = 0; i < currentAssets.length; i++) {
      const asset = currentAssets[i];
      const isVideo = asset.type === 'video';
      const duration = isVideo && asset.duration ? formatDuration(asset.duration) : '';
      const bagdeHtml = isVideo ? '<span class="thumb-badge">▶ ' + duration + '</span>' : '';
      html += '<div class="thumb" onclick="openViewer(' + i + ')" style="animation-delay:' + (i * 20) + 'ms">' +
        '<img class="thumb-img" src="' + asset.thumbUrl + '" loading="lazy" alt="media"/>' +
        bagdeHtml +
        '<div class="thumb-overlay">' +
        '<button class="thumb-btn" onclick="event.stopPropagation();openViewer(' + i + ')">View</button>' +
        '<button class="thumb-btn" onclick="event.stopPropagation();download(' + "'" + asset.fileUrl + "'" + ')">Save</button>' +
        '</div>' +
        '</div>';
    }
    grid.innerHTML = html;

    // Remove old load-more container if exists
    const oldContainer = document.querySelector('.load-more-container');
    if (oldContainer) oldContainer.remove();

    if (hasMore) {
      const container = document.createElement('div');
      container.className = 'load-more-container';
      container.style.textAlign = 'center';
      container.style.marginTop = '24px';
      container.innerHTML = '<button class="lb-btn" onclick="loadMoreAssets()" style="cursor:pointer;margin:0 auto;">Load More</button>';
      grid.parentElement.appendChild(container);
    }
  }

  function formatDuration(secs) {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return m + ':' + String(s).padStart(2, '0');
  }

  function openViewer(index) {
    currentViewerIndex = index;
    const asset = currentAssets[index];
    const lb = document.getElementById('lightbox');
    const img = document.getElementById('lb-media');
    const vid = document.getElementById('lb-video');

    if (asset.type === 'video') {
      img.style.display = 'none';
      vid.style.display = 'block';
      vid.src = asset.streamUrl || asset.fileUrl;
      vid.play().catch(() => {});
    } else {
      vid.style.display = 'none';
      vid.pause();
      vid.src = '';
      img.style.display = 'block';
      img.src = asset.fileUrl || asset.thumbUrl;
    }

    updateNavButtons();
    lb.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  function closeLightbox() {
    const lb = document.getElementById('lightbox');
    const vid = document.getElementById('lb-video');
    lb.classList.remove('active');
    vid.pause();
    vid.src = '';
    document.body.style.overflow = '';
  }

  function navigateViewer(dir) {
    const newIdx = currentViewerIndex + dir;
    if (newIdx < 0 || newIdx >= currentAssets.length) return;
    openViewer(newIdx);
  }

  function updateNavButtons() {
    const prev = document.getElementById('lb-prev');
    const next = document.getElementById('lb-next');
    prev.disabled = currentViewerIndex === 0;
    next.disabled = currentViewerIndex === currentAssets.length - 1;
  }

  function downloadCurrent() {
    const asset = currentAssets[currentViewerIndex];
    if (asset) download(asset.fileUrl);
  }

  function download(url) {
    const a = document.createElement('a');
    a.href = url;
    a.download = '';
    document.body.appendChild(a);
    a.click();
    a.remove();
  }

  // Keyboard shortcuts
  document.addEventListener('keydown', (e) => {
    const lb = document.getElementById('lightbox');
    if (!lb.classList.contains('active')) return;

    switch (e.key) {
      case 'Escape':
        closeLightbox();
        break;
      case 'ArrowLeft':
        navigateViewer(-1);
        break;
      case 'ArrowRight':
        navigateViewer(1);
        break;
    }
  });

     // Lightbox navigation button events
    document.getElementById('lb-prev').addEventListener('click', () => navigateViewer(-1));
    document.getElementById('lb-next').addEventListener('click', () => navigateViewer(1));
    document.getElementById('lb-close').addEventListener('click', closeLightbox);

    // Lightbox background click to close
    document.getElementById('lightbox').addEventListener('click', (e) => {
      if (e.target.id === 'lightbox') closeLightbox();
    });

    // Touch swipe support for lightbox
    let touchStart = { x: 0, y: 0 };
    document.addEventListener('touchstart', (e) => {
      touchStart = { x: e.touches[0].clientX, y: e.touches[0].clientY };
    });
  document.addEventListener('touchend', (e) => {
    const lb = document.getElementById('lightbox');
    if (!lb.classList.contains('active')) return;

    const touchEnd = e.changedTouches[0];
    const dx = touchEnd.clientX - touchStart.x;
    const dy = touchEnd.clientY - touchStart.y;

    if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 50) {
      navigateViewer(dx > 0 ? -1 : 1);
    } else if (Math.abs(dy) > 50) {
      if (dy > 50) closeLightbox();
    }
  });

  // Initialize
  loadAlbums();
</script>

</body>
</html>
''';

  // ─── Dynamic folder browsing ────────────────────────────

  /// Lists folders in a given path for dynamic folder browser
  Future<List<ShareableDirectory>> listFoldersInPath(String? path) async {
    try {
      if (path == null || path.isEmpty || path == 'root') {
        // Show root storage options
        final dirs = <ShareableDirectory>[];

        // System Photos
        dirs.add(
          ShareableDirectory(
            name: 'All Photos',
            path: 'PHOTOS_SYSTEM',
            type: StorageType.systemPhotos,
            displayPath: 'Device Photos',
          ),
        );

        // Downloads
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          dirs.add(
            ShareableDirectory(
              name: 'Downloads',
              path: downloadsDir.path,
              type: StorageType.downloads,
              displayPath: 'Downloads',
            ),
          );
        }

        // Documents
        final documentsDir = await getApplicationDocumentsDirectory();
        dirs.add(
          ShareableDirectory(
            name: 'Documents',
            path: documentsDir.path,
            type: StorageType.documents,
            displayPath: 'Documents',
          ),
        );

        // External Storage
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            dirs.add(
              ShareableDirectory(
                name: 'External Storage',
                path: externalDir.path,
                type: StorageType.externalStorage,
                displayPath: 'External Storage',
              ),
            );
          }
        } catch (_) {}

        return dirs;
      }

      // For system photos, can't browse into subfolders
      if (path == 'PHOTOS_SYSTEM') {
        return [];
      }

      // List actual folders in the specified path
      final dir = Directory(path);
      if (!await dir.exists()) {
        return [];
      }

      final folders = <ShareableDirectory>[];
      try {
        final entities = await dir.list().toList();
        
        for (final entity in entities) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            
            // Skip hidden folders and system folders
            if (!name.startsWith('.')) {
              folders.add(
                ShareableDirectory(
                  name: name,
                  path: entity.path,
                  type: StorageType.externalStorage,
                  displayPath: name,
                ),
              );
            }
          }
        }

        // Sort folders alphabetically
        folders.sort((a, b) => a.name.compareTo(b.name));
      } catch (_) {}

      return folders;
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    stopServer();
    _infoController.close();
  }
}
