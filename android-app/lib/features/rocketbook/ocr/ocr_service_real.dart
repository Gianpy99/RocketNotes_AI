import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import '../models/scanned_content.dart';
import '../../../core/debug/debug_logger.dart';

class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._();
  OCRService._();

  TextRecognizer? _textRecognizer;
  DigitalInkRecognizer? _digitalInkRecognizer;

  /// Initialize the OCR service with ML Kit V2
  Future<void> initialize() async {
    DebugLogger().log('🔧 OCR Service: Initializing ML Kit V2 (Handwriting Optimized)...');

    // Initialize Google ML Kit V2 Text Recognition
    DebugLogger().log('🤖 OCR: Initializing Google ML Kit V2 (Text Recognition)');
    try {
      // V2 API: Use TextRecognizer with Latin script
      // Note: ML Kit V2 automatically handles handwriting better than V1
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      // Initialize Digital Ink Recognition for future enhancement
      DebugLogger().log('✍️ OCR: Initializing Digital Ink Recognition for handwriting');
      _digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'en');
      
      DebugLogger().log('✅ OCR: Google ML Kit V2 initialized with handwriting optimization');
    } catch (e) {
      DebugLogger().log('❌ OCR: Failed to initialize Google ML Kit V2: $e');
      rethrow;
    }
  }

  /// Process an image and extract all content
  Future<ScannedContent> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    DebugLogger().log('🔍 OCR: Starting image processing for: $imagePath');
    
    try {
      // Create initial scanned content
      final scannedContent = ScannedContent.fromImage(imagePath);
      scannedContent.status = ProcessingStatus.processing;

      await _processImage(scannedContent, imagePath);
      
      stopwatch.stop();
      scannedContent.ocrMetadata.processingTimeMs = stopwatch.elapsedMilliseconds;
      scannedContent.status = ProcessingStatus.completed;
      
      DebugLogger().log('✅ OCR: Processing completed in ${stopwatch.elapsedMilliseconds}ms');
      DebugLogger().log('📝 OCR: Extracted ${scannedContent.rawText.length} characters');
      
      return scannedContent;
    } catch (e) {
      stopwatch.stop();
      DebugLogger().log('❌ OCR: Processing failed: $e');
      
      final scannedContent = ScannedContent.fromImage(imagePath);
      scannedContent.status = ProcessingStatus.failed;
      scannedContent.rawText = 'OCR processing failed: $e';
      scannedContent.ocrMetadata = OCRMetadata(
        engine: 'google_ml_kit_error',
        overallConfidence: 0.0,
        detectedLanguages: [],
        processingTimeMs: stopwatch.elapsedMilliseconds,
        additionalData: {'error': e.toString()},
      );
      return scannedContent;
    }
  }

  /// Process image using Google ML Kit (works on all platforms)
  Future<void> _processImage(ScannedContent scannedContent, String imagePath) async {
    DebugLogger().log('🤖 OCR: Processing image with Google ML Kit');
    
    if (_textRecognizer == null) {
      throw Exception('Google ML Kit not initialized. Call initialize() first.');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      
      DebugLogger().log('📤 OCR: Sending image to ML Kit engine');
      
      // Extract text
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      
      // Apply handwriting post-processing to improve results
      String rawText = recognizedText.text;
      String processedText = _postProcessHandwrittenText(rawText);
      scannedContent.rawText = processedText;
      
      DebugLogger().log('📥 OCR: Received result from ML Kit');
      DebugLogger().log('🔢 OCR: Found ${recognizedText.blocks.length} text blocks');
      DebugLogger().log('✍️ OCR: Applied handwriting corrections (${rawText.length} → ${processedText.length} chars)');
      
      // Calculate confidence (ML Kit doesn't provide overall confidence)
      double totalConfidence = 0.0;
      int elementCount = 0;
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            if (element.confidence != null) {
              totalConfidence += element.confidence!;
              elementCount++;
            }
          }
        }
      }
      
      final overallConfidence = elementCount > 0 ? totalConfidence / elementCount : 0.0;
      
      // Extract tables and diagrams (simplified implementation)
      _extractTablesFromMLKitText(scannedContent, recognizedText);
      _extractDiagramsFromText(scannedContent);
      
      // Set metadata with handwriting flag
      scannedContent.ocrMetadata = OCRMetadata(
        engine: 'google_ml_kit_v2_handwriting',
        overallConfidence: overallConfidence,
        detectedLanguages: ['en'], // ML Kit would require additional detection
        processingTimeMs: 0, // Will be set by caller
        additionalData: {
          'blocks_count': recognizedText.blocks.length,
          'cross_platform': true,
        },
      );
      
    } catch (e) {
      DebugLogger().log('❌ OCR: ML Kit processing error: $e');
      rethrow;
    }
  }

  /// Extract tables from ML Kit text
  void _extractTablesFromMLKitText(ScannedContent scannedContent, RecognizedText recognizedText) {
    final tableRows = <List<String>>[];
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.contains('|') || text.contains('\t')) {
          final columns = text.split(RegExp(r'[|\t]')).map((e) => e.trim()).toList();
          if (columns.length > 1) {
            tableRows.add(columns);
          }
        }
      }
    }
    
    if (tableRows.isNotEmpty) {
      scannedContent.tables.add(
        TableData(
          rows: tableRows,
          boundingBox: BoundingBox(left: 0, top: 0, width: 100, height: 100),
          confidence: 0.8, // Default confidence for ML Kit
        ),
      );
    }
  }

  /// Extract diagrams from text (basic implementation)
  void _extractDiagramsFromText(ScannedContent scannedContent) {
    final text = scannedContent.rawText.toLowerCase();
    
    // Look for diagram indicators
    if (text.contains('diagram') || 
        text.contains('chart') || 
        text.contains('flow') ||
        text.contains('architecture') ||
        text.contains('└') || text.contains('├') || text.contains('┐')) {
      
      scannedContent.diagrams.add(
        DiagramData(
          type: 'technical',
          description: 'Detected diagram or chart in the image',
          boundingBox: BoundingBox(left: 0, top: 0, width: 100, height: 100),
          elements: {
            'type': 'detected_from_text',
            'indicators': ['diagram', 'chart', 'flow'],
          },
          confidence: 0.7,
        ),
      );
    }
  }

  /// Post-process handwritten text to fix common OCR errors
  /// This improves recognition quality specifically for handwritten notes
  String _postProcessHandwrittenText(String text) {
    if (text.isEmpty) return text;
    
    DebugLogger().log('🔧 OCR: Applying handwriting corrections...');
    
    String processed = text;
    
    // Common handwriting OCR errors - Context-aware corrections
    final corrections = {
      // Number/Letter confusion
      RegExp(r'\b0+([A-Za-z])'): '00\$1',  // 0OO → 000
      RegExp(r'O([0-9])'): '0\$1',          // O1 → 01
      RegExp(r'([0-9])O\b'): '\$10',        // 1O → 10
      RegExp(r'\b1([Il])'): '11',           // 1I → 11
      RegExp(r'\b([Il])1\b'): '11',         // I1 → 11
      
      // Common word corrections for notes
      RegExp(r'\bf0r\b', caseSensitive: false): 'for',
      RegExp(r'\bth1s\b', caseSensitive: false): 'this',
      RegExp(r'\bw1th\b', caseSensitive: false): 'with',
      RegExp(r'\bt0\b', caseSensitive: false): 'to',
      RegExp(r'\b0f\b', caseSensitive: false): 'of',
      RegExp(r'\ban0\b', caseSensitive: false): 'and',
      
      // Symbol corrections
      RegExp(r'\|(?=[A-Za-z])'): 'I',       // |text → Itext
      RegExp(r'(?<=[A-Za-z])\|'): 'l',      // text| → textl
      
      // Multiple spaces to single space
      RegExp(r'\s+'): ' ',
    };
    
    // Apply corrections
    corrections.forEach((pattern, replacement) {
      processed = processed.replaceAll(pattern, replacement);
    });
    
    // Clean up extra whitespace
    processed = processed.trim();
    
    // Log significant changes
    if (processed != text) {
      final changes = _calculateDifference(text, processed);
      DebugLogger().log('✅ OCR: Applied $changes handwriting corrections');
    }
    
    return processed;
  }
  
  /// Calculate number of character differences
  int _calculateDifference(String original, String processed) {
    int diff = 0;
    final minLength = original.length < processed.length ? original.length : processed.length;
    
    for (int i = 0; i < minLength; i++) {
      if (original[i] != processed[i]) diff++;
    }
    
    // Add difference in length
    diff += (original.length - processed.length).abs();
    
    return diff;
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _textRecognizer?.close();
    await _digitalInkRecognizer?.close();
    _textRecognizer = null;
    _digitalInkRecognizer = null;
  }
}
