import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();
  CameraService._();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false; // New flag to track capture state

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  List<CameraDescription>? get cameras => _cameras;

  /// Initialize the camera service
  Future<bool> initialize() async {
    try {
      // Request camera permissions
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission denied');
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras?.isEmpty ?? true) {
        throw Exception('No cameras available');
      }

      // Initialize the camera controller with the first camera (usually back camera)
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.veryHigh, // ✅ INCREASED: High quality for better OCR
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Configure with optimized settings
      await _controller!.initialize();
      
      // Set flash to AUTO for better lighting in low-light conditions
      await _controller!.setFlashMode(FlashMode.auto);
      
      _isInitialized = true;

      return true;
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      return false;
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      final currentCamera = _controller?.description;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera != currentCamera,
        orElse: () => _cameras!.first,
      );

      await _controller?.dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.veryHigh, // ✅ INCREASED: Match main camera resolution
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  /// Capture a photo and return the file path
  Future<String?> capturePhoto() async {
    if (!_isInitialized || _controller == null || _isCapturing) {
      throw Exception('Camera not ready for capture');
    }

    _isCapturing = true;

    try {
      // Check if controller is still valid
      if (!_controller!.value.isInitialized) {
        throw Exception('Camera controller not ready');
      }

      // Create a unique filename
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String scansDir = path.join(appDir.path, 'rocketbook_scans');
      
      // Create scans directory if it doesn't exist
      await Directory(scansDir).create(recursive: true);
      
      final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(scansDir, fileName);

      debugPrint('📸 CameraService: Starting photo capture...');
      
      // Capture the image with timeout
      final XFile image = await _controller!.takePicture();
      
      debugPrint('📸 CameraService: Photo captured, saving to: $filePath');
      
      // STOP CAMERA PREVIEW IMMEDIATELY to prevent buffer overflow
      await _pausePreview();
      
      // Move the image to our scans directory
      final File capturedFile = File(image.path);
      if (!await capturedFile.exists()) {
        throw Exception('Captured image file not found');
      }
      
      final File savedFile = await capturedFile.copy(filePath);
      
      // Clean up temporary file
      try {
        await capturedFile.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete temporary file: $e');
      }

      debugPrint('✅ CameraService: Photo saved successfully: ${savedFile.path}');
      
      // Resume preview after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _resumePreview();
      });
      
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ CameraService: Error capturing photo: $e');
      _isCapturing = false;
      return null;
    }
  }

  /// Pause camera preview to prevent buffer overflow
  Future<void> _pausePreview() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        debugPrint('⏸️ CameraService: Pausing camera preview...');
        await _controller!.pausePreview();
      }
    } catch (e) {
      debugPrint('Warning: Could not pause preview: $e');
    }
  }

  /// Resume camera preview
  Future<void> _resumePreview() async {
    try {
      if (_controller != null && _controller!.value.isInitialized && _isCapturing) {
        debugPrint('▶️ CameraService: Resuming camera preview...');
        await _controller!.resumePreview();
        _isCapturing = false;
      }
    } catch (e) {
      debugPrint('Warning: Could not resume preview: $e');
      _isCapturing = false;
    }
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode flashMode) async {
    if (_controller != null) {
      await _controller!.setFlashMode(flashMode);
    }
  }

  /// Get current flash mode
  FlashMode? get currentFlashMode => _controller?.value.flashMode;

  /// Dispose of the camera controller
  Future<void> dispose() async {
    debugPrint('🔧 CameraService: Disposing camera...');
    _isCapturing = false;
    
    try {
      if (_controller != null) {
        // Stop preview first
        if (_controller!.value.isInitialized) {
          await _controller!.pausePreview();
        }
        // Dispose controller
        await _controller!.dispose();
      }
    } catch (e) {
      debugPrint('Warning: Error during camera disposal: $e');
    } finally {
      _controller = null;
      _isInitialized = false;
      debugPrint('✅ CameraService: Camera disposed successfully');
    }
  }

  /// Force release camera resources
  Future<void> forceRelease() async {
    debugPrint('🔧 CameraService: Force releasing camera resources...');
    _isCapturing = false;
    _isInitialized = false;
    
    try {
      await _controller?.dispose();
    } catch (e) {
      debugPrint('Warning: Error during force release: $e');
    } finally {
      _controller = null;
      debugPrint('✅ CameraService: Camera force released');
    }
  }

  /// Stop camera preview completely
  Future<void> stopPreview() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        debugPrint('🛑 CameraService: Stopping camera preview...');
        await _controller!.pausePreview();
      }
    } catch (e) {
      debugPrint('Warning: Could not stop preview: $e');
    }
  }

  /// Start camera preview
  Future<void> startPreview() async {
    try {
      if (_controller != null && _controller!.value.isInitialized && !_isCapturing) {
        debugPrint('▶️ CameraService: Starting camera preview...');
        await _controller!.resumePreview();
      }
    } catch (e) {
      debugPrint('Warning: Could not start preview: $e');
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasPermission() async {
    final permission = await Permission.camera.status;
    return permission.isGranted;
  }

  /// Request camera permission
  Future<bool> requestPermission() async {
    final permission = await Permission.camera.request();
    return permission.isGranted;
  }

  /// Get zoom level
  Future<double> getMinZoomLevel() async {
    if (_controller != null) {
      return await _controller!.getMinZoomLevel();
    }
    return 1.0;
  }

  Future<double> getMaxZoomLevel() async {
    if (_controller != null) {
      return await _controller!.getMaxZoomLevel();
    }
    return 1.0;
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (_controller != null) {
      final minZoom = await getMinZoomLevel();
      final maxZoom = await getMaxZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    }
  }
}

// Camera state management
class CameraState {
  final bool isInitialized;
  final bool isCapturing;
  final FlashMode flashMode;
  final double zoomLevel;
  final String? error;

  const CameraState({
    this.isInitialized = false,
    this.isCapturing = false,
    this.flashMode = FlashMode.auto,
    this.zoomLevel = 1.0,
    this.error,
  });

  CameraState copyWith({
    bool? isInitialized,
    bool? isCapturing,
    FlashMode? flashMode,
    double? zoomLevel,
    String? error,
  }) {
    return CameraState(
      isInitialized: isInitialized ?? this.isInitialized,
      isCapturing: isCapturing ?? this.isCapturing,
      flashMode: flashMode ?? this.flashMode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      error: error ?? this.error,
    );
  }
}
