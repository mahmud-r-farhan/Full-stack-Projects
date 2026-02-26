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
  <link href="https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700&family=Inter:wght@300;400;500&display=swap" rel="stylesheet"/>
  <style>
    :root {
      --glass-bg: rgba(255,255,255,0.07);
      --glass-border: rgba(255,255,255,0.13);
      --glass-hover: rgba(255,255,255,0.12);
      --accent: #7C6FFF;
      --accent2: #00E5FF;
      --surface: rgba(15,14,30,0.95);
      --text: #EAE9FF;
      --muted: #888AB0;
    }
    *{box-sizing:border-box;margin:0;padding:0;}
    html{scroll-behavior:smooth;}

    body {
      background: #06060F;
      color: var(--text);
      font-family: 'Inter', sans-serif;
      min-height: 100vh;
      overflow-x: hidden;
    }

    /* Ambient background blobs */
    body::before, body::after {
      content:'';
      position:fixed;
      border-radius:50%;
      filter:blur(120px);
      pointer-events:none;
      z-index:0;
    }
    body::before {
      width:500px;height:500px;
      background:radial-gradient(circle,rgba(124,111,255,0.18),transparent 70%);
      top:-100px;left:-100px;
    }
    body::after {
      width:400px;height:400px;
      background:radial-gradient(circle,rgba(0,229,255,0.12),transparent 70%);
      bottom:-80px;right:-80px;
    }

    /* HEADER */
    header {
      position:sticky;top:0;z-index:100;
      padding:20px 32px;
      display:flex;align-items:center;gap:16px;
      background:rgba(6,6,15,0.6);
      backdrop-filter:blur(24px) saturate(180%);
      -webkit-backdrop-filter:blur(24px) saturate(180%);
      border-bottom:1px solid var(--glass-border);
    }
    .logo-icon {
      width:42px;height:42px;
      background:linear-gradient(135deg,var(--accent),var(--accent2));
      border-radius:12px;
      display:flex;align-items:center;justify-content:center;
      font-size:20px;
      box-shadow:0 0 20px rgba(124,111,255,0.4);
      flex-shrink:0;
    }
    header h1 {
      font-family:'Sora',sans-serif;
      font-size:22px;font-weight:700;
      background:linear-gradient(135deg,#fff 40%,var(--accent2));
      -webkit-background-clip:text;-webkit-text-fill-color:transparent;
      background-clip:text;
      letter-spacing:-0.3px;
    }
    header p {
      font-size:12px;color:var(--muted);margin-top:2px;
      font-weight:300;letter-spacing:0.3px;
    }
    .status-pill {
      margin-left:auto;
      background:var(--glass-bg);
      border:1px solid var(--glass-border);
      border-radius:99px;
      padding:7px 16px;
      font-size:12px;
      display:flex;align-items:center;gap:6px;
      backdrop-filter:blur(10px);
      color:var(--muted);
      font-weight:500;
    }
    .status-dot {
      width:7px;height:7px;border-radius:50%;
      background:#22C55E;
      box-shadow:0 0 8px rgba(34,197,94,0.8);
      animation:pulse-dot 2s ease-in-out infinite;
    }
    @keyframes pulse-dot {
      0%,100%{opacity:1;transform:scale(1);}
      50%{opacity:0.6;transform:scale(0.85);}
    }

    /* MAIN */
    main {
      position:relative;z-index:1;
      padding:32px;
      max-width:1400px;
      margin:0 auto;
    }

    /* SECTION TITLES */
    .section-header {
      display:flex;align-items:center;gap:12px;
      margin-bottom:20px;
    }
    .section-header h2 {
      font-family:'Sora',sans-serif;
      font-size:15px;font-weight:600;
      color:var(--muted);
      letter-spacing:0.8px;
      text-transform:uppercase;
    }
    .section-line {
      flex:1;height:1px;
      background:linear-gradient(to right, var(--glass-border), transparent);
    }

    /* BACK BUTTON */
    #back-btn {
      display:none;
      align-items:center;gap:8px;
      background:var(--glass-bg);
      border:1px solid var(--glass-border);
      color:var(--text);
      border-radius:10px;
      padding:8px 16px;
      font-size:13px;
      cursor:pointer;
      margin-bottom:20px;
      font-family:'Inter',sans-serif;
      transition:all .2s;
      backdrop-filter:blur(12px);
      width:fit-content;
    }
    #back-btn:hover{background:var(--glass-hover);border-color:var(--accent);transform:translateX(-2px);}

    /* ALBUM GRID */
    #albums {
      display:grid;
      grid-template-columns:repeat(auto-fill,minmax(160px,1fr));
      gap:12px;
      margin-bottom:40px;
    }
    .album-card {
      background:var(--glass-bg);
      border:1px solid var(--glass-border);
      border-radius:18px;
      padding:20px 16px;
      cursor:pointer;
      transition:all .25s cubic-bezier(.4,0,.2,1);
      position:relative;
      overflow:hidden;
    }
    .album-card::before {
      content:'';
      position:absolute;inset:0;
      background:linear-gradient(135deg,rgba(124,111,255,0.12),rgba(0,229,255,0.06));
      opacity:0;
      transition:opacity .3s;
      border-radius:inherit;
    }
    .album-card:hover{
      border-color:rgba(124,111,255,0.5);
      transform:translateY(-4px);
      box-shadow:0 16px 40px rgba(0,0,0,0.4),0 0 0 1px rgba(124,111,255,0.2);
    }
    .album-card:hover::before{opacity:1;}
    .album-icon {
      font-size:26px;margin-bottom:12px;
      display:block;
    }
    .album-card h3 {
      font-family:'Sora',sans-serif;
      font-size:13px;font-weight:600;
      margin-bottom:5px;
      line-height:1.3;
    }
    .album-card span {
      font-size:11px;color:var(--muted);
      font-weight:400;
    }

    /* ASSET GRID */
    #grid {
      display:grid;
      grid-template-columns:repeat(auto-fill,minmax(150px,1fr));
      gap:10px;
    }
    .thumb {
      position:relative;
      aspect-ratio:1;
      border-radius:14px;
      overflow:hidden;
      cursor:pointer;
      background:#1A1A2E;
      border:1px solid var(--glass-border);
      transition:all .25s cubic-bezier(.4,0,.2,1);
    }
    .thumb:hover {
      transform:translateY(-3px) scale(1.02);
      border-color:rgba(124,111,255,0.5);
      box-shadow:0 12px 30px rgba(0,0,0,0.5),0 0 0 1px rgba(124,111,255,0.25);
      z-index:2;
    }
    .thumb img {
      width:100%;height:100%;
      object-fit:cover;
      transition:transform .4s cubic-bezier(.4,0,.2,1);
    }
    .thumb:hover img{transform:scale(1.1);}

    /* overlay on hover */
    .thumb-overlay {
      position:absolute;inset:0;
      background:linear-gradient(to top, rgba(0,0,0,0.7) 0%, transparent 50%);
      opacity:0;
      transition:opacity .25s;
      display:flex;align-items:flex-end;justify-content:space-between;
      padding:10px;
    }
    .thumb:hover .thumb-overlay{opacity:1;}

    .badge-vid {
      position:absolute;top:8px;right:8px;
      background:rgba(0,0,0,0.55);
      backdrop-filter:blur(8px);
      border:1px solid rgba(255,255,255,0.15);
      border-radius:7px;
      padding:3px 8px;
      font-size:10px;
      color:#fff;
      letter-spacing:0.3px;
    }
    .download-btn {
      background:rgba(124,111,255,0.9);
      backdrop-filter:blur(10px);
      border:none;
      color:#fff;
      border-radius:8px;
      padding:6px 10px;
      cursor:pointer;
      font-size:11px;
      font-family:'Inter',sans-serif;
      font-weight:500;
      display:flex;align-items:center;gap:5px;
      transition:all .2s;
      z-index:3;
    }
    .download-btn:hover{background:var(--accent);transform:scale(1.05);}

    .open-btn {
      background:rgba(255,255,255,0.15);
      backdrop-filter:blur(10px);
      border:1px solid rgba(255,255,255,0.2);
      color:#fff;
      border-radius:8px;
      padding:6px 10px;
      cursor:pointer;
      font-size:11px;
      font-family:'Inter',sans-serif;
      font-weight:500;
      transition:all .2s;
    }
    .open-btn:hover{background:rgba(255,255,255,0.25);}

    /* LOADER */
    .loader {
      text-align:center;padding:60px;
      color:var(--muted);font-size:13px;
      display:flex;flex-direction:column;align-items:center;gap:14px;
    }
    .spinner {
      width:32px;height:32px;
      border:2px solid var(--glass-border);
      border-top-color:var(--accent);
      border-radius:50%;
      animation:spin .7s linear infinite;
    }
    @keyframes spin{to{transform:rotate(360deg);}}

    /* LIGHTBOX */
    #lightbox {
      position:fixed;inset:0;z-index:1000;
      background:rgba(4,4,12,0.92);
      backdrop-filter:blur(30px) saturate(150%);
      -webkit-backdrop-filter:blur(30px) saturate(150%);
      display:flex;align-items:center;justify-content:center;
      opacity:0;visibility:hidden;
      transition:all .3s cubic-bezier(.4,0,.2,1);
    }
    #lightbox.active{opacity:1;visibility:visible;}

    .lb-inner {
      position:relative;
      max-width:92vw;max-height:90vh;
      display:flex;flex-direction:column;
      align-items:center;gap:16px;
      animation:lb-in .3s cubic-bezier(.34,1.56,.64,1) forwards;
    }
    @keyframes lb-in {
      from{transform:scale(0.88) translateY(20px);opacity:0;}
      to{transform:scale(1) translateY(0);opacity:1;}
    }
    #lb-media {
      max-width:90vw;max-height:80vh;
      border-radius:18px;
      border:1px solid var(--glass-border);
      box-shadow:0 30px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.05);
      object-fit:contain;
      background:#0a0a14;
    }
    #lb-video {
      display:none;
      max-width:90vw;max-height:80vh;
      border-radius:18px;
      border:1px solid var(--glass-border);
      box-shadow:0 30px 80px rgba(0,0,0,0.6);
      background:#000;
    }
    .lb-controls {
      display:flex;align-items:center;gap:10px;
    }
    .lb-btn {
      background:var(--glass-bg);
      border:1px solid var(--glass-border);
      color:var(--text);
      border-radius:10px;
      padding:9px 18px;
      font-size:13px;
      cursor:pointer;
      font-family:'Inter',sans-serif;
      font-weight:500;
      display:flex;align-items:center;gap:7px;
      transition:all .2s;
      backdrop-filter:blur(12px);
    }
    .lb-btn:hover{background:var(--glass-hover);border-color:var(--accent);}
    .lb-btn.primary {
      background:linear-gradient(135deg,var(--accent),rgba(0,229,255,0.6));
      border-color:transparent;
      color:#fff;
    }
    .lb-btn.primary:hover{opacity:0.88;transform:translateY(-1px);}
    .lb-close {
      position:absolute;top:-14px;right:-14px;
      width:36px;height:36px;
      background:var(--glass-bg);
      border:1px solid var(--glass-border);
      border-radius:50%;
      color:#fff;font-size:16px;
      cursor:pointer;display:flex;align-items:center;justify-content:center;
      transition:all .2s;
      backdrop-filter:blur(12px);
    }
    .lb-close:hover{background:rgba(255,80,80,0.3);border-color:rgba(255,80,80,0.5);}

    /* NAV arrows */
    .lb-nav {
      position:fixed;top:50%;transform:translateY(-50%);
      width:44px;height:44px;
      background:var(--glass-bg);
      border:1px solid var(--glass-border);
      border-radius:50%;
      color:#fff;font-size:18px;
      cursor:pointer;display:flex;align-items:center;justify-content:center;
      transition:all .2s;
      backdrop-filter:blur(12px);
      z-index:10;
    }
    .lb-nav:hover{background:var(--glass-hover);border-color:var(--accent);}
    #lb-prev{left:20px;}
    #lb-next{right:20px;}

    /* Stagger animation for grid items */
    .thumb, .album-card {
      animation:fadeUp .4s ease both;
    }
    @keyframes fadeUp {
      from{opacity:0;transform:translateY(16px);}
      to{opacity:1;transform:translateY(0);}
    }
    .thumb:nth-child(1){animation-delay:.02s}
    .thumb:nth-child(2){animation-delay:.04s}
    .thumb:nth-child(3){animation-delay:.06s}
    .thumb:nth-child(4){animation-delay:.08s}
    .thumb:nth-child(5){animation-delay:.10s}
    .thumb:nth-child(6){animation-delay:.12s}
    .thumb:nth-child(7){animation-delay:.14s}
    .thumb:nth-child(8){animation-delay:.16s}
    .thumb:nth-child(9){animation-delay:.18s}
    .thumb:nth-child(10){animation-delay:.20s}
    .album-card:nth-child(1){animation-delay:.04s}
    .album-card:nth-child(2){animation-delay:.08s}
    .album-card:nth-child(3){animation-delay:.12s}
    .album-card:nth-child(4){animation-delay:.16s}
    .album-card:nth-child(5){animation-delay:.20s}
    .album-card:nth-child(6){animation-delay:.24s}

    /* empty state */
    .empty-state{
      text-align:center;padding:60px 20px;
      color:var(--muted);font-size:14px;
      opacity:0.7;
    }
    .empty-state span{font-size:40px;display:block;margin-bottom:12px;}
  </style>
