import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'backup_archive.g.dart';

/// Represents a backup archive containing family data with encryption and metadata.
@JsonSerializable()
class BackupArchive extends Equatable {
  /// Unique identifier for the backup archive
  final String id;

  /// ID of the family this backup belongs to
  final String familyId;

  /// ID of the user who created this backup
  final String createdBy;

  /// Current status of the backup operation
  final BackupStatus status;

  /// When the backup was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the backup was completed (if successful)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? completedAt;

  /// When this backup expires and should be deleted
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? expiresAt;

  /// Backup metadata and configuration
  final BackupMetadata metadata;

  /// Encryption settings for this backup
  final EncryptionSettings encryption;

  /// List of data types included in this backup
  final List<BackupDataType> includedDataTypes;

  /// Total size of the backup in bytes
  final int? totalSizeBytes;

  /// Number of files in the backup
  final int? fileCount;

  /// URL or path to the backup file
  final String? backupUrl;

  /// Checksum for integrity verification
  final String? checksum;

  /// Compression settings used
  final CompressionSettings? compression;

  /// Error message if backup failed
  final String? errorMessage;

  /// Progress percentage (0-100) for ongoing backups
  final int progressPercent;

  const BackupArchive({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
    required this.metadata,
    required this.encryption,
    required this.includedDataTypes,
    this.totalSizeBytes,
    this.fileCount,
    this.backupUrl,
    this.checksum,
    this.compression,
    this.errorMessage,
    this.progressPercent = 0,
  });

  /// Creates a BackupArchive instance from JSON
  factory BackupArchive.fromJson(Map<String, dynamic> json) =>
      _$BackupArchiveFromJson(json);

  /// Converts BackupArchive instance to JSON
  Map<String, dynamic> toJson() => _$BackupArchiveToJson(this);

  /// Creates a copy of BackupArchive with modified fields
  BackupArchive copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    BackupStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    BackupMetadata? metadata,
    EncryptionSettings? encryption,
    List<BackupDataType>? includedDataTypes,
    int? totalSizeBytes,
    int? fileCount,
    String? backupUrl,
    String? checksum,
    CompressionSettings? compression,
    String? errorMessage,
    int? progressPercent,
  }) {
    return BackupArchive(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      encryption: encryption ?? this.encryption,
      includedDataTypes: includedDataTypes ?? this.includedDataTypes,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      fileCount: fileCount ?? this.fileCount,
      backupUrl: backupUrl ?? this.backupUrl,
      checksum: checksum ?? this.checksum,
      compression: compression ?? this.compression,
      errorMessage: errorMessage ?? this.errorMessage,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        createdBy,
        status,
        createdAt,
        completedAt,
        expiresAt,
        metadata,
        encryption,
        includedDataTypes,
        totalSizeBytes,
        fileCount,
        backupUrl,
        checksum,
        compression,
        errorMessage,
        progressPercent,
      ];

  @override
  String toString() {
    return 'BackupArchive(id: $id, familyId: $familyId, status: $status, '
           'progressPercent: $progressPercent, totalSizeBytes: $totalSizeBytes)';
  }

  /// Helper methods for DateTime serialization
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  static DateTime? _nullableDateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date) : null;
  static String? _nullableDateTimeToJson(DateTime? date) =>
      date?.toIso8601String();

  /// Convenience getters
  bool get isCompleted => status == BackupStatus.completed;
  bool get isFailed => status == BackupStatus.failed;
  bool get isInProgress => status == BackupStatus.inProgress;
  bool get hasExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isEncrypted => encryption.enabled;

  /// Calculate backup duration
  Duration? get backupDuration {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }

  /// Get formatted size string
  String get formattedSize {
    if (totalSizeBytes == null) return 'Unknown';
    final bytes = totalSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Status of a backup operation
enum BackupStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
}

/// Types of data that can be included in a backup
enum BackupDataType {
  @JsonValue('notes')
  notes,
  @JsonValue('shared_notes')
  sharedNotes,
  @JsonValue('family_settings')
  familySettings,
  @JsonValue('user_preferences')
  userPreferences,
  @JsonValue('voice_sessions')
  voiceSessions,
  @JsonValue('attachments')
  attachments,
  @JsonValue('metadata')
  metadata,
  @JsonValue('notifications')
  notifications,
}

/// Metadata for backup operations
@JsonSerializable()
class BackupMetadata extends Equatable {
  /// Human-readable name for the backup
  final String name;

  /// Optional description of the backup
  final String? description;

  /// Version of the backup format
  final String version;

  /// Application version that created the backup
  final String appVersion;

  /// Platform information
  final PlatformInfo platform;

  /// Statistics about the backup content
  final BackupStatistics statistics;

  /// Custom tags for organization
  final List<String> tags;

