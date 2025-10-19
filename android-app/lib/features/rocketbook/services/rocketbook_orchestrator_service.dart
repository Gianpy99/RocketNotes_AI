// ==========================================
// lib/features/rocketbook/services/rocketbook_orchestrator_service.dart
// ==========================================

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'template_recognition_service.dart';
import 'template_data_extractor.dart';
import 'symbol_action_service.dart';
import '../models/rocketbook_template.dart';
import '../../../data/models/note_model.dart';
import '../../../data/repositories/note_repository.dart';

/// Orchestrates the complete Rocketbook scan workflow
/// Makes Rocketbook integration seamless and automatic
class RocketbookOrchestratorService {
  static final RocketbookOrchestratorService _instance = RocketbookOrchestratorService._();
  static RocketbookOrchestratorService get instance => _instance;
  
  RocketbookOrchestratorService._();

  final _noteRepo = NoteRepository();
  bool _isEnabled = true;
  double _confidenceThreshold = 0.6; // 60% confidence to consider it a Rocketbook page

  /// Enable/disable automatic Rocketbook detection
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('[RocketbookOrchestrator] ${enabled ? "Enabled" : "Disabled"}');
  }

  /// Set confidence threshold for Rocketbook detection
  void setConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    debugPrint('[RocketbookOrchestrator] Confidence threshold: ${(_confidenceThreshold * 100).toStringAsFixed(0)}%');
  }

  /// Process a scanned image - automatically detects if it's a Rocketbook page
  /// Returns ProcessResult with isRocketbook flag and created note
  Future<ProcessResult> processScannedImage({
    required Uint8List imageBytes,
    required String ocrText,
    required String userId,
    String mode = 'personal',
  }) async {
    if (!_isEnabled) {
      debugPrint('[RocketbookOrchestrator] Disabled - skipping detection');
      return ProcessResult.notRocketbook();
    }

    try {
      debugPrint('[RocketbookOrchestrator] 🔍 Analyzing image...');
      
      // STEP 1: Check if it's a Rocketbook page
      final recognition = await TemplateRecognitionService.instance
          .recognizeTemplate(imageBytes);
      
      final isRocketbook = recognition.template != RocketbookTemplate.unknown &&
                          recognition.confidence >= _confidenceThreshold;
      
      if (!isRocketbook) {
        debugPrint('[RocketbookOrchestrator] ❌ Not a Rocketbook page (confidence: ${(recognition.confidence * 100).toStringAsFixed(1)}%)');
        return ProcessResult.notRocketbook();
      }

      debugPrint('[RocketbookOrchestrator] ✅ ROCKETBOOK DETECTED!');
      debugPrint('[RocketbookOrchestrator]    Template: ${recognition.template.displayName}');
      debugPrint('[RocketbookOrchestrator]    Confidence: ${(recognition.confidence * 100).toStringAsFixed(1)}%');
      debugPrint('[RocketbookOrchestrator]    Symbols: ${recognition.markedSymbols.length} marked');

      // STEP 2: Extract structured data
      final extractedData = await TemplateDataExtractor.instance.extractData(
        template: recognition.template,
        ocrText: ocrText,
      );

      debugPrint('[RocketbookOrchestrator] 📊 Data extracted:');
      debugPrint('[RocketbookOrchestrator]    Title: ${extractedData.title}');
      if (extractedData.hasStructuredData) {
        debugPrint('[RocketbookOrchestrator]    Structured fields: ${extractedData.structuredData!.keys.join(", ")}');
      }

      // STEP 3: Create note with enhanced content
      final enhancedContent = _buildEnhancedContent(extractedData);
      final tags = _generateTags(recognition.template, extractedData);

      var note = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: extractedData.title,
        content: enhancedContent,
        mode: mode,
        tags: tags,
        attachments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        isArchived: false,
      );

      // STEP 4: Execute symbol actions (this may modify the note)
      SymbolActionResult? actionResult;
      if (recognition.markedSymbols.isNotEmpty) {
        debugPrint('[RocketbookOrchestrator] ⚡ Executing ${recognition.markedSymbols.length} symbol actions...');
        
        actionResult = await SymbolActionService.instance.executeActions(
          markedSymbols: recognition.markedSymbols,
          note: note,
        );

        debugPrint('[RocketbookOrchestrator]    ${actionResult.summary}');
        
        if (actionResult.hasErrors) {
          for (final error in actionResult.errors) {
            debugPrint('[RocketbookOrchestrator]    ⚠️ $error');
          }
        }
      }

      // STEP 5: Save note
      await _noteRepo.saveNote(note);
      debugPrint('[RocketbookOrchestrator] ✅ Note saved with ID: ${note.id}');

      return ProcessResult.rocketbook(
        note: note,
        template: recognition.template,
        confidence: recognition.confidence,
        extractedData: extractedData,
        markedSymbols: recognition.markedSymbols,
        actionResult: actionResult,
      );

    } catch (e, stackTrace) {
      debugPrint('[RocketbookOrchestrator] ❌ Error: $e');
      debugPrint('[RocketbookOrchestrator] Stack: $stackTrace');
      return ProcessResult.error(e.toString());
    }
  }

  /// Build enhanced content with structured data formatting
  String _buildEnhancedContent(ExtractedData data) {
    final buffer = StringBuffer();
    buffer.writeln(data.content);

    if (data.hasStructuredData) {
      buffer.writeln('\n---\n');
      buffer.writeln('📋 Structured Data:\n');

      final structured = data.structuredData!;

      // Date
      if (structured.containsKey('date')) {
        buffer.writeln('📅 Date: ${structured['date']}');
      }

      // Attendees
      if (structured.containsKey('attendees')) {
        final attendees = structured['attendees'] as List?;
        if (attendees != null && attendees.isNotEmpty) {
          buffer.writeln('\n👥 Attendees:');
          for (final attendee in attendees) {
            buffer.writeln('  • $attendee');
          }
        }
      }

      // Action Items
      if (structured.containsKey('actionItems')) {
        final items = structured['actionItems'] as List?;
        if (items != null && items.isNotEmpty) {
          buffer.writeln('\n✅ Action Items:');
          for (final item in items) {
            buffer.writeln('  ☐ $item');
          }
        }
      }

      // Tasks
      if (structured.containsKey('tasks')) {
        final tasks = structured['tasks'] as List?;
        if (tasks != null && tasks.isNotEmpty) {
          buffer.writeln('\n📝 Tasks:');
          for (final task in tasks) {
            buffer.writeln('  ☐ $task');
          }
        }
      }

      // Goals
      if (structured.containsKey('goals')) {
        final goals = structured['goals'] as List?;
        if (goals != null && goals.isNotEmpty) {
          buffer.writeln('\n🎯 Goals:');
          for (final goal in goals) {
            buffer.writeln('  • $goal');
          }
        }
      }

      // Events
      if (structured.containsKey('events')) {
        final events = structured['events'] as List?;
        if (events != null && events.isNotEmpty) {
          buffer.writeln('\n📆 Events:');
          for (final event in events) {
            if (event is Map) {
              buffer.writeln('  • ${event['date']}: ${event['event']}');
            }
          }
        }
      }
    }

    return buffer.toString();
  }

  /// Generate tags based on template and data
  List<String> _generateTags(RocketbookTemplate template, ExtractedData data) {
    final tags = <String>['rocketbook', template.name];

    switch (template) {
      case RocketbookTemplate.meetingNotes:
        tags.add('meeting');
        if (data.structuredData?.containsKey('date') == true) {
          tags.add('dated');
        }
        break;
      
      case RocketbookTemplate.projectManagement:
        tags.add('project');
        tags.add('tasks');
        break;
      
      case RocketbookTemplate.weekly:
      case RocketbookTemplate.monthly:
        tags.add('planner');
        tags.add('calendar');
        break;
      
      case RocketbookTemplate.monthlyDashboard:
        tags.add('dashboard');
        tags.add('goals');
        break;
      
      case RocketbookTemplate.listPage:
        tags.add('checklist');
        break;
      
      default:
        break;
    }

    return tags;
  }
}

