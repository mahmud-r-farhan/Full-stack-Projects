import 'package:photo_manager/photo_manager.dart';

// ─── Media Asset Model ─────────────────────────────────────
class MediaAsset {
  const MediaAsset({
    this.entity,
    String? customId,
    AssetType? customType,
    DateTime? customCreateDateTime,
    int? customWidth,
    int? customHeight,
    Duration? customVideoDuration,
    this.exifData,
    this.isVaulted = false,
    this.vaultFilePath,
    this.vaultThumbPath,
    this.originalFilePath,
  })  : _customId = customId,
        _customType = customType,
        _customCreateDateTime = customCreateDateTime,
        _customWidth = customWidth,
        _customHeight = customHeight,
        _customVideoDuration = customVideoDuration,
        assert(
          entity != null || customId != null,
          'Either entity or customId must be provided',
        );

  final AssetEntity? entity;
  final String? _customId;
  final AssetType? _customType;
  final DateTime? _customCreateDateTime;
  final int? _customWidth;
  final int? _customHeight;
  final Duration? _customVideoDuration;

  final Map<String, dynamic>? exifData;
  final bool isVaulted;
  final String? vaultFilePath;
  final String? vaultThumbPath;
  final String? originalFilePath;

  String get id => entity?.id ?? _customId!;
  AssetType get type => entity?.type ?? _customType ?? AssetType.image;
  DateTime get createDateTime =>
      entity?.createDateTime ?? _customCreateDateTime ?? DateTime.now();
  int get width => entity?.width ?? _customWidth ?? 0;
  int get height => entity?.height ?? _customHeight ?? 0;
  String? get latitude => entity?.latitude?.toString();
  String? get longitude => entity?.longitude?.toString();
  Duration? get videoDuration => entity?.videoDuration ?? _customVideoDuration;

  MediaAsset copyWith({
    AssetEntity? entity,
    String? customId,
    AssetType? customType,
    DateTime? customCreateDateTime,
    int? customWidth,
    int? customHeight,
    Duration? customVideoDuration,
    Map<String, dynamic>? exifData,
    bool? isVaulted,
    String? vaultFilePath,
    String? vaultThumbPath,
    String? originalFilePath,
  }) {
    return MediaAsset(
      entity: entity ?? this.entity,
      customId: customId ?? _customId,
      customType: customType ?? _customType,
      customCreateDateTime: customCreateDateTime ?? _customCreateDateTime,
      customWidth: customWidth ?? _customWidth,
      customHeight: customHeight ?? _customHeight,
      customVideoDuration: customVideoDuration ?? _customVideoDuration,
      exifData: exifData ?? this.exifData,
      isVaulted: isVaulted ?? this.isVaulted,
      vaultFilePath: vaultFilePath ?? this.vaultFilePath,
      vaultThumbPath: vaultThumbPath ?? this.vaultThumbPath,
      originalFilePath: originalFilePath ?? this.originalFilePath,
    );
  }

  Map<String, dynamic> toVaultMetadataMap() {
    return {
      'id': id,
      'type': type == AssetType.video ? 'video' : 'image',
      'createDateTime': createDateTime.toIso8601String(),
      'width': width,
      'height': height,
      'videoDurationMs': videoDuration?.inMilliseconds,
      'vaultFilePath': vaultFilePath,
      'vaultThumbPath': vaultThumbPath,
      'originalFilePath': originalFilePath,
    };
  }

  factory MediaAsset.fromVaultMetadataMap(Map<String, dynamic> map) {
    return MediaAsset(
      customId: map['id'] as String,
      customType:
          map['type'] == 'video' ? AssetType.video : AssetType.image,
      customCreateDateTime: map['createDateTime'] != null
          ? DateTime.tryParse(map['createDateTime'] as String)
          : null,
      customWidth: map['width'] as int?,
      customHeight: map['height'] as int?,
      customVideoDuration: map['videoDurationMs'] != null
          ? Duration(milliseconds: map['videoDurationMs'] as int)
          : null,
      isVaulted: true,
      vaultFilePath: map['vaultFilePath'] as String?,
      vaultThumbPath: map['vaultThumbPath'] as String?,
      originalFilePath: map['originalFilePath'] as String?,
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
  double get spaceUsagePercent {
    if (hasSpaceInfo) {
      return (availableSpace! / totalSpace!) * 100;
    }
    return 0;
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
    this.isLiquidDesign = true,
    this.gridColumns = 3,
    this.crashReportingOptIn = false,
    this.onboardingComplete = false,
    this.vaultEnabled = false,
  });

  final bool isDarkMode;
  final bool isPerformanceMode;
  final bool isLiquidDesign;
  final int gridColumns;
  final bool crashReportingOptIn;
  final bool onboardingComplete;
  final bool vaultEnabled;

  AppSettings copyWith({
    bool? isDarkMode,
    bool? isPerformanceMode,
    bool? isLiquidDesign,
    int? gridColumns,
    bool? crashReportingOptIn,
    bool? onboardingComplete,
    bool? vaultEnabled,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPerformanceMode: isPerformanceMode ?? this.isPerformanceMode,
      isLiquidDesign: isLiquidDesign ?? this.isLiquidDesign,
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
    if (totalSize < 1024) {
      return '$totalSize B';
    }
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
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
