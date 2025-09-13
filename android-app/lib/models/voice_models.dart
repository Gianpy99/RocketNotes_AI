// ==========================================
// lib/models/voice_models.dart
// ==========================================

// T030: Voice Commands Integration Models
// - Voice command types and data structures
// - Voice recognition results and feedback
// - Text-to-speech configuration models
// - Integration with note and family services

/// Voice command types supported by the system
enum VoiceCommandType {
  createNote,
  editNote,
  deleteNote,
  searchNotes,
  shareNote,
  createFamily,
  inviteFamily,
  navigate,
  backup,
  help,
  unknown,
}

/// Voice command data structure
class VoiceCommand {
  final VoiceCommandType type;
  final String originalText;
  final Map<String, String> parameters;
  final double confidence;
  final DateTime timestamp;

  VoiceCommand({
    required this.type,
    required this.originalText,
    required this.parameters,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      type: VoiceCommandType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => VoiceCommandType.unknown,
      ),
      originalText: json['originalText'] as String,
      parameters: Map<String, String>.from(json['parameters'] ?? {}),
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'originalText': originalText,
      'parameters': parameters,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'VoiceCommand(type: $type, text: "$originalText", confidence: $confidence)';
  }
}

/// Result of voice command execution
class VoiceCommandResult {
  final bool success;
  final VoiceCommandType commandType;
  final String message;
  final Map<String, dynamic>? data;
  final bool spoken;
  final DateTime timestamp;

