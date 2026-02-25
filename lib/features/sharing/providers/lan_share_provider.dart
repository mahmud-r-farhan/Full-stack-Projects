import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../services/lan_share_service.dart';

// ═══════════════════════════════════════════════════════════
//  LAN Sharing Providers
// ═══════════════════════════════════════════════════════════

final lanShareServiceProvider = Provider<LanShareService>((ref) {
  final service = LanShareService();
  ref.onDispose(service.dispose);
  return service;
});

class LanShareNotifier extends Notifier<LanServerInfo> {
  @override
  LanServerInfo build() => LanServerInfo.idle;

  Future<void> startServer() async {
    state = const LanServerInfo(status: ServerStatus.starting);
    final service = ref.read(lanShareServiceProvider);
    final info = await service.startServer();
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
}

final lanShareProvider = NotifierProvider<LanShareNotifier, LanServerInfo>(
  LanShareNotifier.new,
);
