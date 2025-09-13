// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSession _$VoiceSessionFromJson(Map<String, dynamic> json) => VoiceSession(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      userId: json['userId'] as String,
      status: $enumDecode(_$VoiceSessionStatusEnumMap, json['status']),
      createdAt: VoiceSession._dateTimeFromJson(json['createdAt'] as String),
      startedAt:
          VoiceSession._nullableDateTimeFromJson(json['startedAt'] as String?),
      endedAt:
          VoiceSession._nullableDateTimeFromJson(json['endedAt'] as String?),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      transcription: json['transcription'] == null
          ? null
          : TranscriptionData.fromJson(
              json['transcription'] as Map<String, dynamic>),
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => AISuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata:
          SessionMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      audioUrl: json['audioUrl'] as String?,
      audioSizeBytes: (json['audioSizeBytes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VoiceSessionToJson(VoiceSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'userId': instance.userId,
      'status': _$VoiceSessionStatusEnumMap[instance.status]!,
      'createdAt': VoiceSession._dateTimeToJson(instance.createdAt),
      'startedAt': VoiceSession._nullableDateTimeToJson(instance.startedAt),
      'endedAt': VoiceSession._nullableDateTimeToJson(instance.endedAt),
      'durationMs': instance.durationMs,
      'transcription': instance.transcription,
      'suggestions': instance.suggestions,
      'metadata': instance.metadata,
      'audioUrl': instance.audioUrl,
      'audioSizeBytes': instance.audioSizeBytes,
    };

const _$VoiceSessionStatusEnumMap = {
  VoiceSessionStatus.pending: 'pending',
  VoiceSessionStatus.recording: 'recording',
  VoiceSessionStatus.processing: 'processing',
  VoiceSessionStatus.completed: 'completed',
  VoiceSessionStatus.failed: 'failed',
  VoiceSessionStatus.cancelled: 'cancelled',
};

TranscriptionData _$TranscriptionDataFromJson(Map<String, dynamic> json) =>
    TranscriptionData(
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      language: json['language'] as String,
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => WordSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: TranscriptionMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TranscriptionDataToJson(TranscriptionData instance) =>
    <String, dynamic>{
      'text': instance.text,
      'confidence': instance.confidence,
      'language': instance.language,
      'segments': instance.segments,
      'metadata': instance.metadata,
    };

WordSegment _$WordSegmentFromJson(Map<String, dynamic> json) => WordSegment(
      word: json['word'] as String,
      startTime: Duration(microseconds: (json['startTime'] as num).toInt()),
      endTime: Duration(microseconds: (json['endTime'] as num).toInt()),
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$WordSegmentToJson(WordSegment instance) =>
    <String, dynamic>{
      'word': instance.word,
      'startTime': instance.startTime.inMicroseconds,
      'endTime': instance.endTime.inMicroseconds,
      'confidence': instance.confidence,
    };

TranscriptionMetadata _$TranscriptionMetadataFromJson(
        Map<String, dynamic> json) =>
    TranscriptionMetadata(
      provider: json['provider'] as String,
      model: json['model'] as String,
      processingTimeMs: (json['processingTimeMs'] as num).toInt(),
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TranscriptionMetadataToJson(
        TranscriptionMetadata instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'model': instance.model,
      'processingTimeMs': instance.processingTimeMs,
      'parameters': instance.parameters,
    };

AISuggestion _$AISuggestionFromJson(Map<String, dynamic> json) => AISuggestion(
      id: json['id'] as String,
      type: $enumDecode(_$SuggestionTypeEnumMap, json['type']),
      title: json['title'] as String,
      content: json['content'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      action: json['action'] == null
          ? null
          : SuggestedAction.fromJson(json['action'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      priority:
          $enumDecodeNullable(_$SuggestionPriorityEnumMap, json['priority']) ??
              SuggestionPriority.medium,
    );

Map<String, dynamic> _$AISuggestionToJson(AISuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SuggestionTypeEnumMap[instance.type]!,
      'title': instance.title,
      'content': instance.content,
      'confidence': instance.confidence,
      'action': instance.action,
      'metadata': instance.metadata,
      'priority': _$SuggestionPriorityEnumMap[instance.priority]!,
    };

const _$SuggestionTypeEnumMap = {
  SuggestionType.noteCreation: 'note_creation',
  SuggestionType.taskExtraction: 'task_extraction',
  SuggestionType.reminderSetting: 'reminder_setting',
  SuggestionType.familySharing: 'family_sharing',
  SuggestionType.contentImprovement: 'content_improvement',
  SuggestionType.followUpAction: 'follow_up_action',
};

const _$SuggestionPriorityEnumMap = {
  SuggestionPriority.low: 'low',
  SuggestionPriority.medium: 'medium',
  SuggestionPriority.high: 'high',
  SuggestionPriority.urgent: 'urgent',
};

SuggestedAction _$SuggestedActionFromJson(Map<String, dynamic> json) =>
    SuggestedAction(
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      label: json['label'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ?? const {},
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$SuggestedActionToJson(SuggestedAction instance) =>
    <String, dynamic>{
      'type': _$ActionTypeEnumMap[instance.type]!,
      'label': instance.label,
      'parameters': instance.parameters,
      'icon': instance.icon,
    };

const _$ActionTypeEnumMap = {
  ActionType.createNote: 'create_note',
  ActionType.createTask: 'create_task',
  ActionType.setReminder: 'set_reminder',
  ActionType.shareWithFamily: 'share_with_family',
  ActionType.scheduleEvent: 'schedule_event',
  ActionType.sendMessage: 'send_message',
};

SessionMetadata _$SessionMetadataFromJson(Map<String, dynamic> json) =>
    SessionMetadata(
      device: DeviceInfo.fromJson(json['device'] as Map<String, dynamic>),
      quality: AudioQuality.fromJson(json['quality'] as Map<String, dynamic>),
      processing: ProcessingPreferences.fromJson(
          json['processing'] as Map<String, dynamic>),
      privacy:
          PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SessionMetadataToJson(SessionMetadata instance) =>
    <String, dynamic>{
      'device': instance.device,
      'quality': instance.quality,
      'processing': instance.processing,
      'privacy': instance.privacy,
    };

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      type: json['type'] as String,
      os: json['os'] as String,
      osVersion: json['osVersion'] as String,
      appVersion: json['appVersion'] as String,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'type': instance.type,
      'os': instance.os,
      'osVersion': instance.osVersion,
      'appVersion': instance.appVersion,
    };

AudioQuality _$AudioQualityFromJson(Map<String, dynamic> json) => AudioQuality(
      sampleRate: (json['sampleRate'] as num).toInt(),
      bitDepth: (json['bitDepth'] as num).toInt(),
      format: json['format'] as String,
      compressionQuality: (json['compressionQuality'] as num).toDouble(),
    );

Map<String, dynamic> _$AudioQualityToJson(AudioQuality instance) =>
    <String, dynamic>{
      'sampleRate': instance.sampleRate,
      'bitDepth': instance.bitDepth,
      'format': instance.format,
      'compressionQuality': instance.compressionQuality,
    };

ProcessingPreferences _$ProcessingPreferencesFromJson(
        Map<String, dynamic> json) =>
    ProcessingPreferences(
      enableAISuggestions: json['enableAISuggestions'] as bool? ?? true,
      storeAudio: json['storeAudio'] as bool? ?? false,
      realTimeTranscription: json['realTimeTranscription'] as bool? ?? true,
      language: json['language'] as String? ?? 'en-US',
      customParameters:
          json['customParameters'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ProcessingPreferencesToJson(
        ProcessingPreferences instance) =>
    <String, dynamic>{
      'enableAISuggestions': instance.enableAISuggestions,
      'storeAudio': instance.storeAudio,
      'realTimeTranscription': instance.realTimeTranscription,
      'language': instance.language,
      'customParameters': instance.customParameters,
    };

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      encryptAudio: json['encryptAudio'] as bool? ?? true,
      deleteAudioAfterProcessing:
          json['deleteAudioAfterProcessing'] as bool? ?? false,
      allowDataSharing: json['allowDataSharing'] as bool? ?? false,
      retentionPeriodDays: (json['retentionPeriodDays'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'encryptAudio': instance.encryptAudio,
      'deleteAudioAfterProcessing': instance.deleteAudioAfterProcessing,
      'allowDataSharing': instance.allowDataSharing,
      'retentionPeriodDays': instance.retentionPeriodDays,
    };
