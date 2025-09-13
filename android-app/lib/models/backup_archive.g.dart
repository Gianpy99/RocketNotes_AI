// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_archive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackupArchive _$BackupArchiveFromJson(Map<String, dynamic> json) =>
    BackupArchive(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      createdBy: json['createdBy'] as String,
      status: $enumDecode(_$BackupStatusEnumMap, json['status']),
      createdAt: BackupArchive._dateTimeFromJson(json['createdAt'] as String),
      completedAt: BackupArchive._nullableDateTimeFromJson(
          json['completedAt'] as String?),
      expiresAt:
          BackupArchive._nullableDateTimeFromJson(json['expiresAt'] as String?),
      metadata:
          BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      encryption: EncryptionSettings.fromJson(
          json['encryption'] as Map<String, dynamic>),
      includedDataTypes: (json['includedDataTypes'] as List<dynamic>)
          .map((e) => $enumDecode(_$BackupDataTypeEnumMap, e))
          .toList(),
      totalSizeBytes: (json['totalSizeBytes'] as num?)?.toInt(),
      fileCount: (json['fileCount'] as num?)?.toInt(),
      backupUrl: json['backupUrl'] as String?,
      checksum: json['checksum'] as String?,
      compression: json['compression'] == null
          ? null
          : CompressionSettings.fromJson(
              json['compression'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String?,
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BackupArchiveToJson(BackupArchive instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'createdBy': instance.createdBy,
      'status': _$BackupStatusEnumMap[instance.status]!,
      'createdAt': BackupArchive._dateTimeToJson(instance.createdAt),
      'completedAt':
          BackupArchive._nullableDateTimeToJson(instance.completedAt),
      'expiresAt': BackupArchive._nullableDateTimeToJson(instance.expiresAt),
      'metadata': instance.metadata,
      'encryption': instance.encryption,
      'includedDataTypes': instance.includedDataTypes
          .map((e) => _$BackupDataTypeEnumMap[e]!)
          .toList(),
      'totalSizeBytes': instance.totalSizeBytes,
      'fileCount': instance.fileCount,
      'backupUrl': instance.backupUrl,
      'checksum': instance.checksum,
      'compression': instance.compression,
      'errorMessage': instance.errorMessage,
      'progressPercent': instance.progressPercent,
    };

const _$BackupStatusEnumMap = {
  BackupStatus.pending: 'pending',
  BackupStatus.inProgress: 'in_progress',
  BackupStatus.completed: 'completed',
  BackupStatus.failed: 'failed',
  BackupStatus.cancelled: 'cancelled',
  BackupStatus.expired: 'expired',
};

const _$BackupDataTypeEnumMap = {
  BackupDataType.notes: 'notes',
  BackupDataType.sharedNotes: 'shared_notes',
  BackupDataType.familySettings: 'family_settings',
  BackupDataType.userPreferences: 'user_preferences',
  BackupDataType.voiceSessions: 'voice_sessions',
  BackupDataType.attachments: 'attachments',
  BackupDataType.metadata: 'metadata',
  BackupDataType.notifications: 'notifications',
};

BackupMetadata _$BackupMetadataFromJson(Map<String, dynamic> json) =>
    BackupMetadata(
      name: json['name'] as String,
      description: json['description'] as String?,
      version: json['version'] as String,
      appVersion: json['appVersion'] as String,
      platform: PlatformInfo.fromJson(json['platform'] as Map<String, dynamic>),
      statistics:
          BackupStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      trigger: $enumDecode(_$BackupTriggerEnumMap, json['trigger']),
      retentionPolicy: RetentionPolicy.fromJson(
          json['retentionPolicy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BackupMetadataToJson(BackupMetadata instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
      'appVersion': instance.appVersion,
      'platform': instance.platform,
      'statistics': instance.statistics,
      'tags': instance.tags,
      'trigger': _$BackupTriggerEnumMap[instance.trigger]!,
      'retentionPolicy': instance.retentionPolicy,
    };

const _$BackupTriggerEnumMap = {
  BackupTrigger.manual: 'manual',
  BackupTrigger.scheduled: 'scheduled',
  BackupTrigger.automatic: 'automatic',
  BackupTrigger.system: 'system',
};

PlatformInfo _$PlatformInfoFromJson(Map<String, dynamic> json) => PlatformInfo(
      operatingSystem: json['operatingSystem'] as String,
      osVersion: json['osVersion'] as String,
      deviceModel: json['deviceModel'] as String,
      details: json['details'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$PlatformInfoToJson(PlatformInfo instance) =>
    <String, dynamic>{
      'operatingSystem': instance.operatingSystem,
      'osVersion': instance.osVersion,
      'deviceModel': instance.deviceModel,
      'details': instance.details,
    };

BackupStatistics _$BackupStatisticsFromJson(Map<String, dynamic> json) =>
    BackupStatistics(
      noteCount: (json['noteCount'] as num).toInt(),
      sharedNoteCount: (json['sharedNoteCount'] as num).toInt(),
      voiceSessionCount: (json['voiceSessionCount'] as num).toInt(),
      attachmentCount: (json['attachmentCount'] as num).toInt(),
      uncompressedSize: (json['uncompressedSize'] as num).toInt(),
      compressionRatio: (json['compressionRatio'] as num).toDouble(),
      processingTimeMs: (json['processingTimeMs'] as num).toInt(),
    );

Map<String, dynamic> _$BackupStatisticsToJson(BackupStatistics instance) =>
    <String, dynamic>{
      'noteCount': instance.noteCount,
      'sharedNoteCount': instance.sharedNoteCount,
      'voiceSessionCount': instance.voiceSessionCount,
      'attachmentCount': instance.attachmentCount,
      'uncompressedSize': instance.uncompressedSize,
      'compressionRatio': instance.compressionRatio,
      'processingTimeMs': instance.processingTimeMs,
    };

RetentionPolicy _$RetentionPolicyFromJson(Map<String, dynamic> json) =>
    RetentionPolicy(
      retentionPeriod:
          RetentionPolicy._durationFromJson(json['retentionPeriod'] as String),
      autoDelete: json['autoDelete'] as bool? ?? true,
      minimumBackupsToKeep:
          (json['minimumBackupsToKeep'] as num?)?.toInt() ?? 1,
      maximumBackupsToKeep:
          (json['maximumBackupsToKeep'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$RetentionPolicyToJson(RetentionPolicy instance) =>
    <String, dynamic>{
      'retentionPeriod':
          RetentionPolicy._durationToJson(instance.retentionPeriod),
      'autoDelete': instance.autoDelete,
      'minimumBackupsToKeep': instance.minimumBackupsToKeep,
      'maximumBackupsToKeep': instance.maximumBackupsToKeep,
    };

EncryptionSettings _$EncryptionSettingsFromJson(Map<String, dynamic> json) =>
    EncryptionSettings(
      enabled: json['enabled'] as bool,
      algorithm: $enumDecodeNullable(
              _$EncryptionAlgorithmEnumMap, json['algorithm']) ??
          EncryptionAlgorithm.aes256,
      keyDerivation: $enumDecodeNullable(
              _$KeyDerivationMethodEnumMap, json['keyDerivation']) ??
          KeyDerivationMethod.pbkdf2,
      iterations: (json['iterations'] as num?)?.toInt() ?? 100000,
      salt: json['salt'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
      encryptMetadata: json['encryptMetadata'] as bool? ?? true,
    );

Map<String, dynamic> _$EncryptionSettingsToJson(EncryptionSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'algorithm': _$EncryptionAlgorithmEnumMap[instance.algorithm]!,
      'keyDerivation': _$KeyDerivationMethodEnumMap[instance.keyDerivation]!,
      'iterations': instance.iterations,
      'salt': instance.salt,
      'parameters': instance.parameters,
      'encryptMetadata': instance.encryptMetadata,
    };

const _$EncryptionAlgorithmEnumMap = {
  EncryptionAlgorithm.aes128: 'aes128',
  EncryptionAlgorithm.aes256: 'aes256',
  EncryptionAlgorithm.chacha20: 'chacha20',
};

const _$KeyDerivationMethodEnumMap = {
  KeyDerivationMethod.pbkdf2: 'pbkdf2',
  KeyDerivationMethod.scrypt: 'scrypt',
  KeyDerivationMethod.argon2: 'argon2',
};

CompressionSettings _$CompressionSettingsFromJson(Map<String, dynamic> json) =>
    CompressionSettings(
      enabled: json['enabled'] as bool? ?? true,
      algorithm: $enumDecodeNullable(
              _$CompressionAlgorithmEnumMap, json['algorithm']) ??
          CompressionAlgorithm.gzip,
      level: (json['level'] as num?)?.toInt() ?? 6,
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CompressionSettingsToJson(
        CompressionSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'algorithm': _$CompressionAlgorithmEnumMap[instance.algorithm]!,
      'level': instance.level,
      'parameters': instance.parameters,
    };

const _$CompressionAlgorithmEnumMap = {
  CompressionAlgorithm.gzip: 'gzip',
  CompressionAlgorithm.zlib: 'zlib',
  CompressionAlgorithm.lz4: 'lz4',
  CompressionAlgorithm.zstd: 'zstd',
};