  VoiceCommandResult({
    required this.success,
    required this.commandType,
    required this.message,
    this.data,
    this.spoken = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResult(
      success: json['success'] as bool,
      commandType: VoiceCommandType.values.firstWhere(
        (e) => e.toString() == json['commandType'],
        orElse: () => VoiceCommandType.unknown,
      ),
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      spoken: json['spoken'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'commandType': commandType.toString(),
      'message': message,
      'data': data,
      'spoken': spoken,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'VoiceCommandResult(success: $success, type: $commandType, message: "$message")';
  }
}

/// Voice recognition session
class VoiceSession {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  final List<VoiceCommand> commands;
  final List<VoiceCommandResult> results;
  final String language;
  bool isActive;

  VoiceSession({
    required this.sessionId,
    DateTime? startTime,
    this.endTime,
    List<VoiceCommand>? commands,
    List<VoiceCommandResult>? results,
    this.language = 'en-US',
    this.isActive = true,
  }) : startTime = startTime ?? DateTime.now(),
       commands = commands ?? [],
       results = results ?? [];

  /// Add command to session
  void addCommand(VoiceCommand command) {
    commands.add(command);
  }

  /// Add result to session
  void addResult(VoiceCommandResult result) {
    results.add(result);
  }

  /// End session
  void endSession() {
    isActive = false;
    endTime = DateTime.now();
  }

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Get success rate
  double get successRate {
    if (results.isEmpty) return 0.0;
    final successful = results.where((r) => r.success).length;
    return successful / results.length;
  }

  factory VoiceSession.fromJson(Map<String, dynamic> json) {
    return VoiceSession(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      commands: (json['commands'] as List<dynamic>?)
          ?.map((e) => VoiceCommand.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => VoiceCommandResult.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      language: json['language'] as String? ?? 'en-US',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'commands': commands.map((c) => c.toJson()).toList(),
      'results': results.map((r) => r.toJson()).toList(),
      'language': language,
      'isActive': isActive,
    };
  }
}

/// Voice settings configuration
class VoiceSettings {
  final bool enabled;
  final String language;
  final double speechRate;
  final double pitch;
  final double volume;
  final bool autoListen;
  final bool confirmActions;
  final Duration listeningTimeout;
  final bool continuousListening;

  const VoiceSettings({
    this.enabled = true,
    this.language = 'en-US',
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.autoListen = false,
    this.confirmActions = true,
    this.listeningTimeout = const Duration(seconds: 30),
    this.continuousListening = false,
  });

  VoiceSettings copyWith({
    bool? enabled,
    String? language,
    double? speechRate,
    double? pitch,
    double? volume,
    bool? autoListen,
    bool? confirmActions,
    Duration? listeningTimeout,
    bool? continuousListening,
  }) {
    return VoiceSettings(
      enabled: enabled ?? this.enabled,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      autoListen: autoListen ?? this.autoListen,
      confirmActions: confirmActions ?? this.confirmActions,
      listeningTimeout: listeningTimeout ?? this.listeningTimeout,
      continuousListening: continuousListening ?? this.continuousListening,
    );
  }

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      enabled: json['enabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'en-US',
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      autoListen: json['autoListen'] as bool? ?? false,
      confirmActions: json['confirmActions'] as bool? ?? true,
      listeningTimeout: Duration(
        seconds: json['listeningTimeoutSeconds'] as int? ?? 30,
      ),
      continuousListening: json['continuousListening'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'language': language,
      'speechRate': speechRate,
      'pitch': pitch,
      'volume': volume,
      'autoListen': autoListen,
      'confirmActions': confirmActions,
      'listeningTimeoutSeconds': listeningTimeout.inSeconds,
      'continuousListening': continuousListening,
    };
  }
}

/// Voice recognition status
enum VoiceRecognitionStatus {
  idle,
  listening,
  processing,
  speaking,
  error,
}

/// Voice recognition state
class VoiceRecognitionState {
  final VoiceRecognitionStatus status;
  final String? currentText;
  final double? confidence;
  final String? error;
  final bool isAvailable;
  final List<String> availableLanguages;

  const VoiceRecognitionState({
    this.status = VoiceRecognitionStatus.idle,
    this.currentText,
    this.confidence,
    this.error,
    this.isAvailable = false,
    this.availableLanguages = const [],
  });

  VoiceRecognitionState copyWith({
    VoiceRecognitionStatus? status,
    String? currentText,
    double? confidence,
    String? error,
    bool? isAvailable,
    List<String>? availableLanguages,
  }) {
    return VoiceRecognitionState(
      status: status ?? this.status,
      currentText: currentText ?? this.currentText,
      confidence: confidence ?? this.confidence,
      error: error ?? this.error,
      isAvailable: isAvailable ?? this.isAvailable,
      availableLanguages: availableLanguages ?? this.availableLanguages,
    );
  }

  bool get isListening => status == VoiceRecognitionStatus.listening;
  bool get isProcessing => status == VoiceRecognitionStatus.processing;
  bool get isSpeaking => status == VoiceRecognitionStatus.speaking;
  bool get hasError => status == VoiceRecognitionStatus.error;
  bool get isIdle => status == VoiceRecognitionStatus.idle;
}

/// Speech synthesis settings
class SpeechSynthesisSettings {
  final bool enabled;
  final String voice;
  final double rate;
  final double pitch;
  final double volume;
  final String language;

  const SpeechSynthesisSettings({
    this.enabled = true,
    this.voice = 'default',
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.language = 'en-US',
  });

  SpeechSynthesisSettings copyWith({
    bool? enabled,
    String? voice,
    double? rate,
    double? pitch,
    double? volume,
    String? language,
  }) {
    return SpeechSynthesisSettings(
      enabled: enabled ?? this.enabled,
      voice: voice ?? this.voice,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      language: language ?? this.language,
    );
  }

  factory SpeechSynthesisSettings.fromJson(Map<String, dynamic> json) {
    return SpeechSynthesisSettings(
      enabled: json['enabled'] as bool? ?? true,
      voice: json['voice'] as String? ?? 'default',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      language: json['language'] as String? ?? 'en-US',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'voice': voice,
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
      'language': language,
    };
  }
}

/// Voice command history entry
class VoiceCommandHistoryEntry {
  final String id;
  final VoiceCommand command;
  final VoiceCommandResult result;
  final DateTime timestamp;

  VoiceCommandHistoryEntry({
    required this.id,
    required this.command,
    required this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory VoiceCommandHistoryEntry.fromJson(Map<String, dynamic> json) {
    return VoiceCommandHistoryEntry(
      id: json['id'] as String,
      command: VoiceCommand.fromJson(json['command'] as Map<String, dynamic>),
      result: VoiceCommandResult.fromJson(json['result'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'command': command.toJson(),
      'result': result.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Voice accessibility settings
class VoiceAccessibilitySettings {
  final bool speakScreenReaderMode;
  final bool speakButtonLabels;
  final bool speakErrors;
  final bool speakConfirmations;
  final bool slowSpeechMode;
  final bool highContrastAudio;

  const VoiceAccessibilitySettings({
    this.speakScreenReaderMode = false,
    this.speakButtonLabels = false,
    this.speakErrors = true,
    this.speakConfirmations = true,
    this.slowSpeechMode = false,
    this.highContrastAudio = false,
  });

  VoiceAccessibilitySettings copyWith({
    bool? speakScreenReaderMode,
    bool? speakButtonLabels,
    bool? speakErrors,
    bool? speakConfirmations,
    bool? slowSpeechMode,
    bool? highContrastAudio,
  }) {
    return VoiceAccessibilitySettings(
      speakScreenReaderMode: speakScreenReaderMode ?? this.speakScreenReaderMode,
      speakButtonLabels: speakButtonLabels ?? this.speakButtonLabels,
      speakErrors: speakErrors ?? this.speakErrors,
      speakConfirmations: speakConfirmations ?? this.speakConfirmations,
      slowSpeechMode: slowSpeechMode ?? this.slowSpeechMode,
      highContrastAudio: highContrastAudio ?? this.highContrastAudio,
    );
  }

  factory VoiceAccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return VoiceAccessibilitySettings(
      speakScreenReaderMode: json['speakScreenReaderMode'] as bool? ?? false,
      speakButtonLabels: json['speakButtonLabels'] as bool? ?? false,
      speakErrors: json['speakErrors'] as bool? ?? true,
      speakConfirmations: json['speakConfirmations'] as bool? ?? true,
      slowSpeechMode: json['slowSpeechMode'] as bool? ?? false,
      highContrastAudio: json['highContrastAudio'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speakScreenReaderMode': speakScreenReaderMode,
      'speakButtonLabels': speakButtonLabels,
      'speakErrors': speakErrors,
      'speakConfirmations': speakConfirmations,
      'slowSpeechMode': slowSpeechMode,
      'highContrastAudio': highContrastAudio,
    };
  }
}