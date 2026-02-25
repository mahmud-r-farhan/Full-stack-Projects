import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

// ═══════════════════════════════════════════════════════════
//  LAN Share Service — Embedded HTTP server (shelf)
//  Hosts a clean Web UI + JSON API for cross-device access.
//  Decoupled completely from UI layer.
// ═══════════════════════════════════════════════════════════

class LanShareService {
  HttpServer? _server;
  LanServerInfo _serverInfo = LanServerInfo.idle;
  final _infoController = StreamController<LanServerInfo>.broadcast();

  Stream<LanServerInfo> get serverInfoStream => _infoController.stream;
  LanServerInfo get currentInfo => _serverInfo;

  // ─── Start server ───────────────────────────────────────

  Future<LanServerInfo> startServer() async {
    if (_server != null) return _serverInfo;

    try {
      _emit(const LanServerInfo(status: ServerStatus.starting));

      final ip = await _getLocalIp();
      if (ip == null) {
        return _emitError('Could not determine local IP address.');
      }

      final router = Router()
        ..get('/', _handleRoot)
        ..get('/api/albums', _handleAlbums)
        ..get('/api/assets/<albumId>', _handleAssets)
        ..get('/api/thumb/<assetId>', _handleThumbnail)
        ..get('/api/file/<assetId>', _handleFile);

      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router.call);

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        AppConstants.lanServerPort,
      );

      final info = LanServerInfo(
        status: ServerStatus.running,
        ipAddress: ip,
        port: AppConstants.lanServerPort,
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
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );
      final data = await Future.wait(
        albums.map(
          (a) async => {
            'id': a.id,
            'name': a.name,
            'count': await a.assetCountAsync,
          },
        ),
      );
      return _jsonResponse(data);
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleAssets(Request req, String albumId) async {
    try {
      final albums = await PhotoManager.getAssetPathList(hasAll: true);
      final album = albums.firstWhere(
        (a) => a.id == albumId,
        orElse: () => albums.first,
      );
      final entities = await album.getAssetListPaged(page: 0, size: 100);
      final data = entities
          .map(
            (e) => {
              'id': e.id,
              'type': e.type.name,
              'width': e.width,
              'height': e.height,
              'createDate': e.createDateTime.toIso8601String(),
              'thumbUrl': '/api/thumb/${e.id}',
              'fileUrl': '/api/file/${e.id}',
            },
          )
          .toList();
      return _jsonResponse(data);
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  Future<Response> _handleThumbnail(Request req, String assetId) async {
    try {
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

  Future<Response> _handleFile(Request req, String assetId) async {
    try {
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) return Response.notFound('Asset not found');
      final file = await entity.originFile;
      if (file == null) return Response.notFound('File unavailable');
      final bytes = await file.readAsBytes();
      final mimeType = entity.type == AssetType.video
          ? 'video/mp4'
          : 'image/jpeg';
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': mimeType,
          'Content-Disposition':
              'attachment; filename="${file.path.split('/').last}"',
        },
      );
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

  Middleware _corsMiddleware() => (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      return response.change(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        },
      );
    };
  };

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

  // ─── Auto-generated Web UI ───────────────────────────────

  String _buildWebUi({required String ipAddress, required int port}) =>
      '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>LiquidSync Gallery</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0;}
    body{background:#0A0A14;color:#fff;font-family:'Segoe UI',sans-serif;min-height:100vh;}
    header{background:linear-gradient(135deg,#6C63FF,#00D9FF);padding:24px 32px;display:flex;align-items:center;gap:16px;}
    header h1{font-size:28px;font-weight:700;letter-spacing:0.5px;}
    header p{font-size:13px;opacity:0.8;margin-top:4px;}
    .badge{background:rgba(255,255,255,0.2);border-radius:8px;padding:6px 14px;font-size:12px;backdrop-filter:blur(10px);}
    main{padding:32px;}
    #albums{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:16px;margin-bottom:32px;}
    .album-card{background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.12);border-radius:16px;padding:16px;cursor:pointer;transition:all .2s;}
    .album-card:hover{background:rgba(108,99,255,0.2);border-color:#6C63FF;transform:translateY(-2px);}
    .album-card h3{font-size:14px;font-weight:600;margin-bottom:4px;}
    .album-card span{font-size:12px;color:#B0B0D0;}
    #grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:8px;}
    .thumb{position:relative;aspect-ratio:1;border-radius:12px;overflow:hidden;cursor:pointer;background:#1A1A2E;}
    .thumb img{width:100%;height:100%;object-fit:cover;transition:transform .3s;}
    .thumb:hover img{transform:scale(1.08);}
    .thumb .badge-vid{position:absolute;top:8px;right:8px;background:rgba(0,0,0,.6);border-radius:6px;padding:2px 6px;font-size:10px;}
    .download-btn{position:absolute;bottom:8px;right:8px;background:#6C63FF;border:none;color:#fff;border-radius:8px;padding:6px 10px;cursor:pointer;font-size:11px;opacity:0;transition:opacity .2s;}
    .thumb:hover .download-btn{opacity:1;}
    h2{font-size:20px;font-weight:600;margin-bottom:16px;color:#B0B0D0;}
    .loader{text-align:center;padding:60px;color:#6060A0;font-size:14px;}
  </style>
</head>
<body>
<header>
  <div>
    <h1>💧 LiquidSync Gallery</h1>
    <p>Sharing from $ipAddress:$port</p>
  </div>
  <div style="margin-left:auto;" class="badge">LAN Share Active</div>
</header>
<main>
  <h2>Albums</h2>
  <div id="albums"><div class="loader">Loading albums…</div></div>
  <h2 id="grid-title" style="display:none;">Photos</h2>
  <div id="grid"></div>
</main>
<script>
const BASE='/api';
async function loadAlbums(){
  const r=await fetch(BASE+'/albums');
  const albums=await r.json();
  const el=document.getElementById('albums');
  el.innerHTML=albums.map(a=>`<div class="album-card" onclick="loadAssets('\${a.id}','\${a.name}')">
    <h3>\${a.name||'All Photos'}</h3><span>\${a.count} items</span></div>`).join('');
}
async function loadAssets(id,name){
  document.getElementById('grid-title').style.display='block';
  document.getElementById('grid-title').textContent=name;
  const grid=document.getElementById('grid');
  grid.innerHTML='<div class="loader">Loading…</div>';
  const r=await fetch(BASE+'/assets/'+id);
  const assets=await r.json();
  grid.innerHTML=assets.map(a=>`<div class="thumb">
    <img src="\${a.thumbUrl}" loading="lazy" alt="media"/>
    \${a.type==='video'?'<span class="badge-vid">▶ Video</span>':''}
    <button class="download-btn" onclick="dl('\${a.fileUrl}')">⬇ Save</button>
  </div>`).join('');
}
function dl(url){const a=document.createElement('a');a.href=url;a.download='';document.body.appendChild(a);a.click();a.remove();}
loadAlbums();
</script>
</body>
</html>
''';

  void dispose() {
    stopServer();
    _infoController.close();
  }
}
