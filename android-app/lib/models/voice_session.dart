import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_session.g.dart';

/// Represents a voice recording session with transcription and AI suggestions.
@JsonSerializable()
class VoiceSession extends Equatable {
  /// Unique identifier for the voice session
  final String id;

  /// ID of the family this session belongs to
  final String familyId;

  /// ID of the user who created this session
  final String userId;

  /// Current status of the voice session
  final VoiceSessionStatus status;

  /// When the session was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the session was started (if started)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? startedAt;

  /// When the session ended (if completed)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? endedAt;

  /// Duration of the recording in milliseconds
  final int? durationMs;

  /// Transcription data from the voice recording
  final TranscriptionData? transcription;

  /// AI-generated suggestions based on the transcription
  final List<AISuggestion> suggestions;

  /// Session metadata and configuration
  final SessionMetadata metadata;

  /// URL to the audio file (if stored)
  final String? audioUrl;

  /// Size of the audio file in bytes
  final int? audioSizeBytes;

  const VoiceSession({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.durationMs,
    this.transcription,
    this.suggestions = const [],
    required this.metadata,
    this.audioUrl,
    this.audioSizeBytes,
  });

  /// Creates a VoiceSession instance from JSON
  factory VoiceSession.fromJson(Map<String, dynamic> json) =>
      _$VoiceSessionFromJson(json);

  /// Converts VoiceSession instance to JSON
  Map<String, dynamic> toJson() => _$VoiceSessionToJson(this);

  /// Creates a copy of VoiceSession with modified fields
  VoiceSession copyWith({
    String? id,
    String? familyId,
    String? userId,
    VoiceSessionStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMs,
    TranscriptionData? transcription,
    List<AISuggestion>? suggestions,
    SessionMetadata? metadata,
    String? audioUrl,
    int? audioSizeBytes,
  }) {
    return VoiceSession(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMs: durationMs ?? this.durationMs,
      transcription: transcription ?? this.transcription,
      suggestions: suggestions ?? this.suggestions,
      metadata: metadata ?? this.metadata,
      audioUrl: audioUrl ?? this.audioUrl,
      audioSizeBytes: audioSizeBytes ?? this.audioSizeBytes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        userId,
        status,
        createdAt,
        startedAt,
        endedAt,
        durationMs,
        transcription,
        suggestions,
        metadata,
        audioUrl,
        audioSizeBytes,
      ];

  @override
  String toString() {
    return 'VoiceSession(id: $id, familyId: $familyId, userId: $userId, '
           'status: $status, durationMs: $durationMs)';
  }

  /// Helper methods for DateTime serialization
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  static DateTime? _nullableDateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date) : null;
  static String? _nullableDateTimeToJson(DateTime? date) =>
      date?.toIso8601String();

  /// Convenience getters
  bool get isCompleted => status == VoiceSessionStatus.completed;
  bool get hasTranscription => transcription != null;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get hasAudio => audioUrl != null;

  /// Calculate session duration
  Duration? get sessionDuration {
    if (startedAt != null && endedAt != null) {
      return endedAt!.difference(startedAt!);
    }
    return null;
  }
}

/// Status of a voice session
enum VoiceSessionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('recording')
  recording,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// Transcription data from voice processing
@JsonSerializable()
class TranscriptionData extends Equatable {
  /// Raw transcribed text
  final String text;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Language detected or specified
  final String language;

  /// Individual word segments with timing
  final List<WordSegment> segments;

  /// Processing metadata
  final TranscriptionMetadata metadata;

  const TranscriptionData({
    required this.text,
    required this.confidence,
    required this.language,
    this.segments = const [],
    required this.metadata,
  });

  /// Creates a TranscriptionData instance from JSON
  factory TranscriptionData.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionDataFromJson(json);

  /// Converts TranscriptionData instance to JSON
  Map<String, dynamic> toJson() => _$TranscriptionDataToJson(this);

