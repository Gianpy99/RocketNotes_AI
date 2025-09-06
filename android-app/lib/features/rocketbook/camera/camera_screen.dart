import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:photo_view/photo_view.dart';
import 'camera_service.dart';
import 'web_camera_service.dart';
import '../ocr/ocr_service_real.dart';
import '../models/scanned_content.dart';
import '../../../data/models/note_model.dart';
import '../../../presentation/providers/app_providers_simple.dart';
import '../../../core/debug/debug_logger.dart';
import 'package:uuid/uuid.dart';

// Provider per il camera service (web o mobile)
final cameraServiceProvider = Provider<dynamic>((ref) {
  if (kIsWeb) {
    return WebCameraService.instance;
  } else {
    return CameraService.instance;
  }
});

// Provider per lo stato della camera
final cameraStateProvider = StateNotifierProvider<CameraStateNotifier, CameraState>((ref) {
  final service = ref.watch(cameraServiceProvider);
  return CameraStateNotifier(service);
});

class CameraStateNotifier extends StateNotifier<CameraState> {
  final dynamic _cameraService; // Può essere CameraService o WebCameraService
  bool _isCapturing = false; // Flag to prevent multiple captures

  CameraStateNotifier(this._cameraService) : super(const CameraState()) {
    _initializeCamera(); // Re-enabled with controlled initialization
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('🔧 Camera: Initializing camera service...');
      await _cameraService.initialize();
      state = state.copyWith(isInitialized: true);
      debugPrint('✅ Camera: Initialization successful');
    } catch (e) {
      debugPrint('❌ Camera: Initialization failed - $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> capturePhoto() async {
    if (!state.isInitialized || _isCapturing) return null;

    _isCapturing = true;
    state = state.copyWith(isCapturing: true);
    
    try {
      String? imagePath;
      if (kIsWeb) {
        imagePath = await _cameraService.capturePhotoWithData();
      } else {
        // Add a small delay to ensure camera is ready
        await Future.delayed(const Duration(milliseconds: 100));
        imagePath = await _cameraService.capturePhoto();
      }
      
      state = state.copyWith(isCapturing: false);
      _isCapturing = false;
      return imagePath;
    } catch (e) {
      state = state.copyWith(isCapturing: false, error: e.toString());
      _isCapturing = false;
      return null;
    }
  }

  Future<void> switchCamera() async {
    if (!kIsWeb) {
      await _cameraService.switchCamera();
    }
  }

  Future<void> setFlashMode(FlashMode flashMode) async {
    if (!kIsWeb) {
      await _cameraService.setFlashMode(flashMode);
      state = state.copyWith(flashMode: flashMode);
    }
  }

  Future<void> setZoomLevel(double zoom) async {
    if (!kIsWeb) {
      await _cameraService.setZoomLevel(zoom);
      state = state.copyWith(zoomLevel: zoom);
    }
  }

  @override
  void dispose() {
    debugPrint('🔧 Camera: Disposing camera state notifier...');
    _isCapturing = false;
    if (!kIsWeb) {
      _cameraService.dispose();
    }
    super.dispose();
  }
}

class RocketbookCameraScreen extends ConsumerWidget {
  const RocketbookCameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraStateProvider);
    final cameraNotifier = ref.read(cameraStateProvider.notifier);
    final cameraService = ref.watch(cameraServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan Rocketbook',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _getFlashIcon(cameraState.flashMode),
              color: Colors.white,
            ),
            onPressed: () => _toggleFlash(cameraNotifier, cameraState.flashMode),
          ),
        ],
      ),
      body: cameraState.error != null
          ? _buildErrorView(cameraState.error!)
          : !cameraState.isInitialized
              ? const _LoadingView()
              : _buildCameraView(context, cameraService, cameraNotifier, cameraState),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView(
    BuildContext context,
    dynamic cameraService, // Può essere CameraService o WebCameraService
    CameraStateNotifier notifier,
    CameraState state,
  ) {
    // Per il web, mostra un placeholder invece della camera preview
    if (kIsWeb) {
      return _buildWebCameraView(context, notifier, state);
    }
    
    final controller = cameraService.controller;
    if (controller == null) return const _LoadingView();

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(controller),
        ),

        // Overlay for Rocketbook detection
        Positioned.fill(
          child: CustomPaint(
            painter: RocketbookOverlayPainter(),
          ),
        ),

        // Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControls(context, notifier, state),
        ),

        // Zoom slider
        if (state.isInitialized)
          Positioned(
            right: 16,
            top: 100,
            bottom: 200,
            child: _buildZoomSlider(notifier, state),
          ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    CameraStateNotifier notifier,
    CameraState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            IconButton(
              onPressed: () => _pickFromGallery(context),
              icon: const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 32,
              ),
            ),

            // Capture button
            GestureDetector(
              onTap: state.isCapturing ? null : () => _capturePhoto(context, notifier, state),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: state.isCapturing ? Colors.grey : Colors.transparent,
                ),
                child: state.isCapturing
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),

            // Switch camera button
            IconButton(
              onPressed: () => notifier.switchCamera(),
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomSlider(CameraStateNotifier notifier, CameraState state) {
    return RotatedBox(
      quarterTurns: 3,
      child: Slider(
        value: state.zoomLevel,
        min: 1.0,
        max: 8.0,
        divisions: 28,
        onChanged: (value) => notifier.setZoomLevel(value),
        activeColor: Colors.white,
        inactiveColor: Colors.white38,
      ),
    );
  }

  IconData _getFlashIcon(FlashMode flashMode) {
    switch (flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  void _toggleFlash(CameraStateNotifier notifier, FlashMode currentMode) {
    final nextMode = switch (currentMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      FlashMode.torch => FlashMode.off,
    };
    notifier.setFlashMode(nextMode);
  }

  Future<void> _capturePhoto(BuildContext context, CameraStateNotifier notifier, CameraState currentState) async {
    // Prevent rapid consecutive captures
    if (currentState.isCapturing) {
      debugPrint('🚫 Camera: Capture already in progress, ignoring request');
      return;
    }

    debugPrint('📸 Camera: Starting photo capture...');
    final imagePath = await notifier.capturePhoto();
    
    if (imagePath != null && context.mounted) {
      debugPrint('✅ Camera: Photo captured successfully: $imagePath');
      // Navigate to preview screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imagePath: imagePath),
        ),
      );
    } else {
      debugPrint('❌ Camera: Failed to capture photo');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture photo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pickFromGallery(BuildContext context) {
    // TODO: Implement gallery picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery picker coming soon')),
    );
  }

  Widget _buildWebCameraView(
    BuildContext context,
    CameraStateNotifier notifier,
    CameraState state,
  ) {
    return Stack(
      children: [
        // Placeholder per web
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[800],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  'Web Camera Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Click capture to select an image',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        
        // UI Controls overlay
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                  onPressed: () => _pickFromGallery(context),
                ),
              ),
              
              // Capture button
              GestureDetector(
                onTap: state.isCapturing ? null : () => _capturePhoto(context, notifier, state),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: state.isCapturing ? Colors.grey : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: state.isCapturing 
                    ? const Center(child: CircularProgressIndicator(color: Colors.grey))
                    : const Icon(Icons.camera_alt, color: Colors.black, size: 40),
                ),
              ),
              
              // Settings button placeholder
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.white54,
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Initializing Camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we prepare your camera',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter per l'overlay Rocketbook
class RocketbookOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3);
    
    // Bright corner indicators
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    // Text background
    final textBgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7);

    // Define the capture area
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.85,
      height: size.height * 0.7,
    );

    // Draw semi-transparent overlay everywhere except the capture area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // Draw animated corner brackets
    const cornerLength = 40.0;
    const cornerOffset = 8.0;
    
    // Top-left corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left - cornerOffset, rect.top - cornerOffset, cornerLength, 4),
        const Radius.circular(2),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left - cornerOffset, rect.top - cornerOffset, 4, cornerLength),
        const Radius.circular(2),
      ),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - cornerLength + cornerOffset, rect.top - cornerOffset, cornerLength, 4),
        const Radius.circular(2),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - 4 + cornerOffset, rect.top - cornerOffset, 4, cornerLength),
        const Radius.circular(2),
      ),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left - cornerOffset, rect.bottom - 4 + cornerOffset, cornerLength, 4),
        const Radius.circular(2),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left - cornerOffset, rect.bottom - cornerLength + cornerOffset, 4, cornerLength),
        const Radius.circular(2),
      ),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - cornerLength + cornerOffset, rect.bottom - 4 + cornerOffset, cornerLength, 4),
        const Radius.circular(2),
      ),
      cornerPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - 4 + cornerOffset, rect.bottom - cornerLength + cornerOffset, 4, cornerLength),
        const Radius.circular(2),
      ),
      cornerPaint,
    );

    // Add instruction text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Position your document or notes within the frame',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: size.width * 0.8);
    
    // Draw text background
    final textRect = Rect.fromCenter(
      center: Offset(size.width / 2, rect.bottom + 60),
      width: textPainter.width + 32,
      height: textPainter.height + 16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(textRect, const Radius.circular(8)),
      textBgPaint,
    );
    
    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        rect.bottom + 60 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Image preview screen
