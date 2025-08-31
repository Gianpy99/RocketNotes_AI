import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

// Simplified data models for web compatibility
class SimpleScannedContent {
  final String id;
  final String imagePath;
  final String extractedText;
  final DateTime scannedAt;
  final SimpleOCRMetadata metadata;
  final SimpleAIAnalysis? aiAnalysis;

  SimpleScannedContent({
    required this.id,
    required this.imagePath,
    required this.extractedText,
    required this.scannedAt,
    required this.metadata,
    this.aiAnalysis,
  });

  factory SimpleScannedContent.fromImage(String imagePath) {
    return SimpleScannedContent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      extractedText: '',
      scannedAt: DateTime.now(),
      metadata: SimpleOCRMetadata.empty(),
    );
  }
}

class SimpleOCRMetadata {
  final String engine;
  final double confidence;
  final Duration processingTime;

  SimpleOCRMetadata({
    required this.engine,
    required this.confidence,
    required this.processingTime,
  });

  factory SimpleOCRMetadata.empty() {
    return SimpleOCRMetadata(
      engine: 'mock_ocr',
      confidence: 0.0,
      processingTime: Duration.zero,
    );
  }
}

class SimpleAIAnalysis {
  final String summary;
  final List<String> keyTopics;
  final List<String> suggestedTags;
  final String suggestedTitle;
  final String contentType;
  final double sentiment;

  SimpleAIAnalysis({
    required this.summary,
    required this.keyTopics,
    required this.suggestedTags,
    required this.suggestedTitle,
    required this.contentType,
    required this.sentiment,
  });
}

class WebOCRService {
  static WebOCRService? _instance;
  static WebOCRService get instance => _instance ??= WebOCRService._();
  WebOCRService._();

  /// Process an image and extract content (mock implementation for web)
  Future<SimpleScannedContent> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final scannedContent = SimpleScannedContent.fromImage(imagePath);
      
      // Simulate processing delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock OCR - simulate text extraction
      final mockText = _generateMockOCRText(imagePath);
      
      stopwatch.stop();
      
      final processedContent = SimpleScannedContent(
        id: scannedContent.id,
        imagePath: imagePath,
        extractedText: mockText,
        scannedAt: scannedContent.scannedAt,
        metadata: SimpleOCRMetadata(
          engine: kIsWeb ? 'web_mock_ocr' : 'mobile_mock_ocr',
          confidence: 0.85,
          processingTime: stopwatch.elapsed,
        ),
        aiAnalysis: _generateMockAIAnalysis(mockText),
      );
      
      return processedContent;
      
    } catch (e) {
      debugPrint('OCR processing error: $e');
      stopwatch.stop();
      
      return SimpleScannedContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: imagePath,
        extractedText: 'Errore nell\'estrazione del testo',
        scannedAt: DateTime.now(),
        metadata: SimpleOCRMetadata(
          engine: 'error',
          confidence: 0.0,
          processingTime: stopwatch.elapsed,
        ),
      );
    }
  }

  /// Generate mock OCR text for demonstration
  String _generateMockOCRText(String imagePath) {
    final now = DateTime.now();
    final fileName = imagePath.split('/').last;
    
    return '''Meeting Notes - ${now.day}/${now.month}/${now.year}

Progetto RocketNotes AI
• Implementare scansione automatica pagine Rocketbook
• Integrazione OCR per estrazione testo
• Analisi AI per categorizzazione automatica
• Sistema di tag intelligenti

TODO:
- Completare integrazione camera ✓
- Testare OCR su diverse tipologie di testo
- Implementare AI analysis
- Ottimizzare performance

Note importanti:
Il sistema di scansione deve essere user-friendly e veloce.
Priorità alta per la compatibilità web.

Fonte: $fileName
Processato: ${now.toLocal()}''';
  }

  /// Generate mock AI analysis
  SimpleAIAnalysis _generateMockAIAnalysis(String text) {
    final keyTopics = _extractKeywords(text);
    final tags = _generateTags(text);
    
    return SimpleAIAnalysis(
      summary: 'Note di lavoro riguardanti il progetto RocketNotes AI con focus su implementazione OCR e analisi automatica.',
      keyTopics: keyTopics,
      suggestedTags: tags,
      suggestedTitle: _generateTitle(text),
      contentType: _detectContentType(text),
      sentiment: 0.7, // Positive sentiment
    );
  }

  List<String> _extractKeywords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final keywords = <String>[];
    
    const importantWords = [
      'rocketbook', 'ai', 'ocr', 'progetto', 'meeting', 'todo', 'importante',
      'implementare', 'sistema', 'analisi', 'automatica', 'scansione'
    ];
    
    for (final word in importantWords) {
      if (words.contains(word)) {
        keywords.add(word);
      }
    }
    
    return keywords.take(5).toList();
  }

  List<String> _generateTags(String text) {
    final lowerText = text.toLowerCase();
    final tags = <String>[];
    
    if (lowerText.contains('meeting') || lowerText.contains('riunione')) {
      tags.add('meeting');
    }
    if (lowerText.contains('todo') || lowerText.contains('task')) {
      tags.add('todo');
    }
    if (lowerText.contains('progetto') || lowerText.contains('project')) {
      tags.add('progetto');
    }
    if (lowerText.contains('importante') || lowerText.contains('priorità')) {
      tags.add('importante');
    }
    if (lowerText.contains('ai') || lowerText.contains('intelligenza')) {
      tags.add('ai');
    }
    
    return tags.take(3).toList();
  }

  String _generateTitle(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('•') && !trimmed.startsWith('-')) {
        if (trimmed.length <= 50) {
          return trimmed;
        } else {
          return '${trimmed.substring(0, 47)}...';
        }
      }
    }
    return 'Nota Scansionata ${DateTime.now().day}/${DateTime.now().month}';
  }

  String _detectContentType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('meeting') || lowerText.contains('riunione')) {
      return 'meeting';
    }
    if (lowerText.contains('todo') || lowerText.contains('task')) {
      return 'todo';
    }
    if (lowerText.contains('progetto') || lowerText.contains('project')) {
      return 'lavoro';
    }
    if (lowerText.contains('personale') || lowerText.contains('famiglia')) {
      return 'personale';
    }
    
    return 'note';
  }
}