  /// Creates a copy of TranscriptionData with modified fields
  TranscriptionData copyWith({
    String? text,
    double? confidence,
    String? language,
    List<WordSegment>? segments,
    TranscriptionMetadata? metadata,
  }) {
    return TranscriptionData(
      text: text ?? this.text,
      confidence: confidence ?? this.confidence,
      language: language ?? this.language,
      segments: segments ?? this.segments,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [text, confidence, language, segments, metadata];

  /// Get text within specific time range
  String getTextInRange(Duration start, Duration end) {
    final relevantSegments = segments.where((segment) {
      return segment.startTime >= start && segment.endTime <= end;
    });
    return relevantSegments.map((s) => s.word).join(' ');
  }
}

/// Individual word segment with timing information
@JsonSerializable()
class WordSegment extends Equatable {
  /// The word text
  final String word;

  /// Start time in milliseconds
  final Duration startTime;

  /// End time in milliseconds
  final Duration endTime;

  /// Confidence for this word (0.0 to 1.0)
  final double confidence;

  const WordSegment({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.confidence,
  });

  /// Creates a WordSegment instance from JSON
  factory WordSegment.fromJson(Map<String, dynamic> json) =>
      _$WordSegmentFromJson(json);

  /// Converts WordSegment instance to JSON
  Map<String, dynamic> toJson() => _$WordSegmentToJson(this);

  @override
  List<Object?> get props => [word, startTime, endTime, confidence];
}

/// Metadata for transcription processing
@JsonSerializable()
class TranscriptionMetadata extends Equatable {
  /// Service used for transcription
  final String provider;

  /// Model or engine version
  final String model;

  /// Processing time in milliseconds
  final int processingTimeMs;

  /// Additional processing parameters
  final Map<String, dynamic> parameters;

  const TranscriptionMetadata({
    required this.provider,
    required this.model,
    required this.processingTimeMs,
    this.parameters = const {},
  });

  /// Creates a TranscriptionMetadata instance from JSON
  factory TranscriptionMetadata.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionMetadataFromJson(json);

  /// Converts TranscriptionMetadata instance to JSON
  Map<String, dynamic> toJson() => _$TranscriptionMetadataToJson(this);

  @override
  List<Object?> get props => [provider, model, processingTimeMs, parameters];
}

/// AI-generated suggestion based on transcription
@JsonSerializable()
class AISuggestion extends Equatable {
  /// Unique identifier for the suggestion
  final String id;

  /// Type of suggestion
  final SuggestionType type;

  /// Human-readable title
  final String title;

  /// Detailed content of the suggestion
  final String content;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Action that can be taken on this suggestion
  final SuggestedAction? action;

  /// Metadata about the suggestion generation
  final Map<String, dynamic> metadata;

  /// Priority level
  final SuggestionPriority priority;

  const AISuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.confidence,
    this.action,
    this.metadata = const {},
    this.priority = SuggestionPriority.medium,
  });

  /// Creates an AISuggestion instance from JSON
  factory AISuggestion.fromJson(Map<String, dynamic> json) =>
      _$AISuggestionFromJson(json);

  /// Converts AISuggestion instance to JSON
  Map<String, dynamic> toJson() => _$AISuggestionToJson(this);

  /// Creates a copy of AISuggestion with modified fields
  AISuggestion copyWith({
    String? id,
    SuggestionType? type,
    String? title,
    String? content,
    double? confidence,
    SuggestedAction? action,
    Map<String, dynamic>? metadata,
    SuggestionPriority? priority,
  }) {
    return AISuggestion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      confidence: confidence ?? this.confidence,
      action: action ?? this.action,
      metadata: metadata ?? this.metadata,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        content,
        confidence,
        action,
        metadata,
        priority,
      ];
}

/// Types of AI suggestions
enum SuggestionType {
  @JsonValue('note_creation')
  noteCreation,
  @JsonValue('task_extraction')
  taskExtraction,
  @JsonValue('reminder_setting')
  reminderSetting,
  @JsonValue('family_sharing')
  familySharing,
  @JsonValue('content_improvement')
  contentImprovement,
  @JsonValue('follow_up_action')
  followUpAction,
}

/// Priority levels for suggestions
enum SuggestionPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Suggested action that can be taken
@JsonSerializable()
class SuggestedAction extends Equatable {
  /// Type of action
  final ActionType type;

  /// Human-readable label for the action
  final String label;

  /// Parameters for executing the action
  final Map<String, dynamic> parameters;

  /// Icon or emoji for the action
  final String? icon;

  const SuggestedAction({
    required this.type,
    required this.label,
    this.parameters = const {},
    this.icon,
  });

  /// Creates a SuggestedAction instance from JSON
  factory SuggestedAction.fromJson(Map<String, dynamic> json) =>
      _$SuggestedActionFromJson(json);

  /// Converts SuggestedAction instance to JSON
  Map<String, dynamic> toJson() => _$SuggestedActionToJson(this);

  @override
  List<Object?> get props => [type, label, parameters, icon];
}

