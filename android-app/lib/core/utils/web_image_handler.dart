// ==========================================
// lib/core/utils/web_image_handler.dart
// ==========================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// Handler per gestire le immagini su Flutter Web
class WebImageHandler {
  /// Converte una stringa base64 in Uint8List per visualizzazione
  static Uint8List? base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Errore nella conversione base64 to bytes: $e');
      return null;
    }
  }

  /// Verifica se una stringa è un base64 valido
  static bool _isBase64String(String str) {
    try {
      // Un base64 valido dovrebbe essere divisibile per 4 e contenere solo caratteri validi
      if (str.length % 4 != 0) return false;
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crea un placeholder per errori di caricamento immagini
  static Widget _buildErrorPlaceholder(double width, double height, String message) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image, 
            size: width > 100 ? 40 : (width > 50 ? 20 : 12), 
            color: Colors.grey
          ),
          if (width > 60)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: width > 100 ? 12 : (width > 80 ? 10 : 8), 
                  color: Colors.grey
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Crea un widget immagine compatibile con web
  static Widget createWebCompatibleImage(
    String imagePath, {
    double? width, 
    double? height,
    BoxFit fit = BoxFit.contain, // Cambiato da cover a contain per default
  }) {
    final imageWidth = width ?? 150;
    final imageHeight = height ?? 150;
    
    if (kIsWeb) {
      // Su web, verifica il tipo di path/URL
      if (imagePath.startsWith('blob:')) {
        // Blob URL - usa Image.network per blob URLs
        debugPrint('🌐 WEB: Caricamento blob URL: $imagePath');
        return Image.network(
          imagePath,
          width: imageWidth,
          height: imageHeight,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Errore caricamento blob URL: $error');
            return _buildErrorPlaceholder(imageWidth, imageHeight, 'Errore caricamento\nimmagine');
          },
        );
      } 
      
      if (imagePath.startsWith('/') || imagePath.startsWith('file://') || imagePath.contains('C:') || imagePath.contains('storage')) {
        // Path locale non accessibile su web - mostra placeholder
        debugPrint('🚫 WEB: Path locale non supportato: $imagePath');
        return _buildErrorPlaceholder(imageWidth, imageHeight, 'Immagine non\ndisponibile su Web');
      }
      
      if (imagePath.contains('base64,')) {
        // URL data con base64
        debugPrint('📄 WEB: Data URL base64: ${imagePath.substring(0, 50)}...');
        return Image.network(
          imagePath,
          width: imageWidth,
          height: imageHeight,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Errore caricamento data URL: $error');
            return _buildErrorPlaceholder(imageWidth, imageHeight, 'Errore formato\nbase64');
          },
        );
      }
      
      // Verifica se è una stringa base64 pura (senza prefisso data:)
      if (_isBase64String(imagePath)) {
        debugPrint('🔤 WEB: Base64 puro rilevato');
        try {
          final bytes = base64ToBytes(imagePath);
          if (bytes != null) {
            return Image.memory(
              bytes,
              width: imageWidth,
              height: imageHeight,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Errore rendering base64: $error');
                return _buildErrorPlaceholder(imageWidth, imageHeight, 'Errore rendering\nbase64');
              },
            );
          }
        } catch (e) {
          debugPrint('❌ Errore nel parsing dell\'immagine base64: $e');
        }
      }
      
      // Se arriviamo qui, il formato non è riconosciuto
      debugPrint('🤷 WEB: Formato immagine non riconosciuto: ${imagePath.substring(0, 50)}...');
      return _buildErrorPlaceholder(imageWidth, imageHeight, 'Formato immagine\nnon supportato');
    } else {
      // Su mobile, usa Image.file normalmente
      return Image.file(
        File(imagePath),
        width: imageWidth,
        height: imageHeight,
        fit: fit,
      );
    }
  }
}
