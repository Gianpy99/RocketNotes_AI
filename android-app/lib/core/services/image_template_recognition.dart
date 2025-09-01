import '../services/rocketbook_template_service.dart';
import 'package:flutter/foundation.dart';

/// Servizio per il riconoscimento di template nelle immagini del Rocketbook
class ImageTemplateRecognition {
  
  /// Analizza un'immagine per riconoscere il template Rocketbook
  static Future<TemplateDetectionResult> analyzeImage(String imagePath) async {
    // Simulazione di analisi immagine - in una implementazione reale
    // qui ci sarebbe il computer vision per riconoscere le caratteristiche
    
    // Per ora usiamo euristica basata su caratteristiche simulate
    final features = await _extractImageFeatures(imagePath);
    
    final detectedTemplate = RocketbookTemplateService.detectTemplate(
      hasLines: features.hasLines,
      hasGrid: features.hasGrid,
      hasDots: features.hasDots,
      hasCalendarStructure: features.hasCalendarStructure,
      hasTableStructure: features.hasTableStructure,
      hasSections: features.hasSections,
      isBlank: features.isBlank,
      textContent: features.extractedText,
    );

    return TemplateDetectionResult(
      template: detectedTemplate,
      confidence: features.confidence,
      features: features,
      chatGptPrompt: RocketbookTemplateService.generateChatGptPrompt(
        detectedTemplate,
        features.extractedText,
      ),
    );
  }

  /// Simula l'estrazione di caratteristiche dall'immagine
  static Future<ImageFeatures> _extractImageFeatures(String imagePath) async {
    // In una implementazione reale, qui useremo:
    // - OCR per estrarre testo
    // - Computer Vision per riconoscere pattern (righe, griglie, punti)
    // - Analisi layout per identificare strutture (calendario, tabelle)
    
    // Per ora restituiamo features simulate basate sul nome file o altri indicatori
    final filename = imagePath.toLowerCase();
    
    return ImageFeatures(
      hasLines: filename.contains('line') || filename.contains('riga'),
      hasGrid: filename.contains('grid') || filename.contains('griglia'),
      hasDots: filename.contains('dot') || filename.contains('punto'),
      hasCalendarStructure: filename.contains('calendar') || filename.contains('week') || filename.contains('month'),
      hasTableStructure: filename.contains('table') || filename.contains('tabella'),
      hasSections: filename.contains('meeting') || filename.contains('project'),
      isBlank: filename.contains('blank') || filename.contains('bianco'),
      extractedText: _simulateOCR(filename),
      confidence: 0.85, // Simulated confidence
    );
  }

  /// Simula OCR per estrazione testo
  static String? _simulateOCR(String filename) {
    // In una implementazione reale qui useremmo OCR vero
    if (filename.contains('meeting')) {
      return 'Meeting notes agenda partecipanti azioni follow-up';
    } else if (filename.contains('project')) {
      return 'Progetto milestone deadline obiettivi timeline';
    } else if (filename.contains('todo') || filename.contains('list')) {
      return 'Todo list checklist priorità compiti';
    }
    return null;
  }

  /// Fornisce suggerimenti per migliorare il riconoscimento
  static List<String> getRecognitionTips() {
    return [
      '📱 Scatta foto con buona illuminazione per migliorare il riconoscimento',
      '📐 Mantieni la pagina dritta e centrata nell\'inquadratura',
      '🔍 Assicurati che il testo sia leggibile e non sfocato',
      '📄 Includi l\'intera pagina nel frame per riconoscere la struttura',
      '✨ Usa sfondo contrastante per evidenziare la pagina',
      '🎯 Focalizza su una pagina alla volta per migliore precisione',
    ];
  }
}

/// Risultato del riconoscimento template
class TemplateDetectionResult {
  final RocketbookTemplate template;
  final double confidence;
  final ImageFeatures features;
  final String chatGptPrompt;

  TemplateDetectionResult({
    required this.template,
    required this.confidence,
    required this.features,
    required this.chatGptPrompt,
  });

  /// Converte in formato JSON per facile serializzazione
  Map<String, dynamic> toJson() {
    return {
      'template': template.toJson(),
      'confidence': confidence,
      'features': features.toJson(),
      'chatGptPrompt': chatGptPrompt,
      'detectionTime': DateTime.now().toIso8601String(),
    };
  }

  /// Verifica se il riconoscimento è affidabile
  bool get isReliable => confidence > 0.7;

  /// Ottiene una descrizione user-friendly del risultato
  String get userDescription {
    final confidenceText = confidence > 0.8 ? 'Alta' : confidence > 0.6 ? 'Media' : 'Bassa';
    return 'Template riconosciuto: ${template.name} (Confidenza: $confidenceText)';
  }
}

