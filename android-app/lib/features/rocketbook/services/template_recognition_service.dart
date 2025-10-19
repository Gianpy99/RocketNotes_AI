// ==========================================
// lib/features/rocketbook/services/template_recognition_service.dart
// ==========================================

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/rocketbook_template.dart';

/// Service for recognizing Rocketbook Fusion Plus templates using computer vision
class TemplateRecognitionService {
  static final TemplateRecognitionService _instance = TemplateRecognitionService._();
  static TemplateRecognitionService get instance => _instance;
  
  TemplateRecognitionService._();

  /// Recognize template from scanned image
  Future<TemplateRecognitionResult> recognizeTemplate(Uint8List imageBytes) async {
    try {
      debugPrint('[TemplateRecognition] Starting template recognition...');
      
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return TemplateRecognitionResult.error('Failed to decode image');
      }

      debugPrint('[TemplateRecognition] Image decoded: ${image.width}x${image.height}');

      // Extract features for template detection
      final features = await _extractFeatures(image);

      // Classify template based on features
      final template = await _classifyTemplate(features);

      // Detect marked symbols at bottom
      final symbols = await _detectMarkedSymbols(image);

      debugPrint('[TemplateRecognition] Detected template: ${template.displayName}');
      debugPrint('[TemplateRecognition] Marked symbols: ${symbols.map((s) => s.displayName).join(', ')}');

      return TemplateRecognitionResult(
        template: template,
        markedSymbols: symbols,
        confidence: features.confidence,
        features: features,
      );
    } catch (e, stack) {
      debugPrint('[TemplateRecognition] Error: $e');
      debugPrint('[TemplateRecognition] Stack: $stack');
      return TemplateRecognitionResult.error('Recognition failed: $e');
    }
  }

  /// Extract visual features from image
  Future<TemplateFeatures> _extractFeatures(img.Image image) async {
    final features = <String, dynamic>{};
    double confidence = 0.0;

    // Analyze page layout patterns
    final hasHeader = await _detectHeader(image);
    final hasGrid = await _detectGrid(image);
    final hasTable = await _detectTable(image);
    final hasCalendar = await _detectCalendar(image);
    final hasCheckboxes = await _detectCheckboxes(image);
    final hasTimeSlots = await _detectTimeSlots(image);
    final linePattern = await _detectLinePattern(image);

    features['hasHeader'] = hasHeader;
    features['hasGrid'] = hasGrid;
    features['hasTable'] = hasTable;
    features['hasCalendar'] = hasCalendar;
    features['hasCheckboxes'] = hasCheckboxes;
    features['hasTimeSlots'] = hasTimeSlots;
    features['linePattern'] = linePattern;

    // Calculate confidence based on detected features
    if (hasHeader) confidence += 0.2;
    if (hasGrid) confidence += 0.15;
    if (hasTable) confidence += 0.15;
    if (hasCalendar) confidence += 0.2;
    if (hasCheckboxes) confidence += 0.15;
    if (hasTimeSlots) confidence += 0.15;

    return TemplateFeatures(
      data: features,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  /// Classify template based on extracted features
  Future<RocketbookTemplate> _classifyTemplate(TemplateFeatures features) async {
    final data = features.data;

    // Monthly Dashboard: Header + sections + metrics
    if (data['hasHeader'] == true && !data['hasCalendar']) {
      if (data['hasGrid'] || data['hasTable']) {
        return RocketbookTemplate.monthlyDashboard;
      }
    }

    // Calendar patterns
    if (data['hasCalendar'] == true) {
      if (data['hasTimeSlots']) {
        return RocketbookTemplate.weekly;
      }
      return RocketbookTemplate.monthly;
    }

    // Table
    if (data['hasTable'] == true && data['linePattern'] == 'table') {
      return RocketbookTemplate.customTable;
    }

    // Project Management: checkboxes + sections
    if (data['hasCheckboxes'] == true && data['hasHeader']) {
      return RocketbookTemplate.projectManagement;
    }

    // Meeting Notes: header + ruled lines + action items
    if (data['hasHeader'] == true && data['hasCheckboxes']) {
      return RocketbookTemplate.meetingNotes;
    }

    // List Page: checkboxes without complex structure
    if (data['hasCheckboxes'] == true) {
      return RocketbookTemplate.listPage;
    }

    // Line patterns
    switch (data['linePattern']) {
      case 'lined':
        return RocketbookTemplate.lined;
      case 'dotgrid':
        return RocketbookTemplate.dotGrid;
      case 'graph':
        return RocketbookTemplate.graph;
      case 'blank':
        return RocketbookTemplate.blank;
    }

    return RocketbookTemplate.unknown;
  }

  /// Detect marked symbols at bottom of page
  Future<List<RocketbookSymbol>> _detectMarkedSymbols(img.Image image) async {
    final markedSymbols = <RocketbookSymbol>[];

    // Symbol row is typically at bottom 5% of page
    final symbolRowY = (image.height * 0.95).toInt();
    final symbolRowHeight = (image.height * 0.05).toInt();

    // Extract symbol row region
    final symbolRow = img.copyCrop(
      image,
      x: 0,
      y: symbolRowY,
      width: image.width,
      height: symbolRowHeight,
    );

    // Divide into 7 equal sections (one for each symbol)
    final symbolWidth = symbolRow.width ~/ 7;

    for (int i = 0; i < 7; i++) {
      final symbolRegion = img.copyCrop(
        symbolRow,
        x: i * symbolWidth,
        y: 0,
        width: symbolWidth,
        height: symbolRow.height,
      );

      // Check if symbol is marked (has dark ink)
      if (await _isSymbolMarked(symbolRegion)) {
        markedSymbols.add(RocketbookSymbol.values[i]);
      }
    }

    return markedSymbols;
  }

  /// Check if symbol region has been marked with pen
  Future<bool> _isSymbolMarked(img.Image symbolRegion) async {
    int darkPixelCount = 0;
    int totalPixels = symbolRegion.width * symbolRegion.height;

    // Sample pixels to detect marking
    for (int y = 0; y < symbolRegion.height; y += 2) {
      for (int x = 0; x < symbolRegion.width; x += 2) {
        final pixel = symbolRegion.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Calculate brightness
        final brightness = (r + g + b) / 3;
        
        // Dark pixel threshold
        if (brightness < 150) {
          darkPixelCount++;
        }
      }
    }

    // If more than 15% of pixels are dark, consider it marked
    final darkRatio = darkPixelCount / (totalPixels / 4); // /4 because we sample every 2 pixels
    return darkRatio > 0.15;
  }

  // Feature detection methods

  Future<bool> _detectHeader(img.Image image) async {
    // Check top 10% of page for header patterns
    final headerHeight = (image.height * 0.1).toInt();
    final headerRegion = img.copyCrop(image, x: 0, y: 0, width: image.width, height: headerHeight);
    
    // Detect horizontal lines or text patterns
    return await _hasHorizontalLines(headerRegion);
  }

  Future<bool> _detectGrid(img.Image image) async {
    // Detect regular grid patterns (dots or lines)
    return await _hasRegularPattern(image, patternType: 'grid');
  }

  Future<bool> _detectTable(img.Image image) async {
    // Detect table structure with rows and columns
    final hasVerticalLines = await _hasVerticalLines(image);
    final hasHorizontalLines = await _hasHorizontalLines(image);
    return hasVerticalLines && hasHorizontalLines;
  }

  Future<bool> _detectCalendar(img.Image image) async {
    // Detect calendar grid (7 columns for days)
    final hasGrid = await _detectGrid(image);
    if (!hasGrid) return false;
    
    // Check for 7-column pattern (week days)
    return await _hasSevenColumnPattern(image);
  }

  Future<bool> _detectCheckboxes(img.Image image) async {
    // Detect square checkbox patterns
    return await _hasSquarePatterns(image);
  }

  Future<bool> _detectTimeSlots(img.Image image) async {
    // Detect time slot patterns (left column with times)
    return await _hasLeftColumnTimePattern(image);
  }

  Future<String> _detectLinePattern(img.Image image) async {
    final hasDots = await _hasDotPattern(image);
    if (hasDots) return 'dotgrid';
    
    final hasLines = await _hasHorizontalLines(image);
    if (hasLines) return 'lined';
    
    final hasGraph = await _hasGraphPattern(image);
    if (hasGraph) return 'graph';
    
    return 'blank';
  }

  // Low-level pattern detection helpers
  
  Future<bool> _hasHorizontalLines(img.Image image) async {
    // Simple edge detection for horizontal lines
    int horizontalEdges = 0;
    for (int y = 0; y < image.height - 1; y += 5) {
      int edgeStrength = 0;
      for (int x = 0; x < image.width; x += 5) {
        final pixel1 = image.getPixel(x, y);
        final pixel2 = image.getPixel(x, y + 1);
        final diff = ((pixel1.r - pixel2.r).abs() + 
                     (pixel1.g - pixel2.g).abs() + 
                     (pixel1.b - pixel2.b).abs()) / 3;
        if (diff > 50) edgeStrength++;
      }
      if (edgeStrength > image.width / 10) horizontalEdges++;
    }
    return horizontalEdges > 5;
  }

  Future<bool> _hasVerticalLines(img.Image image) async {
    int verticalEdges = 0;
    for (int x = 0; x < image.width - 1; x += 5) {
      int edgeStrength = 0;
      for (int y = 0; y < image.height; y += 5) {
        final pixel1 = image.getPixel(x, y);
        final pixel2 = image.getPixel(x + 1, y);
        final diff = ((pixel1.r - pixel2.r).abs() + 
                     (pixel1.g - pixel2.g).abs() + 
                     (pixel1.b - pixel2.b).abs()) / 3;
        if (diff > 50) edgeStrength++;
      }
      if (edgeStrength > image.height / 10) verticalEdges++;
    }
    return verticalEdges > 3;
  }

  Future<bool> _hasRegularPattern(img.Image image, {required String patternType}) async {
    // Detect regular spacing patterns
    return false; // Simplified for now
  }

  Future<bool> _hasSevenColumnPattern(img.Image image) async {
    // Detect 7-column grid for calendar
    return false; // Simplified for now
  }

  Future<bool> _hasSquarePatterns(img.Image image) async {
    // Detect checkbox squares
    return false; // Simplified for now
  }

  Future<bool> _hasLeftColumnTimePattern(img.Image image) async {
    // Detect time column on left
    return false; // Simplified for now
  }

  Future<bool> _hasDotPattern(img.Image image) async {
    // Detect dot grid pattern
    return false; // Simplified for now
  }

  Future<bool> _hasGraphPattern(img.Image image) async {
    // Detect graph paper grid
    return false; // Simplified for now
  }
}

/// Result of template recognition
class TemplateRecognitionResult {
  final RocketbookTemplate template;
  final List<RocketbookSymbol> markedSymbols;
  final double confidence;
  final TemplateFeatures? features;
  final String? error;

  TemplateRecognitionResult({
    required this.template,
    this.markedSymbols = const [],
    this.confidence = 0.0,
    this.features,
    this.error,
  });

  factory TemplateRecognitionResult.error(String message) {
    return TemplateRecognitionResult(
      template: RocketbookTemplate.unknown,
      confidence: 0.0,
      error: message,
    );
  }

  bool get isSuccess => error == null;
  bool get hasMarkedSymbols => markedSymbols.isNotEmpty;
}

/// Features extracted from template
class TemplateFeatures {
  final Map<String, dynamic> data;
  final double confidence;

  TemplateFeatures({
    required this.data,
    required this.confidence,
  });
}
