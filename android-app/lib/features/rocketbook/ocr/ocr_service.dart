import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import '../models/scanned_content.dart';

class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._();
  OCRService._();

  late final TextRecognizer _textRecognizer;
  late final BarcodeScanner _barcodeScanner;

  /// Initialize the OCR service
  Future<void> initialize() async {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _barcodeScanner = BarcodeScanner();
  }

  /// Process an image and extract all content
  Future<ScannedContent> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create initial scanned content
      final scannedContent = ScannedContent.fromImage(imagePath);
      scannedContent.status = ProcessingStatus.processing;

      // Process the image
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Extract text
      final textResult = await _extractText(inputImage);
      scannedContent.rawText = textResult.text;
      
      // Extract tables (basic implementation)
      final tables = await _extractTables(inputImage, textResult);
      scannedContent.tables.addAll(tables);
      
      // Detect any barcodes/QR codes
      final barcodes = await _barcodeScanner.processImage(inputImage);
      
      stopwatch.stop();
      
      // Create metadata
      scannedContent.ocrMetadata = OCRMetadata(
        engine: 'ml_kit',
        overallConfidence: _calculateOverallConfidence(textResult),
        detectedLanguages: ['en'], // ML Kit doesn't provide language detection directly
        processingTime: stopwatch.elapsed,
        additionalData: {
          'barcodes_found': barcodes.length,
          'text_blocks': textResult.blocks.length,
          'image_size': await _getImageSize(imagePath),
        },
      );

      scannedContent.status = ProcessingStatus.completed;
      return scannedContent;
      
    } catch (e) {
      debugPrint('OCR processing error: $e');
      final errorContent = ScannedContent.fromImage(imagePath);
      errorContent.status = ProcessingStatus.failed;
      errorContent.ocrMetadata = OCRMetadata(
        engine: 'ml_kit',
        overallConfidence: 0.0,
        detectedLanguages: [],
        processingTime: stopwatch.elapsed,
        additionalData: {'error': e.toString()},
      );
      return errorContent;
    }
  }

  /// Extract text using ML Kit
  Future<RecognizedText> _extractText(InputImage inputImage) async {
    return await _textRecognizer.processImage(inputImage);
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

  /// Group text blocks that might form a table
  List<List<TextBlock>> _groupBlocksIntoTables(List<TextBlock> blocks) {
    final tables = <List<TextBlock>>[];
    
    // Sort blocks by vertical position
    final sortedBlocks = List<TextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    // Group blocks into rows based on Y-coordinate proximity
    final rows = <List<TextBlock>>[];
    List<TextBlock> currentRow = [];
    double lastY = -1;
    
    for (final block in sortedBlocks) {
      final currentY = block.boundingBox.top;
      
      if (lastY == -1 || (currentY - lastY).abs() < 20) {
        // Same row
        currentRow.add(block);
      } else {
        // New row
        if (currentRow.isNotEmpty) {
          currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          rows.add(List.from(currentRow));
        }
        currentRow = [block];
      }
      lastY = currentY;
    }
    
    if (currentRow.isNotEmpty) {
      currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      rows.add(currentRow);
    }
    
    // Check if rows form a table structure
    if (rows.length >= 2) {
      final columnCounts = rows.map((row) => row.length).toSet();
      if (columnCounts.length <= 2) { // Allow some variation in column count
        final allBlocks = rows.expand((row) => row).toList();
        tables.add(allBlocks);
      }
    }
    
    return tables;
  }

  /// Create a TableData object from grouped blocks
  TableData? _createTableFromBlocks(List<TextBlock> blocks) {
    try {
      // Group blocks into rows again for table creation
      final rows = <List<String>>[];
      
      // Sort by Y position to get rows
      final sortedBlocks = List<TextBlock>.from(blocks)
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
      
      List<TextBlock> currentRowBlocks = [];
      double lastY = -1;
      
      for (final block in sortedBlocks) {
        final currentY = block.boundingBox.top;
        
        if (lastY == -1 || (currentY - lastY).abs() < 20) {
          currentRowBlocks.add(block);
        } else {
          if (currentRowBlocks.isNotEmpty) {
            currentRowBlocks.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
            final rowText = currentRowBlocks.map((b) => b.text).toList();
            rows.add(rowText);
          }
          currentRowBlocks = [block];
        }
        lastY = currentY;
      }
      
      if (currentRowBlocks.isNotEmpty) {
        currentRowBlocks.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        final rowText = currentRowBlocks.map((b) => b.text).toList();
        rows.add(rowText);
      }
      
      if (rows.length >= 2) {
        // Calculate bounding box for the entire table
        final leftmost = blocks.map((b) => b.boundingBox.left).reduce((a, b) => a < b ? a : b);
        final rightmost = blocks.map((b) => b.boundingBox.right).reduce((a, b) => a > b ? a : b);
        final topmost = blocks.map((b) => b.boundingBox.top).reduce((a, b) => a < b ? a : b);
        final bottommost = blocks.map((b) => b.boundingBox.bottom).reduce((a, b) => a > b ? a : b);
        
        final boundingBox = BoundingBox(
          left: leftmost,
          top: topmost,
          width: rightmost - leftmost,
          height: bottommost - topmost,
        );
        
        return TableData(
          rows: rows,
          title: null, // Could be detected from context
          boundingBox: boundingBox,
          confidence: 0.8, // Basic confidence score
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating table from blocks: $e');
      return null;
    }
  }

  /// Calculate overall confidence from ML Kit result
  double _calculateOverallConfidence(RecognizedText textResult) {
    if (textResult.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (final block in textResult.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // ML Kit doesn't provide confidence scores directly
          // We'll use a heuristic based on text characteristics
          totalConfidence += _estimateElementConfidence(element.text);
          elementCount++;
        }
      }
    }
    
    return elementCount > 0 ? totalConfidence / elementCount : 0.0;
  }

  /// Estimate confidence based on text characteristics
  double _estimateElementConfidence(String text) {
    if (text.isEmpty) return 0.0;
    
    double confidence = 0.8; // Base confidence
    
    // Boost confidence for longer text
    if (text.length > 5) confidence += 0.1;
    
    // Reduce confidence for very short or single character text
    if (text.length == 1) confidence -= 0.3;
    
    // Boost confidence for common words
    final commonWords = ['the', 'and', 'is', 'in', 'to', 'of', 'a', 'for', 'on', 'with'];
    if (commonWords.contains(text.toLowerCase())) confidence += 0.1;
    
    // Reduce confidence for strings with special characters
    if (text.contains(RegExp(r'[^\w\s]'))) confidence -= 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Get image dimensions
  Future<Map<String, int>> _getImageSize(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      return {
        'width': image?.width ?? 0,
        'height': image?.height ?? 0,
      };
    } catch (e) {
      return {'width': 0, 'height': 0};
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await _textRecognizer.close();
    await _barcodeScanner.close();
  }
}

/// OCR processing result
class OCRResult {
  final String text;
  final List<TableData> tables;
  final List<DiagramData> diagrams;
  final OCRMetadata metadata;
  final bool success;
  final String? error;

  OCRResult({
    required this.text,
    required this.tables,
    required this.diagrams,
    required this.metadata,
    required this.success,
    this.error,
  });

  factory OCRResult.success({
    required String text,
    required List<TableData> tables,
    required List<DiagramData> diagrams,
    required OCRMetadata metadata,
  }) {
    return OCRResult(
      text: text,
      tables: tables,
      diagrams: diagrams,
      metadata: metadata,
      success: true,
    );
  }

  factory OCRResult.failure(String error, OCRMetadata metadata) {
    return OCRResult(
      text: '',
      tables: [],
      diagrams: [],
      metadata: metadata,
      success: false,
      error: error,
    );
  }
}
