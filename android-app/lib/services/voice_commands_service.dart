// ==========================================
// lib/services/voice_commands_service.dart
// ==========================================
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/voice_models.dart';
import '../services/note_service.dart';
import '../services/family_service.dart';

// T030: Voice Commands Integration
// - Implement voice-to-text for note editing and family management
// - Voice commands for common actions (create note, search, navigate)
// - Text-to-speech for accessibility and feedback
// - Integration with existing services (notes, family, notifications)

class VoiceCommandsService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _textToSpeech = FlutterTts();
  
  final NoteService _noteService = NoteService();
  final FamilyService _familyService = FamilyService();

  static final VoiceCommandsService _instance = VoiceCommandsService._internal();
  factory VoiceCommandsService() => _instance;
  VoiceCommandsService._internal();

  bool _isListening = false;
  bool _isInitialized = false;
  bool _isTtsInitialized = false;
  String _currentLanguage = 'en-US';
  
  // Voice command patterns
  final Map<VoiceCommandType, List<String>> _commandPatterns = {
    VoiceCommandType.createNote: [
      'create note',
      'new note',
      'make note',
      'add note',
      'take note',
    ],
    VoiceCommandType.searchNotes: [
      'search for',
      'find note',
      'look for',
      'search notes',
      'find',
    ],
    VoiceCommandType.editNote: [
      'edit note',
      'modify note',
      'change note',
      'update note',
    ],
    VoiceCommandType.deleteNote: [
      'delete note',
      'remove note',
      'trash note',
    ],
    VoiceCommandType.shareNote: [
      'share note',
      'share with family',
      'send note',
    ],
    VoiceCommandType.createFamily: [
      'create family',
      'new family',
      'make family',
    ],
    VoiceCommandType.inviteFamily: [
      'invite to family',
      'add family member',
      'invite member',
    ],
    VoiceCommandType.navigate: [
      'go to',
      'open',
      'navigate to',
      'show',
    ],
    VoiceCommandType.backup: [
      'backup notes',
      'save backup',
      'create backup',
    ],
    VoiceCommandType.help: [
      'help',
      'what can you do',
      'voice commands',
      'how to use',
    ],
  };

  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;

  /// Initialize voice services
  Future<VoiceServiceResult<bool>> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        return VoiceServiceResult.failure(
          error: 'Microphone permission denied',
          code: 'PERMISSION_DENIED',
        );
      }

      // Initialize Speech-to-Text
      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!available) {
        return VoiceServiceResult.failure(
          error: 'Speech recognition not available',
          code: 'STT_UNAVAILABLE',
        );
      }

      // Initialize Text-to-Speech
      await _initializeTts();

      _isInitialized = true;
      return VoiceServiceResult.success(data: true);
    } catch (e) {
      return VoiceServiceResult.failure(
        error: 'Failed to initialize voice services: ${e.toString()}',
        code: 'INIT_FAILED',
      );
    }
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    try {
      await _textToSpeech.setLanguage(_currentLanguage);
      await _textToSpeech.setPitch(1.0);
      await _textToSpeech.setSpeechRate(0.5);
      await _textToSpeech.setVolume(1.0);
      
      _isTtsInitialized = true;
    } catch (e) {
      print('Failed to initialize TTS: $e');
    }
  }

  /// Start listening for voice commands
  Future<VoiceServiceResult<bool>> startListening({
    String? language,
    Duration? timeout,
  }) async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult.isSuccess) {
          return initResult;
        }
      }

      if (_isListening) {
        return VoiceServiceResult.failure(
          error: 'Already listening',
          code: 'ALREADY_LISTENING',
        );
      }

      final languageCode = language ?? _currentLanguage;
      
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: languageCode,
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      );

      _isListening = true;
      return VoiceServiceResult.success(data: true);
    } catch (e) {
      return VoiceServiceResult.failure(
        error: 'Failed to start listening: ${e.toString()}',
        code: 'LISTEN_FAILED',
      );
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }
    } catch (e) {
      print('Failed to stop listening: $e');
    }
  }

  /// Process voice command
  Future<VoiceCommandResult> processVoiceCommand(String command) async {
    try {
      final cleanCommand = command.toLowerCase().trim();
      
      // Parse command type and parameters
      final parsedCommand = _parseCommand(cleanCommand);
      
      if (parsedCommand == null) {
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.unknown,
          message: 'Command not recognized. Say "help" to see available commands.',
          spoken: true,
        );
      }

      // Execute command based on type
      return await _executeCommand(parsedCommand);
    } catch (e) {
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.unknown,
        message: 'Error processing command: ${e.toString()}',
        spoken: true,
      );
    }
  }

  /// Parse voice command
  VoiceCommand? _parseCommand(String input) {
    for (final entry in _commandPatterns.entries) {
      for (final pattern in entry.value) {
        if (input.contains(pattern)) {
          // Extract parameters based on command type
          final parameters = _extractParameters(input, pattern, entry.key);
          
          return VoiceCommand(
            type: entry.key,
            originalText: input,
            parameters: parameters,
            confidence: _calculateConfidence(input, pattern),
          );
        }
      }
    }
    return null;
  }

  /// Extract parameters from voice command
  Map<String, String> _extractParameters(String input, String pattern, VoiceCommandType type) {
    final parameters = <String, String>{};
    
    switch (type) {
      case VoiceCommandType.createNote:
        // Extract note title and content
        final afterPattern = input.substring(input.indexOf(pattern) + pattern.length).trim();
        if (afterPattern.isNotEmpty) {
          final parts = afterPattern.split(' about ');
          if (parts.length > 1) {
            parameters['title'] = parts[0];
            parameters['content'] = parts[1];
          } else {
            parameters['title'] = afterPattern;
          }
        }
        break;

      case VoiceCommandType.searchNotes:
        // Extract search query
        final afterPattern = input.substring(input.indexOf(pattern) + pattern.length).trim();
        if (afterPattern.isNotEmpty) {
          parameters['query'] = afterPattern;
        }
        break;

      case VoiceCommandType.shareNote:
        // Extract note identifier and recipient
        final afterPattern = input.substring(input.indexOf(pattern) + pattern.length).trim();
        if (afterPattern.contains(' with ')) {
          final parts = afterPattern.split(' with ');
          parameters['noteId'] = parts[0];
          parameters['recipient'] = parts[1];
        }
        break;

      case VoiceCommandType.navigate:
        // Extract destination
        final afterPattern = input.substring(input.indexOf(pattern) + pattern.length).trim();
        if (afterPattern.isNotEmpty) {
          parameters['destination'] = afterPattern;
        }
        break;

      case VoiceCommandType.createFamily:
        // Extract family name
        final afterPattern = input.substring(input.indexOf(pattern) + pattern.length).trim();
        if (afterPattern.contains(' called ') || afterPattern.contains(' named ')) {
          final separator = afterPattern.contains(' called ') ? ' called ' : ' named ';
          final parts = afterPattern.split(separator);
          if (parts.length > 1) {
            parameters['name'] = parts[1];
          }
        } else if (afterPattern.isNotEmpty) {
          parameters['name'] = afterPattern;
        }
        break;

      case VoiceCommandType.inviteFamily:
        // Extract email or name
        final afterPattern = input.substring(input.indexOf(pattern) + pattern.length).trim();
        if (afterPattern.isNotEmpty) {
          parameters['identifier'] = afterPattern;
        }
        break;

      default:
        break;
    }

    return parameters;
  }

  /// Calculate confidence score for command recognition
  double _calculateConfidence(String input, String pattern) {
    final inputWords = input.split(' ');
    final patternWords = pattern.split(' ');
    
    int matches = 0;
    for (final patternWord in patternWords) {
      if (inputWords.contains(patternWord)) {
        matches++;
      }
    }
    
    return matches / patternWords.length;
  }

  /// Execute voice command
  Future<VoiceCommandResult> _executeCommand(VoiceCommand command) async {
    try {
      switch (command.type) {
        case VoiceCommandType.createNote:
          return await _executeCreateNote(command);

        case VoiceCommandType.searchNotes:
          return await _executeSearchNotes(command);

        case VoiceCommandType.shareNote:
          return await _executeShareNote(command);

        case VoiceCommandType.createFamily:
          return await _executeCreateFamily(command);

        case VoiceCommandType.inviteFamily:
          return await _executeInviteFamily(command);

        case VoiceCommandType.navigate:
          return await _executeNavigate(command);

        case VoiceCommandType.backup:
          return await _executeBackup(command);

        case VoiceCommandType.help:
          return _executeHelp();

        default:
          return VoiceCommandResult(
            success: false,
            commandType: command.type,
            message: 'Command type not implemented yet',
            spoken: true,
          );
      }
    } catch (e) {
      return VoiceCommandResult(
        success: false,
        commandType: command.type,
        message: 'Error executing command: ${e.toString()}',
        spoken: true,
      );
    }
  }

  /// Execute create note command
  Future<VoiceCommandResult> _executeCreateNote(VoiceCommand command) async {
    try {
      final title = command.parameters['title'] ?? 'Voice Note';
      final content = command.parameters['content'] ?? '';
      
      // Create note using note service
      final noteResult = await _noteService.createNote(
        title: title,
        content: content,
        type: NoteType.text,
      );

      if (noteResult.isSuccess) {
        final message = 'Note "$title" created successfully';
        await _speak(message);
        
        return VoiceCommandResult(
          success: true,
          commandType: VoiceCommandType.createNote,
          message: message,
          data: {'noteId': noteResult.data!.id},
          spoken: true,
        );
      } else {
        final message = 'Failed to create note: ${noteResult.error}';
        await _speak(message);
        
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.createNote,
          message: message,
          spoken: true,
        );
      }
    } catch (e) {
      final message = 'Error creating note: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.createNote,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute search notes command
  Future<VoiceCommandResult> _executeSearchNotes(VoiceCommand command) async {
    try {
      final query = command.parameters['query'];
      if (query == null || query.isEmpty) {
        const message = 'Please specify what to search for';
        await _speak(message);
        
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.searchNotes,
          message: message,
          spoken: true,
        );
      }

      // Search notes using note service
      final searchResult = await _noteService.searchNotes(query);
      
      if (searchResult.isSuccess) {
        final notes = searchResult.data!;
        final message = notes.isNotEmpty 
            ? 'Found ${notes.length} note${notes.length == 1 ? '' : 's'} matching "$query"'
            : 'No notes found matching "$query"';
        
        await _speak(message);
        
        return VoiceCommandResult(
          success: true,
          commandType: VoiceCommandType.searchNotes,
          message: message,
          data: {'notes': notes.map((n) => n.toJson()).toList()},
          spoken: true,
        );
      } else {
        final message = 'Failed to search notes: ${searchResult.error}';
        await _speak(message);
        
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.searchNotes,
          message: message,
          spoken: true,
        );
      }
    } catch (e) {
      final message = 'Error searching notes: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.searchNotes,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute share note command
  Future<VoiceCommandResult> _executeShareNote(VoiceCommand command) async {
    try {
      const message = 'Note sharing via voice will be implemented soon';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.shareNote,
        message: message,
        spoken: true,
      );
    } catch (e) {
      final message = 'Error sharing note: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.shareNote,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute create family command
  Future<VoiceCommandResult> _executeCreateFamily(VoiceCommand command) async {
    try {
      final familyName = command.parameters['name'] ?? 'My Family';
      
      // Create family using family service
      final familyResult = await _familyService.createFamily(
        name: familyName,
        description: 'Created via voice command',
      );

      if (familyResult.isSuccess) {
        final message = 'Family "$familyName" created successfully';
        await _speak(message);
        
        return VoiceCommandResult(
          success: true,
          commandType: VoiceCommandType.createFamily,
          message: message,
          data: {'familyId': familyResult.data!.id},
          spoken: true,
        );
      } else {
        final message = 'Failed to create family: ${familyResult.error}';
        await _speak(message);
        
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.createFamily,
          message: message,
          spoken: true,
        );
      }
    } catch (e) {
      final message = 'Error creating family: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.createFamily,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute invite family command
  Future<VoiceCommandResult> _executeInviteFamily(VoiceCommand command) async {
    try {
      const message = 'Family invitations via voice will be implemented soon';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.inviteFamily,
        message: message,
        spoken: true,
      );
    } catch (e) {
      final message = 'Error inviting family member: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.inviteFamily,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute navigate command
  Future<VoiceCommandResult> _executeNavigate(VoiceCommand command) async {
    try {
      final destination = command.parameters['destination'];
      if (destination == null || destination.isEmpty) {
        const message = 'Please specify where to navigate';
        await _speak(message);
        
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.navigate,
          message: message,
          spoken: true,
        );
      }

      // Map voice destinations to routes
      final route = _mapDestinationToRoute(destination);
      if (route != null) {
        final message = 'Navigating to $destination';
        await _speak(message);
        
        return VoiceCommandResult(
          success: true,
          commandType: VoiceCommandType.navigate,
          message: message,
          data: {'route': route},
          spoken: true,
        );
      } else {
        final message = 'Unknown destination: $destination';
        await _speak(message);
        
        return VoiceCommandResult(
          success: false,
          commandType: VoiceCommandType.navigate,
          message: message,
          spoken: true,
        );
      }
    } catch (e) {
      final message = 'Error navigating: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.navigate,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute backup command
  Future<VoiceCommandResult> _executeBackup(VoiceCommand command) async {
    try {
      const message = 'Voice-activated backup will be implemented soon';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.backup,
        message: message,
        spoken: true,
      );
    } catch (e) {
      final message = 'Error creating backup: ${e.toString()}';
      await _speak(message);
      
      return VoiceCommandResult(
        success: false,
        commandType: VoiceCommandType.backup,
        message: message,
        spoken: true,
      );
    }
  }

  /// Execute help command
  VoiceCommandResult _executeHelp() {
    const helpText = '''
Available voice commands:
- "Create note" followed by title and content
- "Search for" followed by search terms
- "Create family" followed by family name
- "Go to" followed by destination (notes, family, settings)
- "Help" for this message

Example: "Create note shopping list about buy groceries"
''';

    _speak('Here are the available voice commands. Check the screen for details.');
    
    return VoiceCommandResult(
      success: true,
      commandType: VoiceCommandType.help,
      message: helpText,
      spoken: true,
    );
  }

  /// Map voice destination to app route
  String? _mapDestinationToRoute(String destination) {
    final dest = destination.toLowerCase();
    
    final routeMap = {
      'notes': '/notes',
      'note list': '/notes',
      'my notes': '/notes',
      'family': '/family',
      'families': '/family',
      'family members': '/family',
      'settings': '/settings',
      'preferences': '/settings',
      'notifications': '/notifications',
      'backup': '/backup',
      'profile': '/profile',
      'home': '/',
      'dashboard': '/',
    };

    for (final entry in routeMap.entries) {
      if (dest.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Speech-to-text status callback
  void _onSpeechStatus(String status) {
    print('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Speech-to-text error callback
  void _onSpeechError(dynamic error) {
    print('Speech error: $error');
    _isListening = false;
  }

  /// Speech-to-text result callback
    void _onSpeechResult(result) {
    if (result.finalResult) {
      print('Voice command received: ${result.recognizedWords}');
      processVoiceCommand(result.recognizedWords);
    }
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    try {
      if (_isTtsInitialized) {
        await _textToSpeech.speak(text);
      }
    } catch (e) {
      print('Failed to speak: $e');
    }
  }

  /// Speak text with options
  Future<VoiceServiceResult<bool>> speak(
    String text, {
    double? rate,
    double? pitch,
    double? volume,
    String? language,
  }) async {
    try {
      if (!_isTtsInitialized) {
        await _initializeTts();
      }

      if (language != null && language != _currentLanguage) {
        await _textToSpeech.setLanguage(language);
      }

      if (rate != null) await _textToSpeech.setSpeechRate(rate);
      if (pitch != null) await _textToSpeech.setPitch(pitch);
      if (volume != null) await _textToSpeech.setVolume(volume);

      await _textToSpeech.speak(text);
      
      return VoiceServiceResult.success(data: true);
    } catch (e) {
      return VoiceServiceResult.failure(
        error: 'Failed to speak: ${e.toString()}',
        code: 'TTS_FAILED',
      );
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _speechToText.locales();
      return languages.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('Failed to get languages: $e');
      return [_currentLanguage];
    }
  }

  /// Set language
  Future<VoiceServiceResult<bool>> setLanguage(String languageCode) async {
    try {
      _currentLanguage = languageCode;
      
      if (_isTtsInitialized) {
        await _textToSpeech.setLanguage(languageCode);
      }
      
      return VoiceServiceResult.success(data: true);
    } catch (e) {
      return VoiceServiceResult.failure(
        error: 'Failed to set language: ${e.toString()}',
        code: 'LANGUAGE_FAILED',
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stopListening();
      await _textToSpeech.stop();
      _isInitialized = false;
      _isTtsInitialized = false;
    } catch (e) {
      print('Failed to dispose voice services: $e');
    }
  }
}

/// Result wrapper for voice service operations
class VoiceServiceResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String? code;

  const VoiceServiceResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.code,
  });

  factory VoiceServiceResult.success({required T data}) {
    return VoiceServiceResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory VoiceServiceResult.failure({
    required String error,
    String? code,
  }) {
    return VoiceServiceResult._(
      isSuccess: false,
      error: error,
      code: code,
    );
  }
}