/// Caratteristiche estratte dall'immagine
class ImageFeatures {
  final bool hasLines;
  final bool hasGrid;
  final bool hasDots;
  final bool hasCalendarStructure;
  final bool hasTableStructure;
  final bool hasSections;
  final bool isBlank;
  final String? extractedText;
  final double confidence;

  ImageFeatures({
    required this.hasLines,
    required this.hasGrid,
    required this.hasDots,
    required this.hasCalendarStructure,
    required this.hasTableStructure,
    required this.hasSections,
    required this.isBlank,
    this.extractedText,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasLines': hasLines,
      'hasGrid': hasGrid,
      'hasDots': hasDots,
      'hasCalendarStructure': hasCalendarStructure,
      'hasTableStructure': hasTableStructure,
      'hasSections': hasSections,
      'isBlank': isBlank,
      'extractedText': extractedText,
      'confidence': confidence,
    };
  }

  /// Ottiene una lista delle caratteristiche rilevate
  List<String> get detectedFeatures {
    final features = <String>[];
    if (hasLines) features.add('Righe orizzontali');
    if (hasGrid) features.add('Griglia quadrettata');
    if (hasDots) features.add('Griglia a punti');
    if (hasCalendarStructure) features.add('Struttura calendario');
    if (hasTableStructure) features.add('Struttura tabellare');
    if (hasSections) features.add('Sezioni organizzate');
    if (isBlank) features.add('Pagina bianca');
    return features;
  }
}

/// Utilità per il debug e testing del riconoscimento
class TemplateRecognitionDebug {
  
  /// Testa il riconoscimento con casi di esempio
  static Map<String, TemplateDetectionResult> runTestCases() {
    final testCases = {
      'meeting_notes_example.jpg': ImageFeatures(
        hasLines: true,
        hasGrid: false,
        hasDots: false,
        hasCalendarStructure: false,
        hasTableStructure: false,
        hasSections: true,
        isBlank: false,
        extractedText: 'Meeting 15/01/2025 Partecipanti: Marco, Sara Agenda: Budget Q1 Action: Review by Friday',
        confidence: 0.92,
      ),
      'project_plan_example.jpg': ImageFeatures(
        hasLines: false,
        hasGrid: false,
        hasDots: true,
        hasCalendarStructure: false,
        hasTableStructure: false,
        hasSections: true,
        isBlank: false,
        extractedText: 'Progetto App Mobile Milestone 1: Design UI Deadline: 31/01 Team: 3 sviluppatori',
        confidence: 0.88,
      ),
      'weekly_planner_example.jpg': ImageFeatures(
        hasLines: true,
        hasGrid: false,
        hasDots: false,
        hasCalendarStructure: true,
        hasTableStructure: false,
        hasSections: true,
        isBlank: false,
        extractedText: 'Lunedì 13/01 - Riunione team Martedì 14/01 - Presentazione Mercoledì 15/01 - Review',
        confidence: 0.95,
      ),
    };

    final results = <String, TemplateDetectionResult>{};
    
    for (final entry in testCases.entries) {
      final features = entry.value;
      final template = RocketbookTemplateService.detectTemplate(
        hasLines: features.hasLines,
        hasGrid: features.hasGrid,
        hasDots: features.hasDots,
        hasCalendarStructure: features.hasCalendarStructure,
        hasTableStructure: features.hasTableStructure,
        hasSections: features.hasSections,
        isBlank: features.isBlank,
        textContent: features.extractedText,
      );

      results[entry.key] = TemplateDetectionResult(
        template: template,
        confidence: features.confidence,
        features: features,
        chatGptPrompt: RocketbookTemplateService.generateChatGptPrompt(
          template,
          features.extractedText,
        ),
      );
    }

    return results;
  }

  /// Stampa statistiche di riconoscimento per debugging
  static void printRecognitionStats() {
    final stats = RocketbookTemplateService.getTemplateStats();
    debugPrint('=== ROCKETBOOK TEMPLATE RECOGNITION STATS ===');
    debugPrint('Total Templates: ${stats['totalTemplates']}');
    debugPrint('Total Pages: ${stats['totalPages']}');
    debugPrint('Categories: ${stats['categoriesBreakdown']}');
    debugPrint('Available Templates: ${stats['templates']}');
    
    final testResults = runTestCases();
    debugPrint('\n=== TEST RESULTS ===');
    for (final entry in testResults.entries) {
      final result = entry.value;
      debugPrint('${entry.key}: ${result.template.name} (${(result.confidence * 100).toStringAsFixed(1)}%)');
    }
  }
}