</head>
<body>

<header>
  <div class="logo-icon">💧</div>
  <div>
    <h1>LiquidSync</h1>
    <p>Sharing from $ipAddress:$port</p>
  </div>
  <div class="status-pill">
    <span class="status-dot"></span>
    LAN Active
  </div>
</header>

<main>
  <button id="back-btn" onclick="showAlbums()">
    ← Albums
  </button>

  <div id="albums-section">
    <div class="section-header">
      <h2>Albums</h2>
      <div class="section-line"></div>
    </div>
    <div id="albums">
      <div class="loader"><div class="spinner"></div><span>Loading albums…</span></div>
    </div>
  </div>

  <div id="grid-section" style="display:none;">
    <div class="section-header">
      <h2 id="grid-title">Photos</h2>
      <div class="section-line"></div>
    </div>
    <div id="grid"></div>
  </div>
</main>

<!-- Lightbox -->
<div id="lightbox" onclick="closeLightbox(event)">
  <button class="lb-nav" id="lb-prev" onclick="event.stopPropagation();navLightbox(-1)">‹</button>
  <button class="lb-nav" id="lb-next" onclick="event.stopPropagation();navLightbox(1)">›</button>
  <div class="lb-inner" onclick="event.stopPropagation()">
    <button class="lb-close" onclick="closeLightbox()">✕</button>
    <img id="lb-media" src="" alt="media"/>
    <video id="lb-video" controls></video>
    <div class="lb-controls">
      <button class="lb-btn" onclick="closeLightbox()">✕ Close</button>
      <button class="lb-btn primary" id="lb-download" onclick="dlCurrent()">⬇ Download</button>
    </div>
  </div>
