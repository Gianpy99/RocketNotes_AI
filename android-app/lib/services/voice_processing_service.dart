import 'dart:developer' as developer;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Voice session types
enum VoiceSessionType {
  speechToText,
  voiceCommand,
  voiceNote,
  aiAssistant,
}

/// Voice session status
enum VoiceSessionStatus {
  pending,
  active,
  processing,
  completed,
  failed,
  expired,
}

/// Command types that can be detected from voice input
enum VoiceCommandType {
  createNote,
  editNote,
  deleteNote,
  shareNote,
  addToList,
  setReminder,
  searchNotes,
  organizeNotes,
  unknown,
}

/// Advanced voice processing service with AI integration
class VoiceProcessingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SpeechToText _speechToText;
  final AudioRecorder _recorder;

  VoiceProcessingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SpeechToText? speechToText,
    AudioRecorder? recorder,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _speechToText = speechToText ?? SpeechToText(),
        _recorder = recorder ?? AudioRecorder();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _voiceSessionsCollection =>
      _firestore.collection('voice_sessions');

  CollectionReference<Map<String, dynamic>> get _transcriptionsCollection =>
      _firestore.collection('transcriptions');

  CollectionReference<Map<String, dynamic>> get _voiceCommandsCollection =>
      _firestore.collection('voice_commands');

  CollectionReference<Map<String, dynamic>> get _aiSuggestionsCollection =>
      _firestore.collection('ai_suggestions');

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Initialize the voice processing service
  Future<ServiceResult<bool>> initialize() async {
    try {
      // Check and request microphone permissions
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        return ServiceResult.failure(
          error: 'Microphone permission required',
          code: 'PERMISSION_DENIED',
        );
      }

      // Initialize speech-to-text
      final isAvailable = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );

      if (!isAvailable) {
        return ServiceResult.failure(
          error: 'Speech recognition not available',
          code: 'STT_UNAVAILABLE',
        );
      }

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to initialize voice service: ${e.toString()}',
        code: 'INITIALIZATION_FAILED',
      );
    }
  }

  /// Requests microphone permission
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Creates a new voice session
  Future<ServiceResult<VoiceSession>> createVoiceSession({
    required VoiceSessionType sessionType,
    String? contextId,
    String language = 'en-US',
    Duration? expirationDuration,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final now = DateTime.now();
      final sessionId = _voiceSessionsCollection.doc().id;

      final session = VoiceSession(
        sessionId: sessionId,
        userId: user.uid,
        sessionType: sessionType,
        language: language,
        status: VoiceSessionStatus.pending,
        contextId: contextId,
        createdAt: now,
        expiresAt: expirationDuration != null 
            ? now.add(expirationDuration) 
            : now.add(const Duration(minutes: 5)),
      );

      await _voiceSessionsCollection.doc(sessionId).set(session.toJson());

      return ServiceResult.success(data: session);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to create voice session: ${e.toString()}',
        code: 'SESSION_CREATION_FAILED',
      );
    }
  }

  /// Starts speech-to-text transcription
  Future<ServiceResult<String>> startSpeechToText({
    required String sessionId,
    String language = 'en-US',
    bool partialResults = true,
    Duration? timeout,
  }) async {
    try {
      // Update session status
      await _updateSessionStatus(sessionId, VoiceSessionStatus.active);

      final completer = Completer<String>();
      String finalTranscription = '';
      bool isCompleted = false;

      // Start listening
      await _speechToText.listen(
        onResult: (result) {
          if (!isCompleted) {
            if (result.finalResult) {
              finalTranscription = result.recognizedWords;
              isCompleted = true;
              completer.complete(finalTranscription);
            } else if (partialResults) {
              // Handle partial results for real-time feedback
              _handlePartialTranscription(sessionId, result.recognizedWords);
            }
          }
        },
        listenFor: timeout ?? const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: partialResults,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
        localeId: language,
        onSoundLevelChange: (level) {
          // Handle sound level changes for UI feedback
          _handleSoundLevelChange(sessionId, level);
        },
      );

      // Wait for completion or timeout
      final transcription = await completer.future;

      // Process the transcription
      await _processTranscription(sessionId, transcription, language);

      // Update session status
      await _updateSessionStatus(sessionId, VoiceSessionStatus.completed);

      return ServiceResult.success(data: transcription);
    } catch (e) {
      await _updateSessionStatus(sessionId, VoiceSessionStatus.failed);
      return ServiceResult.failure(
        error: 'Speech-to-text failed: ${e.toString()}',
        code: 'STT_FAILED',
      );
    }
  }

  /// Processes transcription and detects commands
  Future<void> _processTranscription(
    String sessionId,
    String transcription,
    String language,
  ) async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Detect voice commands
      final detectedCommands = await _detectVoiceCommands(transcription);

      // Calculate confidence score (simplified)
      final confidence = _calculateConfidence(transcription);

      // Save transcription
      final transcriptionRecord = VoiceTranscription(
        sessionId: sessionId,
        transcription: transcription,
        confidence: confidence,
        processedAt: DateTime.now(),
        detectedCommands: detectedCommands,
        language: language,
      );

      await _transcriptionsCollection.doc().set(transcriptionRecord.toJson());

      // Execute detected commands
      for (final command in detectedCommands) {
        await _executeVoiceCommand(sessionId, command);
      }

      // Generate AI suggestions if applicable
      await _generateAISuggestions(sessionId, transcription);
    } catch (e) {
      developer.log('Failed to process transcription: $e', name: 'VoiceProcessingService');
    }
  }

  /// Detects voice commands from transcription
  Future<List<VoiceCommand>> _detectVoiceCommands(String transcription) async {
    final commands = <VoiceCommand>[];
    final lowerText = transcription.toLowerCase();

    // Note creation commands
    if (lowerText.contains('create note') || 
        lowerText.contains('new note') ||
        lowerText.contains('add note')) {
      commands.add(VoiceCommand(
        command: 'create_note',
        type: VoiceCommandType.createNote,
        confidence: 0.9,
        parameters: _extractNoteContent(transcription),
      ));
    }

    // List management commands
    if (lowerText.contains('add to') && 
        (lowerText.contains('list') || lowerText.contains('shopping'))) {
      commands.add(VoiceCommand(
        command: 'add_to_list',
        type: VoiceCommandType.addToList,
        confidence: 0.85,
        parameters: _extractListCommand(transcription),
      ));
    }

    // Reminder commands
    if (lowerText.contains('remind me') || 
        lowerText.contains('set reminder')) {
      commands.add(VoiceCommand(
        command: 'set_reminder',
        type: VoiceCommandType.setReminder,
        confidence: 0.88,
        parameters: _extractReminderCommand(transcription),
      ));
    }

    // Search commands
    if (lowerText.contains('find') || 
        lowerText.contains('search') ||
        lowerText.contains('look for')) {
      commands.add(VoiceCommand(
        command: 'search_notes',
        type: VoiceCommandType.searchNotes,
        confidence: 0.82,
        parameters: _extractSearchCommand(transcription),
      ));
    }

    return commands;
  }

  /// Executes a detected voice command
  Future<void> _executeVoiceCommand(String sessionId, VoiceCommand command) async {
    try {
      await _voiceCommandsCollection.doc().set({
        'sessionId': sessionId,
        'command': command.toJson(),
        'executedAt': FieldValue.serverTimestamp(),
        'status': 'executed',
      });

      // In a real implementation, this would trigger the actual command execution
      // through the appropriate services (e.g., notes service, reminders service)
  developer.log('Executing command: ${command.command}', name: 'VoiceProcessingService');
    } catch (e) {
      developer.log('Failed to execute voice command: $e', name: 'VoiceProcessingService');
    }
  }

  /// Generates AI suggestions based on transcription
  Future<void> _generateAISuggestions(String sessionId, String transcription) async {
    try {
      // This would integrate with an AI service (OpenAI, Gemini, etc.)
      final suggestions = await _getAISuggestions(transcription);

      final aiSuggestion = AISuggestion(
        requestId: _aiSuggestionsCollection.doc().id,
        sessionId: sessionId,
        suggestions: suggestions,
        processedAt: DateTime.now(),
      );

      await _aiSuggestionsCollection.doc(aiSuggestion.requestId).set(aiSuggestion.toJson());
    } catch (e) {
      developer.log('Failed to generate AI suggestions: $e', name: 'VoiceProcessingService');
    }
  }

  /// Gets AI suggestions for the given text
  Future<List<SuggestionItem>> _getAISuggestions(String text) async {
    // Mock AI suggestions - in real implementation this would call an AI API
    final suggestions = <SuggestionItem>[];

    // Content completion suggestions
    if (text.length < 50) {
      suggestions.add(SuggestionItem(
        id: 'completion_1',
        text: '$text and organize it for tomorrow.',
        type: 'completion',
        confidence: 0.85,
        rationale: 'Suggested completion based on context',
      ));
    }

    // Organization suggestions
    if (text.contains('grocery') || text.contains('shopping')) {
      suggestions.add(SuggestionItem(
        id: 'organize_1',
        text: 'Create a shopping list category',
        type: 'organization',
        confidence: 0.9,
        rationale: 'Content suggests shopping list organization',
      ));
    }

    // Reminder suggestions
    if (text.contains('tomorrow') || text.contains('later') || text.contains('next week')) {
      suggestions.add(SuggestionItem(
        id: 'reminder_1',
        text: 'Set a reminder for this task',
        type: 'reminder',
        confidence: 0.88,
        rationale: 'Time reference detected',
      ));
    }

    return suggestions;
  }

  /// Records voice note
  Future<ServiceResult<String>> recordVoiceNote({
    required String sessionId,
    Duration? maxDuration,
  }) async {
    try {
      // Check permissions
      final hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) {
        return ServiceResult.failure(
          error: 'Microphone permission required',
          code: 'PERMISSION_DENIED',
        );
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/voice_note_$sessionId.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      // Update session status
      await _updateSessionStatus(sessionId, VoiceSessionStatus.active);

      // Wait for recording to complete (manual stop or max duration)
      if (maxDuration != null) {
        await Future.delayed(maxDuration);
        await _recorder.stop();
      }

      return ServiceResult.success(data: filePath);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Voice recording failed: ${e.toString()}',
        code: 'RECORDING_FAILED',
      );
    }
  }

  /// Stops current voice recording
  Future<ServiceResult<String?>> stopRecording(String sessionId) async {
    try {
      final path = await _recorder.stop();
      await _updateSessionStatus(sessionId, VoiceSessionStatus.completed);
      return ServiceResult.success(data: path);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to stop recording: ${e.toString()}',
        code: 'STOP_RECORDING_FAILED',
      );
    }
  }

  /// Stops speech-to-text listening
  Future<ServiceResult<bool>> stopListening() async {
    try {
      await _speechToText.stop();
      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to stop listening: ${e.toString()}',
        code: 'STOP_LISTENING_FAILED',
      );
    }
  }

  /// Gets available languages for speech recognition
  Future<ServiceResult<List<LocaleName>>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return ServiceResult.success(data: locales);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get languages: ${e.toString()}',
        code: 'GET_LANGUAGES_FAILED',
      );
    }
  }

  /// Gets voice session by ID
  Future<ServiceResult<VoiceSession>> getVoiceSession(String sessionId) async {
    try {
      final doc = await _voiceSessionsCollection.doc(sessionId).get();
      if (!doc.exists) {
        return ServiceResult.failure(
          error: 'Voice session not found',
          code: 'SESSION_NOT_FOUND',
        );
      }

      final data = doc.data()!;
      data['sessionId'] = doc.id;
      final session = VoiceSession.fromJson(data);

      return ServiceResult.success(data: session);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get voice session: ${e.toString()}',
        code: 'GET_SESSION_FAILED',
      );
    }
  }

  /// Gets transcriptions for a session
  Future<ServiceResult<List<VoiceTranscription>>> getTranscriptions(String sessionId) async {
    try {
      final snapshot = await _transcriptionsCollection
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('processedAt', descending: true)
          .get();

      final transcriptions = snapshot.docs.map((doc) {
        final data = doc.data();
        return VoiceTranscription.fromJson(data);
      }).toList();

      return ServiceResult.success(data: transcriptions);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get transcriptions: ${e.toString()}',
        code: 'GET_TRANSCRIPTIONS_FAILED',
      );
    }
  }

  /// Gets AI suggestions for a session
  Future<ServiceResult<AISuggestion?>> getAISuggestions(String sessionId) async {
    try {
      final snapshot = await _aiSuggestionsCollection
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('processedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return ServiceResult.success(data: null);
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final suggestion = AISuggestion.fromJson(data);

      return ServiceResult.success(data: suggestion);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get AI suggestions: ${e.toString()}',
        code: 'GET_AI_SUGGESTIONS_FAILED',
      );
    }
  }

  // Helper methods

  /// Updates session status
  Future<void> _updateSessionStatus(String sessionId, VoiceSessionStatus status) async {
    try {
      await _voiceSessionsCollection.doc(sessionId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Failed to update session status: $e', name: 'VoiceProcessingService');
    }
  }

  /// Handles partial transcription results
  void _handlePartialTranscription(String sessionId, String partialText) {
    // This would typically update UI with real-time transcription
  developer.log('Partial transcription for $sessionId: $partialText', name: 'VoiceProcessingService');
  }

  /// Handles sound level changes
  void _handleSoundLevelChange(String sessionId, double level) {
    // This would update UI with audio level indicators
  developer.log('Sound level for $sessionId: $level', name: 'VoiceProcessingService');
  }

  /// Speech recognition error handler
  void _onSpeechError(dynamic error) {
  developer.log('Speech recognition error: $error', name: 'VoiceProcessingService');
  }

  /// Speech recognition status handler
  void _onSpeechStatus(String status) {
  developer.log('Speech recognition status: $status', name: 'VoiceProcessingService');
  }

  /// Calculates confidence score for transcription
  double _calculateConfidence(String transcription) {
    // Simplified confidence calculation
    // In real implementation, this would use ML models
    if (transcription.isEmpty) return 0.0;
    if (transcription.length < 10) return 0.6;
    if (transcription.split(' ').length < 3) return 0.7;
    return 0.85;
  }

  /// Extracts note content from voice command
  Map<String, dynamic> _extractNoteContent(String transcription) {
    final content = transcription
        .replaceAll(RegExp(r'create note|new note|add note', caseSensitive: false), '')
        .trim();
    
    return {
      'content': content,
      'title': content.length > 50 ? content.substring(0, 50) : content,
    };
  }

  /// Extracts list command parameters
  Map<String, dynamic> _extractListCommand(String transcription) {
    // Simple extraction - would be more sophisticated in real implementation
    final match = RegExp(r'add (.+) to (.+)', caseSensitive: false).firstMatch(transcription);
    
    return {
      'item': match?.group(1)?.trim() ?? '',
      'list': match?.group(2)?.trim() ?? 'default list',
    };
  }

  /// Extracts reminder command parameters
  Map<String, dynamic> _extractReminderCommand(String transcription) {
    return {
      'content': transcription,
      'when': _extractTimeFromText(transcription),
    };
  }

  /// Extracts search command parameters
  Map<String, dynamic> _extractSearchCommand(String transcription) {
    final query = transcription
        .replaceAll(RegExp(r'find|search|look for', caseSensitive: false), '')
        .trim();
    
    return {
      'query': query,
      'type': 'content_search',
    };
  }

  /// Extracts time information from text
  String? _extractTimeFromText(String text) {
    // Simplified time extraction
    if (text.contains('tomorrow')) return 'tomorrow';
    if (text.contains('next week')) return 'next_week';
    if (text.contains('later')) return 'later_today';
    return null;
  }
}

