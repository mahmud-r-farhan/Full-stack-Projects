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