</div>

<script>
const BASE = '/api';
let currentAssets = [];
let currentIndex = 0;

async function loadAlbums() {
  const el = document.getElementById('albums');
  el.innerHTML = '<div class="loader"><div class="spinner"></div><span>Loading albums…</span></div>';
  try {
    const r = await fetch(BASE + '/albums');
    const albums = await r.json();
    if (!albums.length) {
      el.innerHTML = '<div class="empty-state"><span>📂</span>No albums found</div>';
      return;
    }
    const icons = ['🌄','📸','🎬','🌅','👤','📅','🌃','🎞️','🏞️','📷'];
    el.innerHTML = albums.map((a, i) => `
      <div class="album-card" onclick="loadAssets('\${a.id}','\${a.name}')">
        <span class="album-icon">\${icons[i % icons.length]}</span>
        <h3>\${a.name || 'All Photos'}</h3>
        <span>\${a.count} items</span>
      </div>
    `).join('');
  } catch(e) {
    el.innerHTML = '<div class="empty-state"><span>⚠️</span>Failed to load albums</div>';
  }
}

async function loadAssets(id, name) {
  document.getElementById('albums-section').style.display = 'none';
  document.getElementById('grid-section').style.display = 'block';
  document.getElementById('back-btn').style.display = 'flex';
  document.getElementById('grid-title').textContent = name;

  const grid = document.getElementById('grid');
  grid.innerHTML = '<div class="loader"><div class="spinner"></div><span>Loading…</span></div>';

  try {
    const r = await fetch(BASE + '/assets/' + id);
    const assets = await r.json();
    currentAssets = assets;

    if (!assets.length) {
      grid.innerHTML = '<div class="empty-state"><span>🖼️</span>No media found</div>';
      return;
    }

    grid.innerHTML = assets.map((a, i) => `
      <div class="thumb" onclick="openLightbox(\${i})">
        <img src="\${a.thumbUrl}" loading="lazy" alt="media"/>
        \${a.type === 'video' ? '<span class="badge-vid">▶ Video</span>' : ''}
        <div class="thumb-overlay">
          <span class="open-btn" onclick="event.stopPropagation();openLightbox(\${i})">⤢ View</span>
          <button class="download-btn" onclick="event.stopPropagation();dl('\${a.fileUrl}')">⬇ Save</button>
        </div>
      </div>
    `).join('');
  } catch(e) {
    grid.innerHTML = '<div class="empty-state"><span>⚠️</span>Failed to load assets</div>';
  }
}

