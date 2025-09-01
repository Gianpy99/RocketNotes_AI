// ==========================================
// lib/core/services/image_manager.dart
// ==========================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gestisce le operazioni sulle immagini per l'app
class ImageManager {
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  
  static final ImagePicker _picker = ImagePicker();
  
  /// Scatta una foto con la camera del dispositivo
  static Future<ImageResult?> takePhoto() async {
    try {
      debugPrint('📸 IMAGE_MANAGER: Avvio camera...');
      
      if (kIsWeb) {
        // Su web, usiamo file picker con preferenza camera
        return await pickImage();
      }
      
      // Controllo permessi camera
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          return ImageResult.error('Permesso camera negato. Abilita i permessi nelle impostazioni.');
        }
      }
      
      if (cameraStatus.isPermanentlyDenied) {
        return ImageResult.error('Permesso camera negato permanentemente. Abilita i permessi nelle impostazioni del dispositivo.');
      }
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        debugPrint('📸 IMAGE_MANAGER: Foto scattata: ${photo.path}');
        
        // Ottieni informazioni file
        final File file = File(photo.path);
        final int fileSize = await file.length();
        final String fileName = photo.name;
        final String extension = photo.path.split('.').last.toLowerCase();
        
        debugPrint('📸 IMAGE_MANAGER: Dimensione: $fileSize bytes');
        
        // Verifica dimensione
        if (fileSize > maxImageSize) {
          debugPrint('❌ IMAGE_MANAGER: Foto troppo grande: $fileSize bytes');
          return ImageResult.error('La foto è troppo grande. Massimo 5MB consentiti.');
        }
        
        // Su mobile, leggi i bytes per compatibilità
        final Uint8List bytes = await file.readAsBytes();
        
