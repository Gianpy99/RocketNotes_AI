import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Debug screen per testare camera step by step
class CameraDebugScreen extends ConsumerStatefulWidget {
  const CameraDebugScreen({super.key});

  @override
  ConsumerState<CameraDebugScreen> createState() => _CameraDebugScreenState();
}

class _CameraDebugScreenState extends ConsumerState<CameraDebugScreen> {
  String _debugLog = '';
  String? _imagePath;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  void _addLog(String message) {
    setState(() {
      _debugLog += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    debugPrint('🔧 CAMERA_DEBUG: $message');
  }

  @override
  void initState() {
    super.initState();
    _addLog('Screen inizializzato');
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    _addLog('Controllo permessi...');
    
    final cameraStatus = await Permission.camera.status;
    _addLog('Stato camera: ${cameraStatus.name}');
    
    final photosStatus = await Permission.photos.status;
    _addLog('Stato photos: ${photosStatus.name}');
    
    final storageStatus = await Permission.storage.status;
    _addLog('Stato storage: ${storageStatus.name}');
  }

  Future<void> _requestCameraPermission() async {
    _addLog('Richiedendo permesso camera...');
    
    final result = await Permission.camera.request();
    _addLog('Risultato richiesta camera: ${result.name}');
    
    if (result.isGranted) {
      _addLog('✅ Permesso camera concesso');
    } else if (result.isDenied) {
      _addLog('❌ Permesso camera negato');
    } else if (result.isPermanentlyDenied) {
      _addLog('❌ Permesso camera negato permanentemente');
    }
  }

  Future<void> _testImagePicker() async {
    setState(() => _isProcessing = true);
    _addLog('Avvio ImagePicker...');
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        _addLog('✅ Foto scattata: ${photo.path}');
        _addLog('Nome file: ${photo.name}');
        _addLog('Dimensione: ${await photo.length()} bytes');
        
        setState(() {
          _imagePath = photo.path;
        });
      } else {
        _addLog('❌ Nessuna foto scattata (annullato dall\'utente)');
      }
    } catch (e) {
      _addLog('❌ Errore ImagePicker: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _testGalleryPicker() async {
    setState(() => _isProcessing = true);
    _addLog('Avvio Gallery Picker...');
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        _addLog('✅ Immagine selezionata: ${image.path}');
        _addLog('Nome file: ${image.name}');
        _addLog('Dimensione: ${await image.length()} bytes');
        
        setState(() {
          _imagePath = image.path;
        });
      } else {
        _addLog('❌ Nessuna immagine selezionata');
      }
    } catch (e) {
      _addLog('❌ Errore Gallery Picker: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _clearLog() {
    setState(() {
      _debugLog = '';
      _imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Camera Debug'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buttons
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('🔍 Controlla Permessi'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: const Text('🔓 Richiedi Permesso Camera'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isProcessing ? null : _testImagePicker,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _isProcessing 
                  ? const CircularProgressIndicator()
                  : const Text('📷 Test Camera', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isProcessing ? null : _testGalleryPicker,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('📁 Test Galleria', style: TextStyle(color: Colors.white)),
            ),
            
            const SizedBox(height: 16),
            
            // Image preview
            if (_imagePath != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: kIsWeb 
                    ? Image.network(_imagePath!, fit: BoxFit.cover)
                    : Image.file(File(_imagePath!), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                        _addLog('❌ Errore visualizzazione immagine: $error');
                        return const Center(child: Text('Errore caricamento immagine'));
                      }),
              ),
            
            const SizedBox(height: 16),
            
            // Debug log
            const Text(
              'Debug Log:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugLog.isEmpty ? 'Nessun log ancora...' : _debugLog,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