function showAlbums() {
  document.getElementById('albums-section').style.display = 'block';
  document.getElementById('grid-section').style.display = 'none';
  document.getElementById('back-btn').style.display = 'none';
  currentAssets = [];
}

function openLightbox(index) {
  currentIndex = index;
  const a = currentAssets[index];
  const lb = document.getElementById('lightbox');
  const img = document.getElementById('lb-media');
  const vid = document.getElementById('lb-video');

  if (a.type === 'video') {
    img.style.display = 'none';
    vid.style.display = 'block';
    vid.src = a.fileUrl;
    vid.play();
  } else {
    vid.style.display = 'none';
    vid.pause(); vid.src = '';
    img.style.display = 'block';
    img.src = a.fileUrl || a.thumbUrl;
  }

  lb.classList.add('active');
  document.body.style.overflow = 'hidden';
  updateNav();
}

function closeLightbox(e) {
  if (e && e.target !== document.getElementById('lightbox') && !e.currentTarget.classList.contains('lb-close')) {
    if (e.type === 'click' && e.target === document.getElementById('lightbox')) {}
    else return;
  }
  const lb = document.getElementById('lightbox');
  const vid = document.getElementById('lb-video');
  lb.classList.remove('active');
  vid.pause(); vid.src = '';
  document.body.style.overflow = '';
}

function navLightbox(dir) {
  const newIndex = currentIndex + dir;
  if (newIndex < 0 || newIndex >= currentAssets.length) return;
  openLightbox(newIndex);
}

function updateNav() {
  document.getElementById('lb-prev').style.opacity = currentIndex === 0 ? '0.3' : '1';
  document.getElementById('lb-next').style.opacity = currentIndex === currentAssets.length - 1 ? '0.3' : '1';
}

function dlCurrent() {
  if (currentAssets[currentIndex]) dl(currentAssets[currentIndex].fileUrl);
}

function dl(url) {
  const a = document.createElement('a');
  a.href = url; a.download = '';
  document.body.appendChild(a); a.click(); a.remove();
}

// Keyboard navigation
document.addEventListener('keydown', e => {
  const lb = document.getElementById('lightbox');
  if (!lb.classList.contains('active')) return;
  if (e.key === 'Escape') closeLightbox();
  if (e.key === 'ArrowLeft') navLightbox(-1);
  if (e.key === 'ArrowRight') navLightbox(1);
});

// Close lightbox clicking backdrop
document.getElementById('lightbox').addEventListener('click', function(e) {
  if (e.target === this) closeLightbox();
});

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
