import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../services/lan_share_service.dart';

// ═══════════════════════════════════════════════════════════
//  LAN Sharing Providers — Enhanced with directory selection
// ═══════════════════════════════════════════════════════════

final lanShareServiceProvider = Provider<LanShareService>((ref) {
  final service = LanShareService();
  ref.onDispose(service.dispose);
  return service;
});

// Get available directories for sharing
final availableDirectoriesProvider =
    FutureProvider<List<ShareableDirectory>>((ref) async {
  final service = ref.watch(lanShareServiceProvider);
  return service.getAvailableDirectories();
});

// ─── Folder Browser State ──────────────────────────────────
// Tracks current browsing path for dynamic folder selection
final folderBrowserPathNotifier =
    StateNotifierProvider<FolderBrowserNotifier, String>((ref) {
  return FolderBrowserNotifier();
});

class FolderBrowserNotifier extends StateNotifier<String> {
  FolderBrowserNotifier() : super('root');

  void navigateTo(String? path) {
    state = path ?? 'root';
  }

  void goBack() {
    if (state == 'root') return;
    if (state == 'PHOTOS_SYSTEM') {
      state = 'root';
      return;
    }
    
    // Go to parent directory
    final parts = state.split('/');
    if (parts.length > 1) {
      parts.removeLast();
      state = parts.join('/');
    } else {
      state = 'root';
    }
  }

  void reset() {
    state = 'root';
  }
}

// List folders in the current browsing path
final folderBrowserProvider =
    FutureProvider<List<ShareableDirectory>>((ref) async {
  final service = ref.watch(lanShareServiceProvider);
  final currentPath = ref.watch(folderBrowserPathNotifier);
  return service.listFoldersInPath(
    currentPath == 'root' ? null : currentPath,
  );
});

class LanShareNotifier extends Notifier<LanServerInfo> {
  @override
  LanServerInfo build() => LanServerInfo.idle;

  Future<void> startServer({String? sharePath}) async {
    state = state.copyWith(status: ServerStatus.starting);
    final service = ref.read(lanShareServiceProvider);
    final info = await service.startServer(sharePath: sharePath);
    state = info;
  }

  Future<void> stopServer() async {
    final service = ref.read(lanShareServiceProvider);
    await service.stopServer();
    state = LanServerInfo.idle;
  }

  void toggleServer() {
    if (state.isRunning) {
      stopServer();
    } else {
      startServer();
    }
  }

  void changeSharePath(String? newPath) {
    if (state.isRunning) {
      stopServer().then((_) => startServer(sharePath: newPath));
    }
  }
}

final lanShareProvider = NotifierProvider<LanShareNotifier, LanServerInfo>(
  LanShareNotifier.new,
);
