// ==========================================
// lib/features/rocketbook/processing/page_detector.dart
// Page Detection & Corner Finding for Rocketbook
// ==========================================

import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Represents a detected page with its corner points
class DetectedPage {
  final List<Point> corners; // Top-left, top-right, bottom-right, bottom-left
  final double confidence;
  final img.Image? croppedImage;
  final bool isRocketbookPage;

  DetectedPage({
    required this.corners,
    required this.confidence,
    this.croppedImage,
    this.isRocketbookPage = false,
  });

  bool get isValid => corners.length == 4 && confidence > 0.5;
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);

  double distanceTo(Point other) {
    return math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
  }

  @override
  String toString() => 'Point($x, $y)';
}

/// Advanced page detection using edge detection and contour analysis
class PageDetector {
  
  /// Main detection method
  static Future<DetectedPage?> detectPage(img.Image image, {
    bool detectRocketbookMarkers = true,
  }) async {
    print('[PageDetector] Starting page detection...');
    print('[PageDetector] Image size: ${image.width}x${image.height}');

    try {
      // Step 1: Preprocessing
      final preprocessed = _preprocessImage(image);
      
      // Step 2: Edge detection
      final edges = _detectEdges(preprocessed);
      
      // Step 3: Find contours
      final contours = _findContours(edges);
      
      // Step 4: Find largest quadrilateral
      final corners = _findLargestQuad(contours, image.width, image.height);
      
      if (corners == null || corners.length != 4) {
        print('[PageDetector] ❌ No valid quadrilateral found');
        return null;
      }

      // Step 5: Calculate confidence based on shape
      final confidence = _calculateConfidence(corners, image.width, image.height);
      
      print('[PageDetector] ✅ Page detected with confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      
      // Step 6: Apply perspective correction
      final corrected = await _applyPerspectiveCorrection(image, corners);
      
      // Step 7: Detect Rocketbook markers (QR codes in corners)
      bool isRocketbook = false;
      if (detectRocketbookMarkers && corrected != null) {
        isRocketbook = _detectRocketbookMarkers(corrected);
      }

      return DetectedPage(
        corners: corners,
        confidence: confidence,
        croppedImage: corrected,
        isRocketbookPage: isRocketbook,
      );
    } catch (e) {
      print('[PageDetector] ❌ Detection error: $e');
      return null;
    }
  }

  /// Preprocess image: grayscale, blur, contrast
  static img.Image _preprocessImage(img.Image image) {
    print('[PageDetector] Preprocessing image...');
    
    // Convert to grayscale
    var gray = img.grayscale(image);
    
    // Apply MILD Gaussian blur to reduce noise (REDUCED from 2 to 1)
    gray = img.gaussianBlur(gray, radius: 1);
    
    // Increase contrast SLIGHTLY (REDUCED from 1.3 to 1.15)
    gray = img.adjustColor(gray, contrast: 1.15, brightness: 1.05);
    
    return gray;
  }

  /// Canny edge detection (simplified)
  static img.Image _detectEdges(img.Image image) {
    print('[PageDetector] Detecting edges...');
    
    // Sobel edge detection
    final sobelX = img.Image(width: image.width, height: image.height);
    
    // Sobel kernels
    final kernelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    
    final kernelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];
    
    // Apply Sobel operator
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double gx = 0;
        double gy = 0;
        
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final intensity = pixel.r; // Already grayscale
            
            gx += intensity * kernelX[ky + 1][kx + 1];
            gy += intensity * kernelY[ky + 1][kx + 1];
          }
        }
        
        final magnitude = math.sqrt(gx * gx + gy * gy).clamp(0, 255).toInt();
        
        // Threshold to create binary edge map (LOWERED from 50 to 35 for better detection)
        final edgeValue = magnitude > 35 ? 255 : 0;
        final color = img.ColorRgb8(edgeValue, edgeValue, edgeValue);
        sobelX.setPixel(x, y, color);
      }
    }
    
    return sobelX;
  }

  /// Find contours in edge image
  static List<List<Point>> _findContours(img.Image edges) {
    print('[PageDetector] Finding contours...');
    
    final contours = <List<Point>>[];
    final visited = List.generate(
      edges.height,
      (_) => List.filled(edges.width, false),
    );
    
    // Simple contour tracing (flood fill based)
    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        final pixel = edges.getPixel(x, y);
        if (pixel.r > 128 && !visited[y][x]) {
          final contour = _traceContour(edges, x, y, visited);
          if (contour.length > 50) { // Minimum contour size
            contours.add(contour);
          }
        }
      }
    }
    
    print('[PageDetector] Found ${contours.length} contours');
    return contours;
  }

  /// Trace a single contour
  static List<Point> _traceContour(
    img.Image edges,
    int startX,
    int startY,
    List<List<bool>> visited,
  ) {
    final contour = <Point>[];
    final stack = <Point>[Point(startX.toDouble(), startY.toDouble())];
    
    while (stack.isNotEmpty && contour.length < 10000) {
      final point = stack.removeLast();
      final x = point.x.toInt();
      final y = point.y.toInt();
      
      if (x < 0 || x >= edges.width || y < 0 || y >= edges.height) continue;
      if (visited[y][x]) continue;
      
      final pixel = edges.getPixel(x, y);
      if (pixel.r < 128) continue;
      
      visited[y][x] = true;
      contour.add(point);
      
      // Add 8-connected neighbors
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          stack.add(Point((x + dx).toDouble(), (y + dy).toDouble()));
        }
      }
    }
    
    return contour;
  }

  /// Find largest quadrilateral (approximated polygon)
  static List<Point>? _findLargestQuad(
    List<List<Point>> contours,
    int imageWidth,
    int imageHeight,
  ) {
    print('[PageDetector] Finding largest quadrilateral...');
    
    if (contours.isEmpty) return null;
    
    // Sort contours by size
    contours.sort((a, b) => b.length.compareTo(a.length));
    
    // Try to approximate largest contours as quadrilaterals
    for (final contour in contours.take(5)) {
      final approx = _approximatePolygon(contour, epsilon: 0.02);
      
      if (approx.length == 4) {
        // Order corners: TL, TR, BR, BL
        final ordered = _orderCorners(approx);
        
        // Validate that it's a reasonable quadrilateral
        if (_isValidQuad(ordered, imageWidth, imageHeight)) {
          print('[PageDetector] ✅ Valid quad found with ${contour.length} points');
          return ordered;
        }
      }
    }
    
    print('[PageDetector] ⚠️ No valid quad found, using image bounds');
    // Fallback: use entire image
    return [
      Point(0, 0),
      Point(imageWidth.toDouble(), 0),
      Point(imageWidth.toDouble(), imageHeight.toDouble()),
      Point(0, imageHeight.toDouble()),
    ];
  }

  /// Douglas-Peucker algorithm for polygon approximation
  static List<Point> _approximatePolygon(List<Point> points, {required double epsilon}) {
    if (points.length < 3) return points;
    
    // Calculate perimeter
    double perimeter = 0;
    for (int i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      perimeter += points[i].distanceTo(points[next]);
    }
    
    final actualEpsilon = epsilon * perimeter;
    
    return _douglasPeucker(points, actualEpsilon);
  }

  static List<Point> _douglasPeucker(List<Point> points, double epsilon) {
    if (points.length < 3) return points;
    
    // Find point with maximum distance from line between first and last
    double maxDist = 0;
    int maxIndex = 0;
    
    for (int i = 1; i < points.length - 1; i++) {
      final dist = _perpendicularDistance(
        points[i],
        points.first,
        points.last,
      );
      if (dist > maxDist) {
        maxDist = dist;
        maxIndex = i;
      }
    }
    
    if (maxDist > epsilon) {
      // Recursive split
      final left = _douglasPeucker(
        points.sublist(0, maxIndex + 1),
        epsilon,
      );
      final right = _douglasPeucker(
        points.sublist(maxIndex),
        epsilon,
      );
      
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  static double _perpendicularDistance(Point point, Point lineStart, Point lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;
    
    final norm = math.sqrt(dx * dx + dy * dy);
    if (norm == 0) return point.distanceTo(lineStart);
    
    return ((point.x - lineStart.x) * dy - (point.y - lineStart.y) * dx).abs() / norm;
  }

  /// Order corners: Top-Left, Top-Right, Bottom-Right, Bottom-Left
  static List<Point> _orderCorners(List<Point> corners) {
    if (corners.length != 4) return corners;
    
    // Sort by y-coordinate to separate top and bottom
    final sorted = List<Point>.from(corners)
      ..sort((a, b) => a.y.compareTo(b.y));
    
    // Top two points
    final topPoints = sorted.sublist(0, 2)..sort((a, b) => a.x.compareTo(b.x));
    // Bottom two points
    final bottomPoints = sorted.sublist(2)..sort((a, b) => a.x.compareTo(b.x));
    
    return [
      topPoints[0], // TL
      topPoints[1], // TR
      bottomPoints[1], // BR
      bottomPoints[0], // BL
    ];
  }

  /// Validate quadrilateral shape
  static bool _isValidQuad(List<Point> corners, int width, int height) {
    if (corners.length != 4) return false;
    
    // Check minimum area (RELAXED: 5% instead of 10% for distant/partial pages)
    final area = _calculateArea(corners);
    final minArea = width * height * 0.05;
    
    if (area < minArea) {
      print('[PageDetector] ❌ Quad too small: ${area.toInt()} < ${minArea.toInt()}');
      return false;
    }
    
    // Check aspect ratio (RELAXED: 0.3-3.5 instead of 0.5-2.5 for angled photos)
    final topWidth = corners[0].distanceTo(corners[1]);
    final bottomWidth = corners[3].distanceTo(corners[2]);
    final leftHeight = corners[0].distanceTo(corners[3]);
    final rightHeight = corners[1].distanceTo(corners[2]);
    
    final aspectRatio = math.max(topWidth, bottomWidth) / math.max(leftHeight, rightHeight);
    
    if (aspectRatio < 0.3 || aspectRatio > 3.5) {
      print('[PageDetector] ❌ Bad aspect ratio: ${aspectRatio.toStringAsFixed(2)}');
      return false;
    }
    
    return true;
  }

  static double _calculateArea(List<Point> points) {
    if (points.length < 3) return 0;
    
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].x * points[j].y;
      area -= points[j].x * points[i].y;
    }
    return area.abs() / 2;
  }

  /// Calculate detection confidence
  static double _calculateConfidence(List<Point> corners, int width, int height) {
    if (corners.length != 4) return 0.0;
    
    // Factor 1: Area coverage (larger is better)
    final area = _calculateArea(corners);
    final imageArea = width * height;
    final areaCoverage = (area / imageArea).clamp(0.0, 1.0);
    
    // Factor 2: Shape regularity (closer to rectangle is better)
    final topWidth = corners[0].distanceTo(corners[1]);
    final bottomWidth = corners[3].distanceTo(corners[2]);
    final leftHeight = corners[0].distanceTo(corners[3]);
    final rightHeight = corners[1].distanceTo(corners[2]);
    
    final widthSimilarity = 1.0 - (topWidth - bottomWidth).abs() / math.max(topWidth, bottomWidth);
    final heightSimilarity = 1.0 - (leftHeight - rightHeight).abs() / math.max(leftHeight, rightHeight);
    final regularity = (widthSimilarity + heightSimilarity) / 2;
    
    // Combined confidence
    return (areaCoverage * 0.6 + regularity * 0.4).clamp(0.0, 1.0);
  }

  /// Apply perspective correction to extract page
  static Future<img.Image?> _applyPerspectiveCorrection(
    img.Image image,
    List<Point> corners,
  ) async {
    print('[PageDetector] Applying perspective correction...');
    
    if (corners.length != 4) return null;
    
    // Calculate output dimensions based on corner distances
    final topWidth = corners[0].distanceTo(corners[1]);
    final bottomWidth = corners[3].distanceTo(corners[2]);
    final leftHeight = corners[0].distanceTo(corners[3]);
    final rightHeight = corners[1].distanceTo(corners[2]);
    
    final outputWidth = ((topWidth + bottomWidth) / 2).toInt();
    final outputHeight = ((leftHeight + rightHeight) / 2).toInt();
    
    // Create output image
    final output = img.Image(width: outputWidth, height: outputHeight);
    
    // Perspective transform using bilinear interpolation
    for (int y = 0; y < outputHeight; y++) {
      for (int x = 0; x < outputWidth; x++) {
        // Normalized coordinates [0,1]
        final u = x / outputWidth;
        final v = y / outputHeight;
        
        // Bilinear interpolation in source quadrilateral
        final srcX = _bilinearInterpolate(
          corners[0].x, corners[1].x, corners[2].x, corners[3].x,
          u, v,
        );
        final srcY = _bilinearInterpolate(
          corners[0].y, corners[1].y, corners[2].y, corners[3].y,
          u, v,
        );
        
        // Sample from source image
        if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
          final pixel = image.getPixel(srcX.toInt(), srcY.toInt());
          output.setPixel(x, y, pixel);
        }
      }
    }
    
    print('[PageDetector] ✅ Perspective correction complete: ${outputWidth}x${outputHeight}');
    return output;
  }

  static double _bilinearInterpolate(
    double tl, double tr, double br, double bl,
    double u, double v,
  ) {
    final top = tl * (1 - u) + tr * u;
    final bottom = bl * (1 - u) + br * u;
    return top * (1 - v) + bottom * v;
  }

  /// Detect Rocketbook QR code markers in corners
  static bool _detectRocketbookMarkers(img.Image image) {
    print('[PageDetector] Checking for Rocketbook markers...');
    
    // Check corners for high-frequency patterns (QR codes)
    // INCREASED corner size for better detection (from 1/8 to 1/6)
    final cornerSize = math.min(image.width, image.height) ~/ 6;
    int markersFound = 0;
    
    // Check each corner with MORE tolerance
    final corners = [
      (0, 0), // Top-left
      (image.width - cornerSize, 0), // Top-right
      (image.width - cornerSize, image.height - cornerSize), // Bottom-right
      (0, image.height - cornerSize), // Bottom-left
    ];
    
    for (final (x, y) in corners) {
      if (_hasQRPattern(image, x, y, cornerSize)) {
        markersFound++;
      }
    }
    
    // RELAXED: Accept as Rocketbook with just 1 marker (often only bottom markers visible)
    final isRocketbook = markersFound >= 1;
    print('[PageDetector] ${isRocketbook ? "✅" : "❌"} Rocketbook markers: $markersFound/4');
    
    return isRocketbook;
  }

  /// Simple QR pattern detection (high variance in small region)
  static bool _hasQRPattern(img.Image image, int x, int y, int size) {
    if (x < 0 || y < 0 || x + size > image.width || y + size > image.height) {
      return false;
    }
    
    // Calculate variance in the region
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    
    // INCREASED sampling density - step every 2 pixels instead of every pixel for speed
    final step = math.max(1, size ~/ 20); // Sample more densely
    
    for (int dy = 0; dy < size; dy += step) {
      for (int dx = 0; dx < size; dx += step) {
        final pixel = image.getPixel(x + dx, y + dy);
        final intensity = pixel.r.toDouble();
        sum += intensity;
        sumSq += intensity * intensity;
        count++;
      }
    }
    
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    
    // LOWERED variance threshold (from 5000 to 3000) to catch markers with lower contrast
    // This helps with different lighting conditions and worn markers
    return variance > 3000;
  }
}
