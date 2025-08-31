import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'web_camera_service.dart';
import '../../../data/models/note_model.dart';
import '../../../main_simple.dart';
import '../../../screens/ai_analysis_screen.dart';

// Provider per il web camera service
final webCameraServiceProvider = Provider<WebCameraService>((ref) {
  return WebCameraService.instance;
});

// Provider per lo stato della web camera
final webCameraStateProvider = StateNotifierProvider<WebCameraStateNotifier, WebCameraState>((ref) {
  final service = ref.watch(webCameraServiceProvider);
  return WebCameraStateNotifier(service);
});

class WebCameraStateNotifier extends StateNotifier<WebCameraState> {
  final WebCameraService _cameraService;

  WebCameraStateNotifier(this._cameraService) : super(const WebCameraState());

  Future<String?> capturePhoto() async {
    state = state.copyWith(isCapturing: true);
    try {
      final imagePath = await _cameraService.capturePhoto();
      state = state.copyWith(isCapturing: false);
      return imagePath;
    } catch (e) {
      state = state.copyWith(isCapturing: false, error: e.toString());
      return null;
    }
  }

  Future<List<String>> captureMultiplePhotos() async {
    state = state.copyWith(isCapturing: true);
    try {
      final imagePaths = await _cameraService.captureMultiplePhotos();
      state = state.copyWith(isCapturing: false);
      return imagePaths;
    } catch (e) {
      state = state.copyWith(isCapturing: false, error: e.toString());
      return [];
    }
  }
}

class WebRocketbookCameraScreen extends ConsumerWidget {
  const WebRocketbookCameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(webCameraStateProvider);
    final cameraNotifier = ref.read(webCameraStateProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          kIsWeb ? 'Carica Rocketbook' : 'Scansiona Rocketbook',
        ),
        centerTitle: true,
      ),
      body: cameraState.error != null
          ? _buildErrorView(cameraState.error!)
          : _buildMainView(context, cameraNotifier, cameraState),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[300],
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Errore',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(
    BuildContext context,
    WebCameraStateNotifier notifier,
    WebCameraState state,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona principale
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepPurple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                kIsWeb ? Icons.upload_file : Icons.camera_alt,
                size: 60,
                color: Colors.deepPurple[700],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Titolo
            Text(
              kIsWeb 
                ? 'Carica le tue pagine Rocketbook' 
                : 'Scansiona le tue pagine Rocketbook',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Descrizione
            Text(
              kIsWeb
                ? 'Seleziona le immagini delle tue pagine Rocketbook dal computer. Il sistema estrarrà automaticamente il testo e analizzerà il contenuto con AI.'
                : 'Usa la fotocamera per scansionare le tue pagine Rocketbook. Il sistema estrarrà automaticamente il testo e analizzerà il contenuto con AI.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Pulsanti principali
            if (state.isCapturing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Caricamento in corso...'),
                ],
              )
            else ...[
              // Pulsante singola immagine
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _capturePhoto(context, notifier),
                  icon: Icon(kIsWeb ? Icons.photo : Icons.camera_alt),
                  label: Text(
                    kIsWeb ? 'Seleziona Immagine' : 'Scatta Foto',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pulsante multiple immagini
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _captureMultiplePhotos(context, notifier),
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                    kIsWeb ? 'Seleziona Multiple' : 'Scansione Multipla',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: BorderSide(color: Colors.deepPurple, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Suggerimenti',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Assicurati che il testo sia ben visibile\n'
                    '• Usa buona illuminazione\n'
                    '• Inquadra l\'intera pagina\n'
                    '• Evita riflessi e ombre',
                    style: TextStyle(color: Colors.blue[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto(BuildContext context, WebCameraStateNotifier notifier) async {
    final imagePath = await notifier.capturePhoto();
    if (imagePath != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebImagePreviewScreen(
            imagePaths: [imagePath],
            title: 'Anteprima Scansione',
          ),
        ),
      );
    }
  }

  Future<void> _captureMultiplePhotos(BuildContext context, WebCameraStateNotifier notifier) async {
    final imagePaths = await notifier.captureMultiplePhotos();
    if (imagePaths.isNotEmpty && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebImagePreviewScreen(
            imagePaths: imagePaths,
            title: 'Anteprima Scansioni (${imagePaths.length})',
          ),
        ),
      );
    }
  }
}

// Web Image Preview Screen
class WebImagePreviewScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String title;

  const WebImagePreviewScreen({
    super.key,
    required this.imagePaths,
    required this.title,
  });

  @override
  State<WebImagePreviewScreen> createState() => _WebImagePreviewScreenState();
}

class _WebImagePreviewScreenState extends State<WebImagePreviewScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Image display
          Expanded(
            child: PageView.builder(
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: kIsWeb
                      ? _buildWebImage(widget.imagePaths[index])
                      : _buildMobileImage(widget.imagePaths[index]),
                );
              },
            ),
          ),
          
          // Page indicator (if multiple images)
          if (widget.imagePaths.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imagePaths.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.key == currentIndex 
                          ? Colors.white 
                          : Colors.white54,
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Annulla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _saveAsNote(context),
                        icon: const Icon(Icons.note_add),
                        label: const Text('Salva Nota'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _processWithAI(context),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Analizza con AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildWebImage(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Errore nel caricamento immagine',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileImage(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Errore nel caricamento immagine',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _saveAsNote(BuildContext context) async {
    try {
      // Create a new note with the image(s) as attachments
      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      final note = NoteModel(
        id: noteId,
        title: 'Foto ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        content: 'Nota con ${widget.imagePaths.length} immagine/i acquisita/e dalla camera',
        mode: 'personal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['foto', 'camera'],
        attachments: widget.imagePaths,
      );

      // Navigate back to home and show success message
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // For now, just show a success message
      // TODO: Actually save the note - this requires access to the provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto salvata! (${widget.imagePaths.length} immagine/i)'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvare la nota: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processWithAI(BuildContext context) {
    // Navigate to AI Analysis screen with the captured images
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AIAnalysisScreen(preloadedImages: widget.imagePaths),
      ),
    );
  }
}