        return ImageResult.success(
          path: photo.path,
          name: fileName,
          size: fileSize,
          extension: extension ?? 'jpg',
          bytes: bytes,
        );
      } else {
        debugPrint('👤 IMAGE_MANAGER: Scatto cancellato dall\'utente');
        return null;
      }
    } catch (e) {
      debugPrint('❌ IMAGE_MANAGER: Errore durante scatto: $e');
      return ImageResult.error('Errore durante lo scatto della foto: $e');
    }
  }
  
  /// Seleziona un'immagine dal dispositivo (galleria)
  static Future<ImageResult?> pickImage() async {
    try {
      debugPrint('🖼️ IMAGE_MANAGER: Avvio selezione immagine...');
      
      if (kIsWeb) {
        // Su web usiamo file picker
        return await _pickImageWeb();
      } else {
        // Su mobile usiamo image picker
        return await _pickImageMobile();
      }
    } catch (e) {
      debugPrint('❌ IMAGE_MANAGER: Errore durante selezione: $e');
      return ImageResult.error('Errore durante la selezione dell\'immagine: $e');
    }
  }
  
  /// Selezione immagine su mobile con image_picker
  static Future<ImageResult?> _pickImageMobile() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      debugPrint('📱 IMAGE_MANAGER: Immagine selezionata: ${image.path}');
      
      final File file = File(image.path);
      final int fileSize = await file.length();
      final String fileName = image.name;
      final String extension = image.path.split('.').last.toLowerCase();
      
      // Verifica dimensione
      if (fileSize > maxImageSize) {
        return ImageResult.error('Il file è troppo grande. Massimo 5MB consentiti.');
      }
      
      // Verifica formato
      if (!supportedFormats.contains(extension)) {
        return ImageResult.error('Formato non supportato. Formati consentiti: ${supportedFormats.join(", ")}');
      }
      
      final Uint8List bytes = await file.readAsBytes();
      
      return ImageResult.success(
        path: image.path,
        name: fileName,
        size: fileSize,
        extension: extension,
        bytes: bytes,
      );
    }
    
    return null;
  }
  
  /// Selezione immagine su web con file_picker
  static Future<ImageResult?> _pickImageWeb() async {
    try {
      debugPrint('🖼️ IMAGE_MANAGER: Avvio selezione immagine...');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: supportedFormats,
        withData: kIsWeb, // Su web dobbiamo ottenere i bytes
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        debugPrint('🖼️ IMAGE_MANAGER: File selezionato: ${file.name}');
        debugPrint('🖼️ IMAGE_MANAGER: Dimensione: ${file.size} bytes');
        
        // Verifica dimensione
        if (file.size > maxImageSize) {
          debugPrint('❌ IMAGE_MANAGER: File troppo grande: ${file.size} bytes');
          return ImageResult.error('Il file è troppo grande. Massimo 5MB consentiti.');
        }
        
        // Verifica formato
        String extension = (file.extension?.toLowerCase()) ?? '';
        if (extension.isEmpty || !supportedFormats.contains(extension)) {
          debugPrint('❌ IMAGE_MANAGER: Formato non supportato: $extension');
          return ImageResult.error('Formato non supportato. Formati consentiti: ${supportedFormats.join(", ")}');
        }
        
        String imagePath;
        if (kIsWeb) {
          // Su web, creiamo un blob URL
          if (file.bytes != null) {
            imagePath = _createBlobUrl(file.bytes!, file.name);
            debugPrint('🌐 IMAGE_MANAGER: Creato blob URL: $imagePath');
          } else {
            debugPrint('❌ IMAGE_MANAGER: Nessun dato bytes disponibile');
            return ImageResult.error('Errore nel caricamento dell\'immagine');
          }
        } else {
          // Su mobile, usiamo il path del file
          if (file.path != null) {
            imagePath = file.path!;
            debugPrint('📱 IMAGE_MANAGER: Path file: $imagePath');
          } else {
            debugPrint('❌ IMAGE_MANAGER: Nessun path disponibile');
            return ImageResult.error('Errore nel caricamento dell\'immagine');
          }
        }
        
        return ImageResult.success(
          path: imagePath,
          name: file.name,
          size: file.size,
          extension: extension,
          bytes: file.bytes,
        );
      } else {
        debugPrint('👤 IMAGE_MANAGER: Selezione cancellata dall\'utente');
        return null;
      }
    } catch (e) {
      debugPrint('❌ IMAGE_MANAGER: Errore durante selezione: $e');
      return ImageResult.error('Errore durante la selezione dell\'immagine: $e');
    }
  }
  
  /// Crea un blob URL da bytes (solo web)
  static String _createBlobUrl(Uint8List bytes, String fileName) {
    // Per ora ritorniamo una stringa che può essere gestita dal WebImageHandler
    // In un'implementazione reale, useresti dart:html per creare il blob URL
    final base64String = base64Encode(bytes);
    return 'data:image/${_getMimeType(fileName)};base64,$base64String';
  }
  
  /// Ottiene il tipo MIME dal nome file
  static String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }
  
  /// Converte immagine in base64
  static String? imageToBase64(Uint8List? bytes) {
    if (bytes == null) return null;
    try {
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('❌ IMAGE_MANAGER: Errore conversione base64: $e');
      return null;
    }
  }
  
  /// Converte base64 in bytes
  static Uint8List? base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      // Rimuovi eventuale prefisso data URL
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }
      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint('❌ IMAGE_MANAGER: Errore conversione da base64: $e');
      return null;
    }
  }
  
  /// Ottiene informazioni su un'immagine
  static ImageInfo getImageInfo(String imagePath) {
    if (imagePath.startsWith('blob:')) {
      return ImageInfo(
        type: ImageType.blob,
        source: 'Blob URL temporaneo',
        isWebCompatible: true,
      );
    } else if (imagePath.startsWith('data:image')) {
      return ImageInfo(
        type: ImageType.dataUrl,
        source: 'Data URL Base64',
        isWebCompatible: true,
      );
    } else if (imagePath.contains('base64')) {
      return ImageInfo(
        type: ImageType.base64,
        source: 'Base64 puro',
        isWebCompatible: true,
      );
    } else {
      return ImageInfo(
        type: ImageType.file,
        source: 'File locale',
        isWebCompatible: false,
      );
    }
  }
  
  /// Formatta la dimensione del file
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Risultato dell'operazione di selezione immagine
class ImageResult {
  final bool isSuccess;
  final String? path;
  final String? name;
  final int? size;
  final String? extension;
  final Uint8List? bytes;
  final String? error;
  
  ImageResult._({
    required this.isSuccess,
    this.path,
    this.name,
    this.size,
    this.extension,
    this.bytes,
    this.error,
  });
  
  factory ImageResult.success({
    required String path,
    required String name,
    required int size,
    required String extension,
    Uint8List? bytes,
  }) {
    return ImageResult._(
      isSuccess: true,
      path: path,
      name: name,
      size: size,
      extension: extension,
      bytes: bytes,
    );
  }
  
  factory ImageResult.error(String error) {
    return ImageResult._(
      isSuccess: false,
      error: error,
    );
  }
  
  String get formattedSize => size != null ? ImageManager.formatFileSize(size!) : 'Sconosciuta';
}

/// Informazioni su un'immagine
class ImageInfo {
  final ImageType type;
  final String source;
  final bool isWebCompatible;
  
  ImageInfo({
    required this.type,
    required this.source,
    required this.isWebCompatible,
  });
}

/// Tipo di immagine
enum ImageType {
  file,      // File locale
  blob,      // Blob URL
  dataUrl,   // Data URL con base64
  base64,    // Base64 puro
}
