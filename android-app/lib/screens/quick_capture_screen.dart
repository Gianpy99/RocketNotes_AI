import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/image_manager.dart';
import '../widgets/ocr_widget.dart';
import '../widgets/rocketbook_analyzer_widget.dart';
import '../data/models/note_model.dart';
import '../main_simple.dart';
import 'package:hive/hive.dart';
import '../features/rocketbook/models/scanned_content.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/settings_repository.dart';
import '../features/rocketbook/ai_analysis/ai_service.dart';

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
  ScannedContent? _scanned; // contiene testo OCR e metadata
  AIAnalysis? _ai; // risultato AI
  Duration _aiDuration = Duration.zero;

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
            onOCRComplete: (result) async {
              debugPrint('OCR completato: ${result.rawText.length} caratteri');
              setState(() { _scanned = result; });
              // Auto-run AI se abilitato in impostazioni
              try {
                final settingsRepo = SettingsRepository();
                final settings = await settingsRepo.getSettings();
                if (settings.autoQuickCaptureAI && mounted) {
                  setState(() { _isProcessing = true; });
                  final sw = Stopwatch()..start();
                  final analysis = await AIService.instance.analyzeContent(result);
                  sw.stop();
                  setState(() {
                    _ai = analysis;
                    _aiDuration = sw.elapsed;
                    _isProcessing = false;
                  });
                }
              } catch (e) {
                debugPrint('Auto AI error: $e');
                if (mounted) setState(() { _isProcessing = false; });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rocketbook Analyzer Widget (genera prompt AI opzionale)
          RocketbookAnalyzerWidget(
            imagePath: _capturedImagePath!,
            onAnalysisGenerated: (request) {
              debugPrint('Analisi generata per template: ${request.template.name}');
              setState(() {
                // Se l'utente usa Analyzer, salviamo il prompt nel testo AI
                _ai = AIAnalysis(
                  summary: 'Prompt generato',
                  keyTopics: const [],
                  suggestedTags: const [],
                  suggestedTitle: 'Analisi Rocketbook',
                  contentType: ContentType.mixed,
                  sentiment: 0,
                  actionItems: const [],
                  insights: {'generated_prompt': request.prompt},
                );
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Status indicators
          if ((_scanned?.rawText.isNotEmpty ?? false) || _ai != null)
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
                        (_scanned?.rawText.isNotEmpty ?? false) && _ai != null
                            ? 'OCR e analisi AI completati'
                            : (_scanned?.rawText.isNotEmpty ?? false)
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
      final extracted = _scanned?.rawText ?? '';
      if (extracted.isNotEmpty) {
        // Usa le prime parole del testo estratto come titolo
        final words = extracted.trim().split(' ');
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
      if (extracted.isNotEmpty) {
        content += '📝 Testo estratto:\n$extracted\n\n';
      }

      // Aggiungi l'analisi AI se disponibile
      if (_ai != null) {
        content += '🤖 Analisi AI:\n${_ai!.summary}\n\n';
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
        tags: ['quick-capture', 'image', if (extracted.isNotEmpty) 'ocr'],
        mode: 'personal', // Default mode
        attachments: [_capturedImagePath!],
        isFavorite: false,
        priority: 0,
      );

      // Salva la nota usando il provider
      final notesNotifier = ref.read(notesProvider.notifier);
      await notesNotifier.addNote(note);

      // Salva anche lo scan strutturato per analytics
      try {
        final scan = _scanned ?? ScannedContent.fromImage(_capturedImagePath!);
        if (_scanned == null) {
          scan.rawText = extracted;
          scan.status = extracted.isNotEmpty ? ProcessingStatus.completed : ProcessingStatus.pending;
        }
        if (_ai != null) {
          scan.aiAnalysis = _ai;
          // salviamo la durata AI negli insights
          scan.aiAnalysis!.insights = {
            ...scan.aiAnalysis!.insights,
            'ai_processing_ms': _aiDuration.inMilliseconds,
          };
        }
        final box = Hive.box<ScannedContent>(AppConstants.scansBox);
        await box.put(scan.id, scan);
      } catch (_) {}

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
      _scanned = null;
      _ai = null;
      _aiDuration = Duration.zero;
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
