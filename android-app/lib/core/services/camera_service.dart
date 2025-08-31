import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'openai_service.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});

class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Scatta una foto dalla camera
  Future<File?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Errore durante la cattura dell\'immagine: $e');
      return null;
    }
  }

  /// Seleziona un'immagine dalla galleria
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Errore durante la selezione dell\'immagine: $e');
      return null;
    }
  }
}

/// Provider per lo stato dell'analisi delle immagini
final imageAnalysisProvider = StateNotifierProvider<ImageAnalysisNotifier, ImageAnalysisState>((ref) {
  return ImageAnalysisNotifier(ref.read(openAIServiceProvider));
});

class ImageAnalysisState {
  final bool isLoading;
  final RocketbookAnalysis? analysis;
  final String? error;
  final File? currentImage;

  const ImageAnalysisState({
    this.isLoading = false,
    this.analysis,
    this.error,
    this.currentImage,
  });

  ImageAnalysisState copyWith({
    bool? isLoading,
    RocketbookAnalysis? analysis,
    String? error,
    File? currentImage,
  }) {
    return ImageAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      analysis: analysis ?? this.analysis,
      error: error ?? this.error,
      currentImage: currentImage ?? this.currentImage,
    );
  }
}

class ImageAnalysisNotifier extends StateNotifier<ImageAnalysisState> {
  final OpenAIService _openAIService;

  ImageAnalysisNotifier(this._openAIService) : super(const ImageAnalysisState());

  /// Analizza un'immagine con OpenAI
  Future<void> analyzeImage(File imageFile) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentImage: imageFile,
    );

    try {
      final analysis = await _openAIService.analyzeRocketbookImage(imageFile);
      state = state.copyWith(
        isLoading: false,
        analysis: analysis,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Reset dello stato
  void reset() {
    state = const ImageAnalysisState();
  }

  /// Scatta una foto e la analizza
  Future<void> captureAndAnalyze(CameraService cameraService) async {
    final imageFile = await cameraService.takePicture();
    if (imageFile != null) {
      await analyzeImage(imageFile);
    } else {
      state = state.copyWith(
        error: 'Errore durante la cattura dell\'immagine',
      );
    }
  }

  /// Seleziona un'immagine dalla galleria e la analizza
  Future<void> pickAndAnalyze(CameraService cameraService) async {
    final imageFile = await cameraService.pickFromGallery();
    if (imageFile != null) {
      await analyzeImage(imageFile);
    } else {
      state = state.copyWith(
        error: 'Errore durante la selezione dell\'immagine',
      );
    }
  }

  /// Analizza un'immagine da path
  Future<void> analyzeImageFromPath(String imagePath) async {
    try {
      // Su web, i blob URL non possono essere verificati con File.exists()
      if (kIsWeb && imagePath.startsWith('blob:')) {
        // Per blob URL su web, skippiamo l'analisi o implementiamo un fallback
        state = state.copyWith(
          error: 'Analisi immagine non supportata per blob URL su web',
        );
        return;
      }
      
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await analyzeImage(imageFile);
      } else {
        state = state.copyWith(
          error: 'File immagine non trovato: $imagePath',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Errore durante l\'analisi dell\'immagine: $e',
      );
    }
  }
}