/// Base service result class
class ServiceResult<T> {
  final T? data;
  final String? error;
  final String? code;
  final bool isSuccess;

  const ServiceResult._({
    this.data,
    this.error,
    this.code,
    required this.isSuccess,
  });

  factory ServiceResult.success({required T data}) {
    return ServiceResult._(data: data, isSuccess: true);
  }

  factory ServiceResult.failure({required String error, String? code}) {
    return ServiceResult._(error: error, code: code, isSuccess: false);
  }
}

/// Voice session model
class VoiceSession {
  final String sessionId;
  final String userId;
  final VoiceSessionType sessionType;
  final String language;
  final VoiceSessionStatus status;
  final String? contextId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? updatedAt;

  const VoiceSession({
    required this.sessionId,
    required this.userId,
    required this.sessionType,
    required this.language,
    required this.status,
    this.contextId,
    required this.createdAt,
    required this.expiresAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'sessionType': sessionType.toString(),
      'language': language,
      'status': status.toString(),
      'contextId': contextId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory VoiceSession.fromJson(Map<String, dynamic> json) {
    return VoiceSession(
      sessionId: json['sessionId'],
      userId: json['userId'],
      sessionType: VoiceSessionType.values.firstWhere(
        (e) => e.toString() == json['sessionType'],
      ),
      language: json['language'],
      status: VoiceSessionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      contextId: json['contextId'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
}

/// Voice transcription model
class VoiceTranscription {
  final String sessionId;
  final String transcription;
  final double confidence;
  final DateTime processedAt;
  final List<VoiceCommand> detectedCommands;
  final String language;

  const VoiceTranscription({
    required this.sessionId,
    required this.transcription,
    required this.confidence,
    required this.processedAt,
    required this.detectedCommands,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'transcription': transcription,
      'confidence': confidence,
      'processedAt': processedAt.toIso8601String(),
      'detectedCommands': detectedCommands.map((c) => c.toJson()).toList(),
      'language': language,
    };
  }

  factory VoiceTranscription.fromJson(Map<String, dynamic> json) {
    return VoiceTranscription(
      sessionId: json['sessionId'],
      transcription: json['transcription'],
      confidence: json['confidence'].toDouble(),
      processedAt: DateTime.parse(json['processedAt']),
      detectedCommands: (json['detectedCommands'] as List)
          .map((c) => VoiceCommand.fromJson(c))
          .toList(),
      language: json['language'],
    );
  }
}

/// Voice command model
class VoiceCommand {
  final String command;
  final VoiceCommandType type;
  final double confidence;
  final Map<String, dynamic> parameters;

  const VoiceCommand({
    required this.command,
    required this.type,
    required this.confidence,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      'type': type.toString(),
      'confidence': confidence,
      'parameters': parameters,
    };
  }

  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      command: json['command'],
      type: VoiceCommandType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      confidence: json['confidence'].toDouble(),
      parameters: Map<String, dynamic>.from(json['parameters']),
    );
  }
}

/// AI suggestion model
class AISuggestion {
  final String requestId;
  final String sessionId;
  final List<SuggestionItem> suggestions;
  final DateTime processedAt;

  const AISuggestion({
    required this.requestId,
    required this.sessionId,
    required this.suggestions,
    required this.processedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'sessionId': sessionId,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'processedAt': processedAt.toIso8601String(),
    };
  }

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      requestId: json['requestId'],
      sessionId: json['sessionId'],
      suggestions: (json['suggestions'] as List)
          .map((s) => SuggestionItem.fromJson(s))
          .toList(),
      processedAt: DateTime.parse(json['processedAt']),
    );
  }
}

/// Suggestion item model
class SuggestionItem {
  final String id;
  final String text;
  final String type;
  final double confidence;
  final String rationale;

  const SuggestionItem({
    required this.id,
    required this.text,
    required this.type,
    required this.confidence,
    required this.rationale,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'confidence': confidence,
      'rationale': rationale,
    };
  }

  factory SuggestionItem.fromJson(Map<String, dynamic> json) {
    return SuggestionItem(
      id: json['id'],
      text: json['text'],
      type: json['type'],
      confidence: json['confidence'].toDouble(),
      rationale: json['rationale'],
    );
  }
}