  /// Whether this is an automatic or manual backup
  final BackupTrigger trigger;

  /// Retention policy for this backup
  final RetentionPolicy retentionPolicy;

  const BackupMetadata({
    required this.name,
    this.description,
    required this.version,
    required this.appVersion,
    required this.platform,
    required this.statistics,
    this.tags = const [],
    required this.trigger,
    required this.retentionPolicy,
  });

  /// Creates a BackupMetadata instance from JSON
  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);

  /// Converts BackupMetadata instance to JSON
  Map<String, dynamic> toJson() => _$BackupMetadataToJson(this);

  /// Creates a copy of BackupMetadata with modified fields
  BackupMetadata copyWith({
    String? name,
    String? description,
    String? version,
    String? appVersion,
    PlatformInfo? platform,
    BackupStatistics? statistics,
    List<String>? tags,
    BackupTrigger? trigger,
    RetentionPolicy? retentionPolicy,
  }) {
    return BackupMetadata(
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      statistics: statistics ?? this.statistics,
      tags: tags ?? this.tags,
      trigger: trigger ?? this.trigger,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
    );
  }

  @override
  List<Object?> get props => [
        name,
        description,
        version,
        appVersion,
        platform,
        statistics,
        tags,
        trigger,
        retentionPolicy,
      ];
}

/// Platform information for backup
@JsonSerializable()
class PlatformInfo extends Equatable {
  /// Operating system
  final String operatingSystem;

  /// OS version
  final String osVersion;

  /// Device model
  final String deviceModel;

  /// Additional platform details
  final Map<String, dynamic> details;

  const PlatformInfo({
    required this.operatingSystem,
    required this.osVersion,
    required this.deviceModel,
    this.details = const {},
  });

  /// Creates a PlatformInfo instance from JSON
  factory PlatformInfo.fromJson(Map<String, dynamic> json) =>
      _$PlatformInfoFromJson(json);

  /// Converts PlatformInfo instance to JSON
  Map<String, dynamic> toJson() => _$PlatformInfoToJson(this);

  @override
  List<Object?> get props => [operatingSystem, osVersion, deviceModel, details];
}

/// Statistics about backup content
@JsonSerializable()
class BackupStatistics extends Equatable {
  /// Number of notes included
  final int noteCount;

  /// Number of shared notes included
  final int sharedNoteCount;

  /// Number of voice sessions included
  final int voiceSessionCount;

  /// Number of attachments included
  final int attachmentCount;

  /// Total data size before compression
  final int uncompressedSize;

  /// Compression ratio achieved
  final double compressionRatio;

  /// Processing time in milliseconds
  final int processingTimeMs;

  const BackupStatistics({
    required this.noteCount,
    required this.sharedNoteCount,
    required this.voiceSessionCount,
    required this.attachmentCount,
    required this.uncompressedSize,
    required this.compressionRatio,
    required this.processingTimeMs,
  });

  /// Creates a BackupStatistics instance from JSON
  factory BackupStatistics.fromJson(Map<String, dynamic> json) =>
      _$BackupStatisticsFromJson(json);

  /// Converts BackupStatistics instance to JSON
  Map<String, dynamic> toJson() => _$BackupStatisticsToJson(this);

  @override
  List<Object?> get props => [
        noteCount,
        sharedNoteCount,
        voiceSessionCount,
        attachmentCount,
        uncompressedSize,
        compressionRatio,
        processingTimeMs,
      ];

  /// Get total item count
  int get totalItems => noteCount + sharedNoteCount + voiceSessionCount + attachmentCount;
}

/// Backup trigger types
enum BackupTrigger {
  @JsonValue('manual')
  manual,
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('automatic')
  automatic,
  @JsonValue('system')
  system,
}

/// Retention policy for backups
@JsonSerializable()
class RetentionPolicy extends Equatable {
  /// How long to keep the backup
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration retentionPeriod;

  /// Whether to delete automatically when expired
  final bool autoDelete;

  /// Minimum number of backups to keep
  final int minimumBackupsToKeep;

  /// Maximum number of backups to keep
  final int maximumBackupsToKeep;

  const RetentionPolicy({
    required this.retentionPeriod,
    this.autoDelete = true,
    this.minimumBackupsToKeep = 1,
    this.maximumBackupsToKeep = 10,
  });

  /// Creates a RetentionPolicy instance from JSON
  factory RetentionPolicy.fromJson(Map<String, dynamic> json) =>
      _$RetentionPolicyFromJson(json);

  /// Converts RetentionPolicy instance to JSON
  Map<String, dynamic> toJson() => _$RetentionPolicyToJson(this);

  @override
  List<Object?> get props => [
        retentionPeriod,
        autoDelete,
        minimumBackupsToKeep,
        maximumBackupsToKeep,
      ];

