import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/scanned_content.dart';
import '../../../core/debug/debug_logger.dart';

class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._();
  OCRService._();

  TextRecognizer? _textRecognizer;
  BarcodeScanner? _barcodeScanner;

  /// Initialize the OCR service
  Future<void> initialize() async {
    DebugLogger().log('🔧 OCR Service: Initializing...');

    // Initialize Google ML Kit for all platforms
    DebugLogger().log('🤖 OCR: Initializing Google ML Kit');
    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _barcodeScanner = BarcodeScanner();
      DebugLogger().log('✅ OCR: Google ML Kit initialized successfully');
    } catch (e) {
      DebugLogger().log('❌ OCR: Failed to initialize Google ML Kit: $e');
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
      scannedContent.ocrMetadata.processingTime = stopwatch.elapsed;
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
        processingTime: stopwatch.elapsed,
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
      scannedContent.rawText = recognizedText.text;
      
      DebugLogger().log('📥 OCR: Received result from ML Kit');
      DebugLogger().log('🔢 OCR: Found ${recognizedText.blocks.length} text blocks');
      
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
      
      // Set metadata
      scannedContent.ocrMetadata = OCRMetadata(
        engine: 'google_ml_kit',
        overallConfidence: overallConfidence,
        detectedLanguages: ['en'], // ML Kit would require additional detection
        processingTime: Duration.zero, // Will be set by caller
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

  /// Cleanup resources
  Future<void> dispose() async {
    await _textRecognizer?.close();
    await _barcodeScanner?.close();
    _textRecognizer = null;
    _barcodeScanner = null;
  }
}
