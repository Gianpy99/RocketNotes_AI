import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import '../models/scanned_content.dart';
import '../camera/web_camera_service.dart';
import '../../../core/debug/debug_logger.dart';

// Conditional import for web-only Tesseract bindings
import 'tesseract_bindings.dart' if (dart.library.io) 'tesseract_bindings_stub.dart';

class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._();
  OCRService._();

  TextRecognizer? _textRecognizer;
  BarcodeScanner? _barcodeScanner;
  TesseractWorker? _tesseractWorker;

  /// Initialize the OCR service
  Future<void> initialize() async {
    DebugLogger().log('🔧 OCR Service: Initializing...');
    
    if (kIsWeb) {
      // Initialize Tesseract.js for web
      DebugLogger().log('🌐 OCR: Initializing Tesseract.js for web platform');
      try {
        _tesseractWorker = createWorker(null);
        await promiseToFuture(_tesseractWorker!.load());
        await promiseToFuture(_tesseractWorker!.loadLanguage('eng'));
        await promiseToFuture(_tesseractWorker!.initialize('eng'));
        DebugLogger().log('✅ OCR: Tesseract.js initialized successfully');
      } catch (e) {
        DebugLogger().log('❌ OCR: Failed to initialize Tesseract.js: $e');
        _tesseractWorker = null;
      }
    } else {
      // Initialize Google ML Kit for mobile
      DebugLogger().log('📱 OCR: Initializing Google ML Kit for mobile platform');
      try {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        _barcodeScanner = BarcodeScanner();
        DebugLogger().log('✅ OCR: Google ML Kit initialized successfully');
      } catch (e) {
        DebugLogger().log('❌ OCR: Failed to initialize Google ML Kit: $e');
      }
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

      if (kIsWeb) {
        await _processImageWeb(scannedContent, imagePath);
      } else {
        await _processImageMobile(scannedContent, imagePath);
      }
      
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
        engine: kIsWeb ? 'tesseract_js_error' : 'ml_kit_error',
        overallConfidence: 0.0,
        detectedLanguages: [],
        processingTime: stopwatch.elapsed,
        additionalData: {'error': e.toString()},
      );
      return scannedContent;
    }
  }

  /// Web implementation using Tesseract.js
  Future<void> _processImageWeb(ScannedContent scannedContent, String imagePath) async {
    DebugLogger().log('🌐 OCR: Processing image with Tesseract.js');
    
    if (_tesseractWorker == null) {
      throw Exception('Tesseract.js not initialized. Call initialize() first.');
    }

    try {
      // Use the captured image from WebCameraService
      final webService = WebCameraService.instance;
      final imageData = webService.getLastCapturedImageData();
      
      if (imageData == null) {
        throw Exception('No image data available for OCR processing');
      }

      DebugLogger().log('📤 OCR: Sending image to Tesseract.js engine');
      
      // Perform OCR with Tesseract.js
      final result = await promiseToFuture<TesseractResult>(
        _tesseractWorker!.recognize(imageData, 'eng')
      );
      
      final data = result.data;
      scannedContent.rawText = data.text.trim();
      
      DebugLogger().log('📥 OCR: Received result from Tesseract.js');
      DebugLogger().log('🎯 OCR: Confidence: ${(data.confidence * 100).toStringAsFixed(1)}%');
      
      // Extract additional data
      _extractTablesFromTesseractData(scannedContent, data);
      _extractDiagramsFromText(scannedContent);
      
      // Set metadata
      scannedContent.ocrMetadata = OCRMetadata(
        engine: 'tesseract_js',
        overallConfidence: data.confidence,
        detectedLanguages: ['en'],
        processingTime: Duration.zero, // Will be set by caller
        additionalData: {
          'words_count': data.words?.length ?? 0,
          'lines_count': data.lines?.length ?? 0,
          'paragraphs_count': data.paragraphs?.length ?? 0,
          'web_processing': true,
        },
      );
      
    } catch (e) {
      DebugLogger().log('❌ OCR: Tesseract.js processing error: $e');
      rethrow;
    }
  }

  /// Mobile implementation using Google ML Kit
  Future<void> _processImageMobile(ScannedContent scannedContent, String imagePath) async {
    DebugLogger().log('📱 OCR: Processing image with Google ML Kit');
    
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
          'mobile_processing': true,
        },
      );
      
    } catch (e) {
      DebugLogger().log('❌ OCR: ML Kit processing error: $e');
      rethrow;
    }
  }

  /// Extract tables from Tesseract.js data
  void _extractTablesFromTesseractData(ScannedContent scannedContent, TesseractData data) {
    // Basic table extraction logic based on text layout
    if (data.lines != null) {
      final tableRows = <List<String>>[];
      for (final line in data.lines!) {
        // Look for lines that might be table rows (contain multiple columns)
        final text = line.text.trim();
        if (text.contains('|') || text.contains('\t')) {
          final columns = text.split(RegExp(r'[|\t]')).map((e) => e.trim()).toList();
          if (columns.length > 1) {
            tableRows.add(columns);
          }
        }
      }
      
      if (tableRows.isNotEmpty) {
        scannedContent.tables.add(
          TableData(
            rows: tableRows,
            confidence: data.confidence,
          ),
        );
      }
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
    if (kIsWeb) {
      if (_tesseractWorker != null) {
        await promiseToFuture(_tesseractWorker!.terminate());
        _tesseractWorker = null;
      }
    } else {
      await _textRecognizer?.close();
      await _barcodeScanner?.close();
      _textRecognizer = null;
      _barcodeScanner = null;
    }
  }
}