  /// Helper methods for Duration serialization
  static Duration _durationFromJson(String duration) {
    // Parse ISO 8601 duration format (e.g., "P30D" for 30 days)
    final regex = RegExp(r'P(\d+)D');
    final match = regex.firstMatch(duration);
    if (match != null) {
      final days = int.parse(match.group(1)!);
      return Duration(days: days);
    }
    return const Duration(days: 30); // Default fallback
  }

  static String _durationToJson(Duration duration) {
    return 'P${duration.inDays}D';
  }
}

/// Encryption settings for backups
@JsonSerializable()
class EncryptionSettings extends Equatable {
  /// Whether encryption is enabled
  final bool enabled;

  /// Encryption algorithm used
  final EncryptionAlgorithm algorithm;

  /// Key derivation method
  final KeyDerivationMethod keyDerivation;

  /// Number of iterations for key derivation
  final int iterations;

  /// Salt for key derivation (base64 encoded)
  final String? salt;

  /// Additional encryption parameters
  final Map<String, dynamic> parameters;

  /// Whether to encrypt metadata as well
  final bool encryptMetadata;

  const EncryptionSettings({
    required this.enabled,
    this.algorithm = EncryptionAlgorithm.aes256,
    this.keyDerivation = KeyDerivationMethod.pbkdf2,
    this.iterations = 100000,
    this.salt,
    this.parameters = const {},
    this.encryptMetadata = true,
  });

  /// Creates an EncryptionSettings instance from JSON
  factory EncryptionSettings.fromJson(Map<String, dynamic> json) =>
      _$EncryptionSettingsFromJson(json);

  /// Converts EncryptionSettings instance to JSON
  Map<String, dynamic> toJson() => _$EncryptionSettingsToJson(this);

  /// Creates a copy of EncryptionSettings with modified fields
  EncryptionSettings copyWith({
    bool? enabled,
    EncryptionAlgorithm? algorithm,
    KeyDerivationMethod? keyDerivation,
    int? iterations,
    String? salt,
    Map<String, dynamic>? parameters,
    bool? encryptMetadata,
  }) {
    return EncryptionSettings(
      enabled: enabled ?? this.enabled,
      algorithm: algorithm ?? this.algorithm,
      keyDerivation: keyDerivation ?? this.keyDerivation,
      iterations: iterations ?? this.iterations,
      salt: salt ?? this.salt,
      parameters: parameters ?? this.parameters,
      encryptMetadata: encryptMetadata ?? this.encryptMetadata,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        algorithm,
        keyDerivation,
        iterations,
        salt,
        parameters,
        encryptMetadata,
      ];

  /// Get security level description
  String get securityLevel {
    if (!enabled) return 'None';
    switch (algorithm) {
      case EncryptionAlgorithm.aes128:
        return 'Standard';
      case EncryptionAlgorithm.aes256:
        return 'High';
      case EncryptionAlgorithm.chacha20:
        return 'High';
    }
  }
}

/// Encryption algorithms supported
enum EncryptionAlgorithm {
  @JsonValue('aes128')
  aes128,
  @JsonValue('aes256')
  aes256,
  @JsonValue('chacha20')
  chacha20,
}

/// Key derivation methods
enum KeyDerivationMethod {
  @JsonValue('pbkdf2')
  pbkdf2,
  @JsonValue('scrypt')
  scrypt,
  @JsonValue('argon2')
  argon2,
}

/// Compression settings for backups
@JsonSerializable()
class CompressionSettings extends Equatable {
  /// Whether compression is enabled
  final bool enabled;

  /// Compression algorithm used
  final CompressionAlgorithm algorithm;

  /// Compression level (1-9, higher = better compression but slower)
  final int level;

  /// Additional compression parameters
  final Map<String, dynamic> parameters;

  const CompressionSettings({
    this.enabled = true,
    this.algorithm = CompressionAlgorithm.gzip,
    this.level = 6,
    this.parameters = const {},
  });

  /// Creates a CompressionSettings instance from JSON
  factory CompressionSettings.fromJson(Map<String, dynamic> json) =>
      _$CompressionSettingsFromJson(json);

  /// Converts CompressionSettings instance to JSON
  Map<String, dynamic> toJson() => _$CompressionSettingsToJson(this);

  @override
  List<Object?> get props => [enabled, algorithm, level, parameters];

  /// Get compression description
  String get description {
    if (!enabled) return 'No compression';
    return '${algorithm.name.toUpperCase()} level $level';
  }
}

/// Compression algorithms supported
enum CompressionAlgorithm {
  @JsonValue('gzip')
  gzip,
  @JsonValue('zlib')
  zlib,
  @JsonValue('lz4')
  lz4,
  @JsonValue('zstd')
  zstd,
}