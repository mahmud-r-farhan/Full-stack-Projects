import 'package:photo_manager/photo_manager.dart';

// ─── Media Asset Model ─────────────────────────────────────
class MediaAsset {
  const MediaAsset({
    required this.entity,
    this.exifData,
    this.isVaulted = false,
    this.vaultFilePath,
  });

  final AssetEntity entity;
  final Map<String, dynamic>? exifData;
  final bool isVaulted;
  final String? vaultFilePath;

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
    String? vaultFilePath,
  }) {
    return MediaAsset(
      entity: entity ?? this.entity,
      exifData: exifData ?? this.exifData,
      isVaulted: isVaulted ?? this.isVaulted,
      vaultFilePath: vaultFilePath ?? this.vaultFilePath,
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

// ─── Shareable Directory Model ────────────────────────────
enum StorageType { systemPhotos, downloads, documents, externalStorage, otg }

class ShareableDirectory {
  const ShareableDirectory({
    required this.name,
    required this.path,
    required this.type,
    required this.displayPath,
    this.availableSpace,
    this.totalSpace,
  });

  final String name;
  final String path;
  final StorageType type;
  final String displayPath;
  final int? availableSpace;
  final int? totalSpace;

  String get icon {
    switch (type) {
      case StorageType.systemPhotos:
        return '📱';
      case StorageType.downloads:
        return '⬇️';
      case StorageType.documents:
        return '📄';
      case StorageType.externalStorage:
        return '💾';
      case StorageType.otg:
        return '🔌';
    }
  }

  bool get hasSpaceInfo => availableSpace != null && totalSpace != null;
  double get spaceUsagePercent =>
      hasSpaceInfo ? (availableSpace! / totalSpace!) * 100 : 0;
}

// ─── LAN Server State ──────────────────────────────────────
enum ServerStatus { stopped, starting, running, error }

class LanServerInfo {
  const LanServerInfo({
    required this.status,
    this.ipAddress,
    this.port,
    this.errorMessage,
    this.selectedSharePath,
    this.selectedShareName = 'All Photos',
  });

  final ServerStatus status;
  final String? ipAddress;
  final int? port;
  final String? errorMessage;
  final String? selectedSharePath;
  final String selectedShareName;

  bool get isRunning => status == ServerStatus.running;
  String get url => isRunning ? 'http://$ipAddress:$port' : '';

  LanServerInfo copyWith({
    ServerStatus? status,
    String? ipAddress,
    int? port,
    String? errorMessage,
    String? selectedSharePath,
    String? selectedShareName,
  }) {
    return LanServerInfo(
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedSharePath: selectedSharePath ?? this.selectedSharePath,
      selectedShareName: selectedShareName ?? this.selectedShareName,
    );
  }

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

// ─── Vault Statistics ───────────────────────────────────────
class VaultStats {
  const VaultStats({
    required this.itemCount,
    required this.totalSize,
    required this.vaultPath,
  });

  final int itemCount;
  final int totalSize;
  final String vaultPath;

  String get sizeFormatted {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── Vault Exception ────────────────────────────────────────
class VaultException implements Exception {
  VaultException(this.message);
  
  final String message;

  @override
  String toString() => 'VaultException: $message';
}