class ImagePreviewScreen extends ConsumerWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Preview',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<ImageProvider?>(
              future: _getImageProvider(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'Error loading image',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return PhotoView(
                  imageProvider: snapshot.data!,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with processing options
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Choose Processing Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select how you want to process this image',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  // OCR Option
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () => _processImage(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.text_fields, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'OCR + AI Analysis',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Extract text first, then analyze with AI',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            'Best for handwritten notes & documents',
                            style: TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Direct AI Option
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () => _processImageDirectAI(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.smart_toy, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Direct AI Analysis',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Skip OCR, analyze image directly with AI',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            'Faster processing, good for diagrams & photos',
                            style: TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Retake option
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Retake Photo', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processImage(BuildContext context, WidgetRef ref) async {
    // Show enhanced loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Processing Image...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '1. Extracting text with OCR\n2. Analyzing content with AI\n3. Generating smart notes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This may take 10-30 seconds',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
    );

    try {
      DebugLogger().log('📷 Starting image processing...');
      
      // Initialize and use OCR service
      final ocrService = OCRService.instance;
      await ocrService.initialize();
      DebugLogger().log('📝 OCR Service initialized');
      
      // Process image with OCR
      final scannedContent = await ocrService.processImage(imagePath);
      DebugLogger().log('📝 OCR processing complete. Text length: ${scannedContent.rawText.length}');
      
      if (scannedContent.rawText.isNotEmpty) {
        // Get AI service from provider (already initialized)
        final aiService = ref.read(aiServiceProvider);
        DebugLogger().log('🤖 Using AI Service from provider');
        
        // Analyze with AI
        final aiAnalysis = await aiService.analyzeContent(scannedContent);
        scannedContent.aiAnalysis = aiAnalysis;
        DebugLogger().log('🤖 AI Analysis complete. Title: ${aiAnalysis.suggestedTitle}');
        
        // Navigate to results screen or save as note
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showResultsDialog(context, ref, scannedContent);
        }
      } else {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No text found in image. Please try again with better lighting.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processImageDirectAI(BuildContext context, WidgetRef ref) async {
    // Show enhanced loading dialog for Direct AI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 20),
            Text(
              '🚀 Direct AI Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Analyzing image directly with AI\nSkipping OCR for faster processing',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Usually takes 5-15 seconds',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      ),
    );

    try {
      DebugLogger().log('🤖 Starting Direct AI processing...');
      
      // Create ScannedContent without OCR processing
      final scannedContent = ScannedContent.fromImage(imagePath);
      scannedContent.rawText = '[Image sent directly to AI for analysis]';
      scannedContent.status = ProcessingStatus.completed;
      DebugLogger().log('📷 Scanned content created for direct AI analysis');
      
      // Initialize AI service for direct image analysis
      final aiService = ref.read(aiServiceProvider);
      DebugLogger().log('🤖 Using AI Service from provider for direct analysis');
      
      // Analyze image directly with AI
      final aiAnalysis = await aiService.analyzeContent(scannedContent);
      scannedContent.aiAnalysis = aiAnalysis;
      DebugLogger().log('🤖 Direct AI Analysis complete. Title: ${aiAnalysis.suggestedTitle}');
      
      // Navigate to results screen
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showDirectAIResultsDialog(context, ref, scannedContent);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultsDialog(BuildContext context, WidgetRef ref, ScannedContent scannedContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Text Extracted'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scannedContent.aiAnalysis?.suggestedTitle != null)
                Text(
                  'Title: ${scannedContent.aiAnalysis!.suggestedTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(scannedContent.rawText),
                ),
              ),
              if (scannedContent.aiAnalysis?.summary != null) ...[
                const SizedBox(height: 16),
                const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(scannedContent.aiAnalysis!.summary),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveAsNote(context, ref, scannedContent);
            },
            child: const Text('Save as Note'),
          ),
        ],
      ),
    );
  }

  void _showDirectAIResultsDialog(BuildContext context, WidgetRef ref, ScannedContent scannedContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 AI Analysis Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scannedContent.aiAnalysis?.suggestedTitle != null)
                Text(
                  'Title: ${scannedContent.aiAnalysis!.suggestedTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 8),
              const Text(
                'AI analyzed this image directly (without OCR)',
                style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              if (scannedContent.aiAnalysis?.summary != null) ...[
                const Text('Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(scannedContent.aiAnalysis!.summary),
                  ),
                ),
              ] else ...[
                const Text('No AI analysis available'),
              ],
              if (scannedContent.aiAnalysis != null && 
                  scannedContent.aiAnalysis!.suggestedTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Suggested Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 4,
                  children: scannedContent.aiAnalysis!.suggestedTags
                      .map((tag) => Chip(label: Text(tag), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveAsNote(context, ref, scannedContent);
            },
            child: const Text('Save as Note'),
          ),
        ],
      ),
    );
  }

  void _saveAsNote(BuildContext context, WidgetRef ref, ScannedContent scannedContent) async {
    try {
      DebugLogger().log('🔄 Starting to save note...');
      
      // Create a new note with the extracted content
      const uuid = Uuid();
      
      // For web images, don't include the web:// path in attachments
      List<String> attachments = [];
      if (!kIsWeb || !scannedContent.imagePath.startsWith('web://')) {
        attachments = [scannedContent.imagePath];
      }
      
      DebugLogger().log('📄 Creating note with content: ${scannedContent.rawText.substring(0, scannedContent.rawText.length > 100 ? 100 : scannedContent.rawText.length)}...');
      
      final note = NoteModel(
        id: uuid.v4(),
        title: scannedContent.aiAnalysis?.suggestedTitle ?? 'Scanned Note',
        content: scannedContent.rawText,
        mode: 'personal', // Default mode
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: scannedContent.aiAnalysis?.suggestedTags ?? [],
        aiSummary: scannedContent.aiAnalysis?.summary,
        attachments: attachments,
        isFavorite: false,
        priority: 1, // medium priority
      );

      DebugLogger().log('💾 Attempting to save note with ID: ${note.id}');
      
      // Save the note using the notesProvider
      final notesNotifier = ref.read(notesProvider.notifier);
      await notesNotifier.saveNote(note);
      
      DebugLogger().log('✅ Note saved successfully!');
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      DebugLogger().log('❌ Error saving note: $e');
      DebugLogger().log('Stack trace: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get the appropriate ImageProvider based on platform
  Future<ImageProvider?> _getImageProvider() async {
    if (kIsWeb && imagePath.startsWith('web://')) {
      // For web images, get bytes from WebCameraService
      final webService = WebCameraService.instance;
      final bytes = await webService.getLastImageBytes();
      if (bytes != null) {
        return MemoryImage(bytes);
      }
      return null;
    } else {
      // For mobile images, use FileImage
      return FileImage(File(imagePath));
    }
  }
}
