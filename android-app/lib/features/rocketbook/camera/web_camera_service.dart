import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/services/storage_manager.dart';

// Modello per gestire immagini web e mobile
class CapturedImage {
  final String? path;        // Path per mobile
  final Uint8List? bytes;    // Bytes per web
  final String? name;        // Nome del file

  CapturedImage({this.path, this.bytes, this.name});

  bool get isWeb => bytes != null;
  bool get isMobile => path != null;
}

class WebCameraService {
  static WebCameraService? _instance;
  static WebCameraService get instance => _instance ??= WebCameraService._();
  WebCameraService._();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera (mobile) or file picker (web)
  Future<String?> capturePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      if (kIsWeb) {
        // For web, we'll handle this differently in the UI
        // Return a special identifier that indicates it's a web file
        return 'web://${image.name}';
      } else {
        // For mobile, copy to app directory and cleanup old files
        await StorageManager.cleanOldImages(); // Pulisci file vecchi
        
        final Directory scansDir = await StorageManager.getScansDirectory();
        
        final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = path.join(scansDir.path, fileName);

        final File savedFile = await File(image.path).copy(filePath);
        print('📱 CAMERA: Immagine salvata in ${savedFile.path}');
        
        return savedFile.path;
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  // Nuovo metodo per ottenere i bytes dell'ultima immagine selezionata
  XFile? _lastSelectedImage;

  /// Metodo interno per salvare l'ultima immagine selezionata
  Future<String?> capturePhotoWithData() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;
      
      _lastSelectedImage = image; // Salva per uso successivo

      if (kIsWeb) {
        return 'web://${image.name}';
      } else {
        // For mobile, copy to app directory and cleanup old files
        await StorageManager.cleanOldImages();
        
        final Directory scansDir = await StorageManager.getScansDirectory();
        
        final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = path.join(scansDir.path, fileName);

        final File savedFile = await File(image.path).copy(filePath);
        print('📱 CAMERA: Immagine salvata in ${savedFile.path}');
        
        return savedFile.path;
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Ottieni i bytes dell'ultima immagine selezionata (solo per web)
  Future<Uint8List?> getLastImageBytes() async {
    if (_lastSelectedImage != null && kIsWeb) {
      return await _lastSelectedImage!.readAsBytes();
    }
    return null;
  }

  /// Pick multiple images
  Future<List<String>> captureMultiplePhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      final List<String> paths = [];
      
      for (final image in images) {
        if (kIsWeb) {
          paths.add(image.path);
        } else {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String scansDir = path.join(appDir.path, 'rocketbook_scans');
          
          await Directory(scansDir).create(recursive: true);
          
          final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}_${paths.length}.jpg';
          final String filePath = path.join(scansDir, fileName);

          final File savedFile = await File(image.path).copy(filePath);
          paths.add(savedFile.path);
        }
      }

      return paths;
    } catch (e) {
      debugPrint('Error capturing multiple photos: $e');
      return [];
    }
  }
}

// State management for web camera
class WebCameraState {
  final bool isCapturing;
  final String? error;

  const WebCameraState({
    this.isCapturing = false,
    this.error,
  });

  WebCameraState copyWith({
    bool? isCapturing,
    String? error,
  }) {
    return WebCameraState(
      isCapturing: isCapturing ?? this.isCapturing,
      error: error ?? this.error,
    );
  }
}