/// Result of processing a scanned image
class ProcessResult {
  final bool isRocketbook;
  final bool success;
  final NoteModel? note;
  final RocketbookTemplate? template;
  final double? confidence;
  final ExtractedData? extractedData;
  final List<RocketbookSymbol>? markedSymbols;
  final SymbolActionResult? actionResult;
  final String? error;

  ProcessResult._({
    required this.isRocketbook,
    required this.success,
    this.note,
    this.template,
    this.confidence,
    this.extractedData,
    this.markedSymbols,
    this.actionResult,
    this.error,
  });

  factory ProcessResult.rocketbook({
    required NoteModel note,
    required RocketbookTemplate template,
    required double confidence,
    required ExtractedData extractedData,
    required List<RocketbookSymbol> markedSymbols,
    SymbolActionResult? actionResult,
  }) {
    return ProcessResult._(
      isRocketbook: true,
      success: true,
      note: note,
      template: template,
      confidence: confidence,
      extractedData: extractedData,
      markedSymbols: markedSymbols,
      actionResult: actionResult,
    );
  }

  factory ProcessResult.notRocketbook() {
    return ProcessResult._(
      isRocketbook: false,
      success: true,
    );
  }

  factory ProcessResult.error(String error) {
    return ProcessResult._(
      isRocketbook: false,
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (!success) return 'ProcessResult(error: $error)';
    if (!isRocketbook) return 'ProcessResult(not Rocketbook)';
    return 'ProcessResult(Rocketbook: ${template?.displayName}, confidence: ${(confidence! * 100).toStringAsFixed(1)}%, symbols: ${markedSymbols?.length ?? 0})';
  }
}
