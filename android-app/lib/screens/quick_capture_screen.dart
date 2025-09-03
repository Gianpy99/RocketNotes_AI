import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/image_manager.dart';
import '../widgets/ocr_widget.dart';
import '../widgets/rocketbook_analyzer_widget.dart';
import '../data/models/note_model.dart';
import '../main_simple.dart';

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
  String? _extractedText;
  String? _aiAnalysis;

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
              debugPrint('OCR completato: ${result.rawText.length} caratteri');
              setState(() {
                _extractedText = result.rawText;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rocketbook Analyzer Widget
          RocketbookAnalyzerWidget(
            imagePath: _capturedImagePath!,
            onAnalysisGenerated: (request) {
              debugPrint('Analisi generata per template: ${request.template.name}');
              setState(() {
                _aiAnalysis = request.prompt;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Status indicators
          if (_extractedText != null || _aiAnalysis != null)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _extractedText != null && _aiAnalysis != null
                            ? 'OCR e analisi AI completati'
                            : _extractedText != null
                                ? 'Testo estratto dall\'immagine'
                                : 'Analisi AI completata',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _saveToNote,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isProcessing ? 'Salvataggio...' : 'Salva come Nota'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _captureNew,
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

  void _saveToNote() async {
    if (_capturedImagePath == null) {
      _showError('Nessuna immagine catturata');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Genera un titolo basato sul contenuto estratto
      String title = '📷 Nota da immagine';
      if (_extractedText != null && _extractedText!.isNotEmpty) {
        // Usa le prime parole del testo estratto come titolo
        final words = _extractedText!.trim().split(' ');
        if (words.isNotEmpty) {
          title = words.take(5).join(' ');
          if (title.length > 30) {
            title = '${title.substring(0, 27)}...';
          }
        }
      }

      // Costruisci il contenuto della nota
      String content = '';

      // Aggiungi il testo estratto dall'OCR
      if (_extractedText != null && _extractedText!.isNotEmpty) {
        content += '📝 Testo estratto:\n$_extractedText\n\n';
      }

      // Aggiungi l'analisi AI se disponibile
      if (_aiAnalysis != null && _aiAnalysis!.isNotEmpty) {
        content += '🤖 Analisi AI:\n$_aiAnalysis\n\n';
      }

      // Aggiungi un riferimento all'immagine
      content += '🖼️ Immagine allegata: $_capturedImagePath';

      // Crea la nota
      final note = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['quick-capture', 'image', if (_extractedText != null) 'ocr'],
        mode: 'personal', // Default mode
        attachments: [_capturedImagePath!],
        isFavorite: false,
        priority: 0,
      );

      // Salva la nota usando il provider
      final notesNotifier = ref.read(notesProvider.notifier);
      await notesNotifier.addNote(note);

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nota salvata con successo!'),
            backgroundColor: Colors.green,
          ),
        );

        // Torna alla schermata precedente dopo un breve delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Errore nel salvare la nota: $e');
    }
  }

  void _captureNew() {
    setState(() {
      _capturedImagePath = null;
      _isProcessing = false;
      _extractedText = null;
      _aiAnalysis = null;
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
