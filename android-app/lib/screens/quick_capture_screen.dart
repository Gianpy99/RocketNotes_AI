import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/image_manager.dart';
import '../widgets/ocr_widget.dart';
import '../widgets/rocketbook_analyzer_widget.dart';

/// Screen principale per la cattura e analisi delle immagini
class QuickCaptureScreen extends ConsumerStatefulWidget {
  final Function(String)? onImageCaptured;
  
  const QuickCaptureScreen({
    super.key,
    this.onImageCaptured,
  });

  @override
  ConsumerState<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  String? _capturedImagePath;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📷 Quick Capture'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: _capturedImagePath == null 
          ? _buildCaptureInterface()
          : _buildAnalysisInterface(),
    );
  }

  Widget _buildCaptureInterface() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 120,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Cattura la tua pagina Rocketbook',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Scatta una foto della pagina per iniziare l\'analisi OCR e AI',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureFromCamera,
              icon: _isProcessing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isProcessing ? 'Elaborazione...' : '📷 Scatta Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('📁 Scegli dalla Galleria'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Anteprima immagine
          Card(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _capturedImagePath!,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        Text('Errore caricamento immagine'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // OCR Widget
          OCRWidget(
            imagePath: _capturedImagePath!,
            autoExtract: true,
            onOCRComplete: (result) {
              debugPrint('OCR completato: ${result.text.length} caratteri');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rocketbook Analyzer Widget
          RocketbookAnalyzerWidget(
            imagePath: _capturedImagePath!,
            onAnalysisGenerated: (request) {
              debugPrint('Analisi generata per template: ${request.template.name}');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveToNote,
                  icon: const Icon(Icons.save),
                  label: const Text('Salva come Nota'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _captureNew,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nuova Foto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    setState(() => _isProcessing = true);
    
    try {
      // Usa la fotocamera reale del dispositivo
      final result = await ImageManager.takePhoto();
      if (result != null && result.isSuccess) {
        setState(() {
          _capturedImagePath = result.path;
          _isProcessing = false;
        });
        widget.onImageCaptured?.call(result.path!);
      } else {
        setState(() => _isProcessing = false);
        if (result?.error != null) {
          _showError(result!.error!);
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Errore camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await ImageManager.pickImage();
      if (result != null && result.isSuccess) {
        setState(() {
          _capturedImagePath = result.path;
          _isProcessing = false;
        });
        widget.onImageCaptured?.call(result.path!);
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Errore: $e');
    }
  }

  void _saveToNote() {
    // TODO: Implementare salvataggio come nota
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 Funzionalità in sviluppo - Salvataggio note'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _captureNew() {
    setState(() {
      _capturedImagePath = null;
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Istruzioni'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 Per migliori risultati:'),
            SizedBox(height: 8),
            Text('• Assicurati che la pagina sia ben illuminata'),
            Text('• Mantieni il telefono dritto'),
            Text('• Includi tutta la pagina nel frame'),
            Text('• Evita ombre o riflessi'),
            SizedBox(height: 12),
            Text('🤖 L\'AI riconoscerà automaticamente:'),
            SizedBox(height: 8),
            Text('• Tipo di template Rocketbook'),
            Text('• Testo tramite OCR'),
            Text('• Contenuto per ChatGPT'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
