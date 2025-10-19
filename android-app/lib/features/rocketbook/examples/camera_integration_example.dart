// ==========================================
// EXAMPLE: Camera Service Integration with Rocketbook
// File: lib/features/camera/services/camera_scan_service.dart
// ==========================================

/*
 * This is an EXAMPLE of how to integrate Rocketbook template recognition
 * into your existing camera scan workflow.
 * 
 * Copy relevant parts into your actual camera service.
 */

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../rocketbook/services/template_recognition_service.dart';
import '../../rocketbook/services/template_data_extractor.dart';
import '../../rocketbook/services/symbol_action_service.dart';
import '../../rocketbook/models/rocketbook_template.dart';
import '../../../data/models/note.dart';
import '../../../data/repositories/note_repository.dart';

class CameraScanService {
  final _noteRepo = NoteRepository();
  
  /// Process a scanned Rocketbook page
  Future<ScanResult> processRocketbookScan({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      debugPrint('[CameraScan] Processing Rocketbook page...');
      
      // STEP 1: Recognize template type and detect marked symbols
      debugPrint('[CameraScan] Step 1: Recognizing template...');
      final recognition = await TemplateRecognitionService.instance
          .recognizeTemplate(imageBytes);
      
      debugPrint('[CameraScan] ✓ Template: ${recognition.template.displayName}');
      debugPrint('[CameraScan] ✓ Confidence: ${(recognition.confidence * 100).toStringAsFixed(1)}%');
      debugPrint('[CameraScan] ✓ Marked symbols: ${recognition.markedSymbols.map((s) => s.displayName).join(", ")}');
      
      if (recognition.error != null) {
        debugPrint('[CameraScan] ⚠ Recognition error: ${recognition.error}');
      }
      
      // STEP 2: Run OCR to extract text
      // Replace this with your actual OCR service
      debugPrint('[CameraScan] Step 2: Running OCR...');
      final ocrText = await _performOCR(imageBytes);
      debugPrint('[CameraScan] ✓ OCR completed: ${ocrText.length} characters');
      
      // STEP 3: Extract structured data based on template type
      debugPrint('[CameraScan] Step 3: Extracting structured data...');
      final extractedData = await TemplateDataExtractor.instance.extractData(
        template: recognition.template,
        ocrText: ocrText,
      );
      
      debugPrint('[CameraScan] ✓ Title: ${extractedData.title}');
      if (extractedData.hasStructuredData) {
        debugPrint('[CameraScan] ✓ Structured data: ${extractedData.structuredData!.keys.join(", ")}');
        
        // Log some interesting extracted data
        if (extractedData.structuredData!.containsKey('attendees')) {
          debugPrint('[CameraScan]   - Attendees: ${extractedData.structuredData!['attendees']}');
        }
        if (extractedData.structuredData!.containsKey('actionItems')) {
          final items = extractedData.structuredData!['actionItems'] as List;
          debugPrint('[CameraScan]   - Action items: ${items.length}');
        }
        if (extractedData.structuredData!.containsKey('date')) {
          debugPrint('[CameraScan]   - Date: ${extractedData.structuredData!['date']}');
        }
      }
      
      // STEP 4: Create note
      debugPrint('[CameraScan] Step 4: Creating note...');
      final note = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: extractedData.title,
        content: extractedData.content,
        mode: 'personal', // or determine from template/symbols
        tags: _generateTags(recognition.template, extractedData),
        attachments: [], // Add image path if needed
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        isArchived: false,
      );
      
      // TODO: Store Rocketbook metadata in a custom field or separate table
      // For now, you could add to note.aiSummary or create a metadata field
      
      // STEP 5: Execute symbol actions
      if (recognition.markedSymbols.isNotEmpty) {
        debugPrint('[CameraScan] Step 5: Executing symbol actions...');
        final actionResult = await SymbolActionService.instance.executeActions(
          markedSymbols: recognition.markedSymbols,
          note: note,
        );
        
        debugPrint('[CameraScan] ✓ Actions: ${actionResult.summary}');
        if (actionResult.hasErrors) {
          for (final error in actionResult.errors) {
            debugPrint('[CameraScan] ⚠ Action error: $error');
          }
        }
        
        // Note may have been modified by actions (topic, favorite, reminder, etc.)
        // Reload or pass updated note if needed
      }
      
      // STEP 6: Save note to repository
      debugPrint('[CameraScan] Step 6: Saving note...');
      await _noteRepo.saveNote(note);
      debugPrint('[CameraScan] ✓ Note saved with ID: ${note.id}');
      
      return ScanResult(
        success: true,
        note: note,
        template: recognition.template,
        confidence: recognition.confidence,
        extractedData: extractedData,
        markedSymbols: recognition.markedSymbols,
      );
      
    } catch (e, stackTrace) {
      debugPrint('[CameraScan] ❌ Error processing scan: $e');
      debugPrint('[CameraScan] Stack trace: $stackTrace');
      
      return ScanResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Perform OCR on image bytes
  /// Replace this with your actual OCR implementation
  Future<String> _performOCR(Uint8List imageBytes) async {
    // TODO: Implement with your OCR service
    // Examples:
    // - Google ML Kit Text Recognition
    // - Firebase ML Vision
    // - Tesseract OCR
    // - Cloud Vision API
    
    // For now, return placeholder
    await Future.delayed(const Duration(milliseconds: 500));
    return 'OCR text would be here...';
  }
  
  /// Generate tags based on template type and extracted data
  List<String> _generateTags(RocketbookTemplate template, ExtractedData data) {
    final tags = <String>[
      'rocketbook',
      template.name,
    ];
    
    // Add template-specific tags
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

/// Result of a Rocketbook scan operation
class ScanResult {
  final bool success;
  final NoteModel? note;
  final RocketbookTemplate? template;
  final double? confidence;
  final ExtractedData? extractedData;
  final List<RocketbookSymbol>? markedSymbols;
  final String? error;
  
  ScanResult({
    required this.success,
    this.note,
    this.template,
    this.confidence,
    this.extractedData,
    this.markedSymbols,
    this.error,
  });
  
  @override
  String toString() {
    if (!success) {
      return 'ScanResult(success: false, error: $error)';
    }
    return 'ScanResult(success: true, template: ${template?.displayName}, confidence: ${(confidence! * 100).toStringAsFixed(1)}%, symbols: ${markedSymbols?.length ?? 0})';
  }
}
