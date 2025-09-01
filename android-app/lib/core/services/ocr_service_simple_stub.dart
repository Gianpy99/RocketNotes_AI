import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Servizio OCR semplificato - STUB temporaneo
/// TODO: Sostituire con implementazione completa quando si aggiunge google_mlkit_text_recognition
class OCRService {
  static const String _logTag = '[OCR_STUB]';

  /// Estrae testo da immagine (versione stub)
  static Future<OCRResult> extractTextFromImage(String imagePath) async {
    debugPrint('$_logTag Chiamata OCR su: $imagePath');
    
    await Future.delayed(const Duration(milliseconds: 500)); // Simula processing

    return OCRResult(
      text: "OCR temporaneamente disabilitato.\nAggiungere google_mlkit_text_recognition al pubspec.yaml per abilitare l'estrazione testo.",
      confidence: 0.0,
      language: 'it',
      blocks: [],
      lines: [],
      words: [],
      processingTime: const Duration(milliseconds: 500),
      imagePath: imagePath,
    );
  }

  /// Cleanup - Stub
  static Future<void> dispose() async {
    debugPrint('$_logTag Disposed');
  }
}

/// Risultato OCR semplificato
class OCRResult {
  final String text;
  final double confidence;
  final String language;
  final List<String> blocks;
  final List<String> lines;
  final List<String> words;
  final Duration processingTime;
  final String imagePath;

  OCRResult({
    required this.text,
    required this.confidence,
    required this.language,
    required this.blocks,
    required this.lines,
    required this.words,
    required this.processingTime,
    required this.imagePath,
  });

  OCRResult.error(String errorMessage)
      : text = "",
        confidence = 0.0,
        language = 'unknown',
        blocks = [],
        lines = [],
        words = [],
        processingTime = Duration.zero,
        imagePath = errorMessage;

  bool get hasText => text.isNotEmpty;
  bool get isEmpty => text.isEmpty;
}
