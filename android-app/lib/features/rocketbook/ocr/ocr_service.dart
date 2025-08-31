import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import '../models/scanned_content.dart';
import '../camera/web_camera_service.dart';

class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._();
  OCRService._();

  TextRecognizer? _textRecognizer;
  BarcodeScanner? _barcodeScanner;

  /// Initialize the OCR service
  Future<void> initialize() async {
    if (kIsWeb) {
      // Su web, ML Kit non è supportato - usiamo implementazione mock
      _textRecognizer = null;
      _barcodeScanner = null;
      debugPrint('🌐 OCR: Web mode - using mock implementation');
    } else {
      // Su mobile, usiamo Google ML Kit
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _barcodeScanner = BarcodeScanner();
      debugPrint('📱 OCR: Mobile mode - using Google ML Kit');
    }
  }

  /// Process an image and extract all content
  Future<ScannedContent> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create initial scanned content
      final scannedContent = ScannedContent.fromImage(imagePath);
      scannedContent.status = ProcessingStatus.processing;

      if (kIsWeb) {
        // Web implementation - check if it's a web image
        if (imagePath.startsWith('web://')) {
          await _processImageWebWithBytes(scannedContent, imagePath);
        } else {
          await _processImageWeb(scannedContent, imagePath);
        }
      } else {
        // Mobile implementation - Google ML Kit
        await _processImageMobile(scannedContent, imagePath);
      }
      
      stopwatch.stop();
      scannedContent.ocrMetadata.processingTime = stopwatch.elapsed;
      scannedContent.status = ProcessingStatus.completed;
      return scannedContent;
    } catch (e) {
      debugPrint('❌ OCR Error: $e');
      final scannedContent = ScannedContent.fromImage(imagePath);
      scannedContent.status = ProcessingStatus.failed;
      scannedContent.rawText = 'Error processing image: $e';
      return scannedContent;
    }
  }

  /// Process web image with bytes from WebCameraService
  Future<void> _processImageWebWithBytes(ScannedContent scannedContent, String imagePath) async {
    try {
      // Get image bytes from WebCameraService
      final bytes = await WebCameraService.instance.getLastImageBytes();
      
      if (bytes != null) {
        // For now, we'll still use mock OCR but indicate we have the real image
        final fileName = imagePath.replaceFirst('web://', '');
        scannedContent.rawText = '''OCR Processing Complete (Web)
        
Image: $fileName
Size: ${bytes.length} bytes

Sample extracted text (using mock OCR):
• This is sample text from your uploaded image
• Line detection and text extraction would happen here
• In production, this would use a web OCR service

To implement real OCR on web, consider:
1. Tesseract.js for client-side OCR
2. Google Cloud Vision API
3. AWS Textract
4. Azure Computer Vision

Image successfully loaded and ready for processing.
''';

        scannedContent.ocrMetadata = OCRMetadata(
          engine: 'web_with_image',
          overallConfidence: 0.75,
          detectedLanguages: ['en'],
          processingTime: const Duration(milliseconds: 800),
          additionalData: {
            'mode': 'web_real_image',
            'image_path': imagePath,
            'image_size_bytes': bytes.length,
          },
        );
      } else {
        // Fallback to basic mock
        await _processImageWeb(scannedContent, imagePath);
      }
    } catch (e) {
      debugPrint('Error processing web image with bytes: $e');
      // Fallback to basic mock
      await _processImageWeb(scannedContent, imagePath);
    }
  }

  /// Web implementation (mock)
  Future<void> _processImageWeb(ScannedContent scannedContent, String imagePath) async {
    // Simuliamo l'OCR su web con testo di esempio
    scannedContent.rawText = '''Sample OCR Text (Web Mode)
    
This is a demo text extracted from your image.
Since we're running on web, Google ML Kit is not available.

• Line 1: Demo content
• Line 2: More demo content  
• Line 3: Additional information

In a real implementation, you would:
1. Send the image to a cloud OCR service
2. Use a JavaScript OCR library like Tesseract.js
3. Process the image server-side

Image path: $imagePath
''';

    scannedContent.ocrMetadata = OCRMetadata(
      engine: 'web_mock',
      overallConfidence: 0.85,
      detectedLanguages: ['en'],
      processingTime: const Duration(milliseconds: 500),
      additionalData: {
        'mode': 'web_demo',
        'image_path': imagePath,
      },
    );
  }

  /// Mobile implementation (Google ML Kit)
  Future<void> _processImageMobile(ScannedContent scannedContent, String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    
    // Extract text
    final textResult = await _extractText(inputImage);
    scannedContent.rawText = textResult.text;
    
    // Extract tables (basic implementation)
    final tables = await _extractTables(inputImage, textResult);
    scannedContent.tables.addAll(tables);
    
    // Detect any barcodes/QR codes
    final barcodes = await _barcodeScanner?.processImage(inputImage) ?? [];
    
    // Create metadata
    scannedContent.ocrMetadata = OCRMetadata(
      engine: 'ml_kit',
      overallConfidence: _calculateOverallConfidence(textResult),
      detectedLanguages: ['en'], // ML Kit doesn't provide language detection directly
      processingTime: Duration.zero, // Will be set by caller
      additionalData: {
        'barcodes_found': barcodes.length,
        'text_blocks': textResult.blocks.length,
        'image_size': await _getImageSize(imagePath),
      },
    );
  }

  /// Extract text using ML Kit
  Future<RecognizedText> _extractText(InputImage inputImage) async {
    if (_textRecognizer == null) {
      throw Exception('TextRecognizer not initialized - web platform not supported');
    }
    return await _textRecognizer!.processImage(inputImage);
  }

  /// Basic table extraction (enhanced version would use more sophisticated algorithms)
  Future<List<TableData>> _extractTables(InputImage inputImage, RecognizedText textResult) async {
    final tables = <TableData>[];
    
    // Simple table detection based on text block positioning
    final blocks = textResult.blocks;
    
    // Group blocks that might form tables
    final potentialTables = _groupBlocksIntoTables(blocks);
    
    for (final tableBlocks in potentialTables) {
      if (tableBlocks.length >= 4) { // Minimum 2x2 table
        final table = _createTableFromBlocks(tableBlocks);
        if (table != null) {
          tables.add(table);
        }
      }
    }
    
    return tables;
  }

  /// Group text blocks that might form a table structure
  List<List<TextBlock>> _groupBlocksIntoTables(List<TextBlock> blocks) {
    final tables = <List<TextBlock>>[];
    
    // Sort blocks by vertical position
    final sortedBlocks = List<TextBlock>.from(blocks);
    sortedBlocks.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    // Group blocks into rows based on Y position proximity
    final rows = <List<TextBlock>>[];
    List<TextBlock> currentRow = [];
    double lastY = -1;
    
    for (final block in sortedBlocks) {
      final currentY = block.boundingBox.top.toDouble();
      
      // If this block is roughly on the same line as the previous
      if (lastY == -1 || (currentY - lastY).abs() < 20) {
        currentRow.add(block);
      } else {
        // Start a new row
        if (currentRow.isNotEmpty) {
          // Sort current row by X position
          currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          rows.add(List.from(currentRow));
        }
        currentRow = [block];
      }
      lastY = currentY;
    }
    
    // Add the last row
    if (currentRow.isNotEmpty) {
      currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      rows.add(currentRow);
    }
    
    // Look for table patterns
    if (rows.length >= 2) {
      final tableBlocks = <TextBlock>[];
      for (final row in rows) {
        tableBlocks.addAll(row);
      }
      tables.add(tableBlocks);
    }
    
    return tables;
  }

  /// Create a table structure from grouped text blocks
  TableData? _createTableFromBlocks(List<TextBlock> blocks) {
    try {
      // Sort blocks by position to determine table structure
      final sortedByY = List<TextBlock>.from(blocks);
      sortedByY.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
      
      // Group into rows
      final rows = <List<String>>[];
      List<TextBlock> currentRowBlocks = [];
      double lastY = -1;
      
      for (final block in sortedByY) {
        final currentY = block.boundingBox.top.toDouble();
        
        if (lastY == -1 || (currentY - lastY).abs() < 20) {
          currentRowBlocks.add(block);
        } else {
          if (currentRowBlocks.isNotEmpty) {
            // Sort current row by X position and extract text
            currentRowBlocks.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
            final rowTexts = currentRowBlocks.map((b) => b.text.trim()).toList();
            rows.add(rowTexts);
          }
          currentRowBlocks = [block];
        }
        lastY = currentY;
      }
      
      // Add the last row
      if (currentRowBlocks.isNotEmpty) {
        currentRowBlocks.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        final rowTexts = currentRowBlocks.map((b) => b.text.trim()).toList();
        rows.add(rowTexts);
      }
      
      if (rows.isEmpty) return null;
      
      // Create table with headers and data
      final allRows = rows;
      
      return TableData(
        rows: allRows,
        boundingBox: BoundingBox(
          left: 0.0,
          top: 0.0,
          width: 100.0,
          height: 50.0, // Default bounding box for web mock
        ),
        confidence: 0.7, // Basic confidence for table detection
      );
    } catch (e) {
      debugPrint('Error creating table from blocks: $e');
      return null;
    }
  }

  /// Calculate overall confidence from recognized text
  double _calculateOverallConfidence(RecognizedText textResult) {
    if (textResult.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (final block in textResult.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // ML Kit doesn't provide confidence, so we estimate based on text quality
          final text = element.text;
          double confidence = _estimateTextConfidence(text);
          totalConfidence += confidence;
          elementCount++;
        }
      }
    }
    
    return elementCount > 0 ? totalConfidence / elementCount : 0.0;
  }

  /// Estimate text confidence based on text characteristics
  double _estimateTextConfidence(String text) {
    if (text.isEmpty) return 0.0;
    
    // Basic heuristics for text quality
    double confidence = 0.8; // Base confidence
    
    // Penalize very short text
    if (text.length < 3) confidence -= 0.2;
    
    // Penalize text with many special characters
    final specialCharCount = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    final specialCharRatio = specialCharCount / text.length;
    if (specialCharRatio > 0.3) confidence -= 0.3;
    
    // Bonus for common words
    if (RegExp(r'\b(the|and|or|a|an|in|on|at|to|for|of|with|by)\b', caseSensitive: false).hasMatch(text)) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Get image size information
  Future<Map<String, dynamic>> _getImageSize(String imagePath) async {
    try {
      if (kIsWeb) {
        return {'width': 0, 'height': 0, 'note': 'Web mode - size not available'};
      }
      
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        return {
          'width': image.width,
          'height': image.height,
          'channels': image.numChannels,
        };
      }
    } catch (e) {
      debugPrint('Error getting image size: $e');
    }
    
    return {'width': 0, 'height': 0, 'error': 'Could not determine size'};
  }

  /// Clean up resources
  Future<void> dispose() async {
    await _textRecognizer?.close();
    await _barcodeScanner?.close();
  }
}