/// Types of actions that can be suggested
enum ActionType {
  @JsonValue('create_note')
  createNote,
  @JsonValue('create_task')
  createTask,
  @JsonValue('set_reminder')
  setReminder,
  @JsonValue('share_with_family')
  shareWithFamily,
  @JsonValue('schedule_event')
  scheduleEvent,
  @JsonValue('send_message')
  sendMessage,
}

/// Session metadata and configuration
@JsonSerializable()
class SessionMetadata extends Equatable {
  /// Device information where session was recorded
  final DeviceInfo device;

  /// Audio quality settings
  final AudioQuality quality;

  /// Processing preferences
  final ProcessingPreferences processing;

  /// Privacy and security settings
  final PrivacySettings privacy;

  const SessionMetadata({
    required this.device,
    required this.quality,
    required this.processing,
    required this.privacy,
  });

  /// Creates a SessionMetadata instance from JSON
  factory SessionMetadata.fromJson(Map<String, dynamic> json) =>
      _$SessionMetadataFromJson(json);

  /// Converts SessionMetadata instance to JSON
  Map<String, dynamic> toJson() => _$SessionMetadataToJson(this);

  @override
  List<Object?> get props => [device, quality, processing, privacy];
}

/// Device information for voice session
@JsonSerializable()
class DeviceInfo extends Equatable {
  /// Device type (mobile, tablet, etc.)
  final String type;

  /// Operating system
  final String os;

  /// OS version
  final String osVersion;

  /// App version
  final String appVersion;

  const DeviceInfo({
    required this.type,
    required this.os,
    required this.osVersion,
    required this.appVersion,
  });

  /// Creates a DeviceInfo instance from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  /// Converts DeviceInfo instance to JSON
  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  List<Object?> get props => [type, os, osVersion, appVersion];
}

/// Audio quality settings
@JsonSerializable()
class AudioQuality extends Equatable {
  /// Sample rate in Hz
  final int sampleRate;

  /// Bit depth
  final int bitDepth;

  /// Audio format (e.g., 'wav', 'mp3', 'aac')
  final String format;

  /// Compression quality (0.0 to 1.0)
  final double compressionQuality;

  const AudioQuality({
    required this.sampleRate,
    required this.bitDepth,
    required this.format,
    required this.compressionQuality,
  });

  /// Creates an AudioQuality instance from JSON
  factory AudioQuality.fromJson(Map<String, dynamic> json) =>
      _$AudioQualityFromJson(json);

  /// Converts AudioQuality instance to JSON
  Map<String, dynamic> toJson() => _$AudioQualityToJson(this);

  @override
  List<Object?> get props => [sampleRate, bitDepth, format, compressionQuality];
}

/// Processing preferences for voice session
@JsonSerializable()
class ProcessingPreferences extends Equatable {
  /// Whether to enable AI suggestions
  final bool enableAISuggestions;

  /// Whether to store audio file
  final bool storeAudio;

  /// Whether to enable real-time transcription
  final bool realTimeTranscription;

  /// Language for transcription
  final String language;

  /// Custom processing parameters
  final Map<String, dynamic> customParameters;

  const ProcessingPreferences({
    this.enableAISuggestions = true,
    this.storeAudio = false,
    this.realTimeTranscription = true,
    this.language = 'en-US',
    this.customParameters = const {},
  });

  /// Creates a ProcessingPreferences instance from JSON
  factory ProcessingPreferences.fromJson(Map<String, dynamic> json) =>
      _$ProcessingPreferencesFromJson(json);

  /// Converts ProcessingPreferences instance to JSON
  Map<String, dynamic> toJson() => _$ProcessingPreferencesToJson(this);

  @override
  List<Object?> get props => [
        enableAISuggestions,
        storeAudio,
        realTimeTranscription,
        language,
        customParameters,
      ];
}

/// Privacy settings for voice session
@JsonSerializable()
class PrivacySettings extends Equatable {
  /// Whether to encrypt audio data
  final bool encryptAudio;

  /// Whether to delete audio after processing
  final bool deleteAudioAfterProcessing;

  /// Whether to allow data sharing for improvement
  final bool allowDataSharing;

  /// Data retention period in days
  final int retentionPeriodDays;

  const PrivacySettings({
    this.encryptAudio = true,
    this.deleteAudioAfterProcessing = false,
    this.allowDataSharing = false,
    this.retentionPeriodDays = 30,
  });

  /// Creates a PrivacySettings instance from JSON
  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  /// Converts PrivacySettings instance to JSON
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  @override
  List<Object?> get props => [
        encryptAudio,
        deleteAudioAfterProcessing,
        allowDataSharing,
        retentionPeriodDays,
      ];
}