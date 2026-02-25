import 'package:photo_manager/photo_manager.dart';

// ─── Media Asset Model ─────────────────────────────────────
class MediaAsset {
  const MediaAsset({
    required this.entity,
    this.exifData,
    this.isVaulted = false,
  });

  final AssetEntity entity;
  final Map<String, dynamic>? exifData;
  final bool isVaulted;

  String get id => entity.id;
  AssetType get type => entity.type;
  DateTime get createDateTime => entity.createDateTime;
  int get width => entity.width;
  int get height => entity.height;
  String? get latitude => entity.latitude?.toString();
  String? get longitude => entity.longitude?.toString();
  Duration? get videoDuration => entity.videoDuration;

  MediaAsset copyWith({
    AssetEntity? entity,
    Map<String, dynamic>? exifData,
    bool? isVaulted,
  }) {
    return MediaAsset(
      entity: entity ?? this.entity,
      exifData: exifData ?? this.exifData,
      isVaulted: isVaulted ?? this.isVaulted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MediaAsset && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ─── Media Group (by Date) ─────────────────────────────────
class MediaGroup {
  const MediaGroup({required this.date, required this.assets});

  final DateTime date;
  final List<MediaAsset> assets;

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── LAN Server State ──────────────────────────────────────
enum ServerStatus { stopped, starting, running, error }

class LanServerInfo {
  const LanServerInfo({
    required this.status,
    this.ipAddress,
    this.port,
    this.errorMessage,
  });

  final ServerStatus status;
  final String? ipAddress;
  final int? port;
  final String? errorMessage;

  bool get isRunning => status == ServerStatus.running;

  String get url => isRunning ? 'http://$ipAddress:$port' : '';

  static const LanServerInfo idle = LanServerInfo(status: ServerStatus.stopped);
}

// ─── Vault State ───────────────────────────────────────────
enum VaultAuthState { locked, unlocking, unlocked, error }

class VaultState {
  const VaultState({
    required this.authState,
    this.assets = const [],
    this.errorMessage,
  });

  final VaultAuthState authState;
  final List<MediaAsset> assets;
  final String? errorMessage;

  bool get isUnlocked => authState == VaultAuthState.unlocked;

  VaultState copyWith({
    VaultAuthState? authState,
    List<MediaAsset>? assets,
    String? errorMessage,
  }) {
    return VaultState(
      authState: authState ?? this.authState,
      assets: assets ?? this.assets,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static const VaultState initial = VaultState(
    authState: VaultAuthState.locked,
  );
}

// ─── App Settings Model ────────────────────────────────────
class AppSettings {
  const AppSettings({
    this.isDarkMode = true,
    this.isPerformanceMode = false,
    this.gridColumns = 3,
    this.crashReportingOptIn = false,
    this.onboardingComplete = false,
    this.vaultEnabled = false,
  });

  final bool isDarkMode;
  final bool isPerformanceMode;
  final int gridColumns;
  final bool crashReportingOptIn;
  final bool onboardingComplete;
  final bool vaultEnabled;

  AppSettings copyWith({
    bool? isDarkMode,
    bool? isPerformanceMode,
    int? gridColumns,
    bool? crashReportingOptIn,
    bool? onboardingComplete,
    bool? vaultEnabled,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPerformanceMode: isPerformanceMode ?? this.isPerformanceMode,
      gridColumns: gridColumns ?? this.gridColumns,
      crashReportingOptIn: crashReportingOptIn ?? this.crashReportingOptIn,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      vaultEnabled: vaultEnabled ?? this.vaultEnabled,
    );
  }
}
