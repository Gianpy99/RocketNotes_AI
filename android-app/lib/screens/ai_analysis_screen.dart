import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/camera_service.dart';
import '../core/services/openai_service.dart';

class AIAnalysisScreen extends ConsumerWidget {
  final List<String>? preloadedImages;
  
  const AIAnalysisScreen({super.key, this.preloadedImages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(imageAnalysisProvider);
    final cameraService = ref.read(cameraServiceProvider);

    // Auto-analizza la prima immagine se fornita
    if (preloadedImages != null && preloadedImages!.isNotEmpty && 
        analysisState.currentImage == null && !analysisState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(imageAnalysisProvider.notifier)
            .analyzeImageFromPath(preloadedImages!.first);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Analisi AI Rocketbook'),
        backgroundColor: Colors.orange,
        actions: [
          if (analysisState.analysis != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveAsNote(context, ref, analysisState.analysis!),
            ),
        ],
      ),
      body: Column(
        children: [
          // Pulsanti di azione
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: analysisState.isLoading ? null : () async {
                      await ref.read(imageAnalysisProvider.notifier)
                          .captureAndAnalyze(cameraService);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scatta Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: analysisState.isLoading ? null : () async {
                      await ref.read(imageAnalysisProvider.notifier)
                          .pickAndAnalyze(cameraService);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galleria'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Configurazione API Key
          if (OpenAIService.isApiKeyMissing())
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'API Key OpenAI Mancante',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Per utilizzare l\'analisi AI, aggiungi la tua API Key OpenAI nel file:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'lib/core/services/openai_service.dart',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sostituisci "YOUR_OPENAI_API_KEY_HERE" con la tua chiave API.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Contenuto principale
          Expanded(
            child: _buildContent(context, analysisState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ImageAnalysisState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Analizzando l\'immagine con AI...'),
            SizedBox(height: 8),
            Text(
              'Questo può richiedere alcuni secondi',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Errore durante l\'analisi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (state.analysis != null) {
      return _buildAnalysisResults(context, state);
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Scatta una foto del tuo Rocketbook',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'L\'AI analizzerà automaticamente il contenuto e estrarrà testo, simboli e azioni',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(BuildContext context, ImageAnalysisState state) {
    final analysis = state.analysis!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine analizzata
          if (state.currentImage != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(state.currentImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          const SizedBox(height: 16),

          // Titolo
          _buildSection(
            'Titolo',
            analysis.title,
            Icons.title,
            Colors.blue,
          ),

          // Contenuto principale
          _buildSection(
            'Contenuto',
            analysis.content,
            Icons.text_fields,
            Colors.green,
          ),

          // Simboli Rocketbook
          _buildSymbolsSection(analysis.symbols),

          // Azioni estratte
          if (analysis.actions.isNotEmpty)
            _buildActionsSection(analysis.actions),

          // Sezioni
          if (analysis.sections.isNotEmpty)
            _buildSectionsDisplay(analysis.sections),

          // Metadata
          _buildMetadataSection(analysis.metadata),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolsSection(RocketbookSymbols symbols) {
    final activeSymbols = <String>[];
    if (symbols.email) activeSymbols.add('📧 Email');
    if (symbols.googleDrive) activeSymbols.add('💾 Google Drive');
    if (symbols.dropbox) activeSymbols.add('📦 Dropbox');
    if (symbols.evernote) activeSymbols.add('🐘 Evernote');
    if (symbols.slack) activeSymbols.add('💬 Slack');
    if (symbols.icloud) activeSymbols.add('☁️ iCloud');
    if (symbols.onedrive) activeSymbols.add('📁 OneDrive');

    if (activeSymbols.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.send, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Destinazioni Rocketbook',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeSymbols.map((symbol) => Chip(
                label: Text(symbol),
                backgroundColor: Colors.purple.withOpacity(0.1),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(List<RocketbookAction> actions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.task_alt, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Azioni Estratte',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          ...actions.map((action) => ListTile(
            leading: _getActionIcon(action.type),
            title: Text(action.content),
            subtitle: Text('${action.type.toUpperCase()} - Priorità: ${action.priority}'),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionsDisplay(List<RocketbookSection> sections) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.view_module, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sezioni',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          ...sections.map((section) => ListTile(
            leading: _getSectionIcon(section.type),
            title: Text(section.content),
            subtitle: Text('${section.type.toUpperCase()} - ${section.position}'),
          )),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(RocketbookMetadata metadata) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  'Informazioni Analisi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Qualità pagina: '),
                    Chip(
                      label: Text(metadata.pageQuality),
                      backgroundColor: _getQualityColor(metadata.pageQuality),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Leggibilità: '),
                    Chip(
                      label: Text(metadata.handwritingLegibility),
                      backgroundColor: _getQualityColor(metadata.handwritingLegibility),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Contiene diagrammi: '),
                    Icon(
                      metadata.containsDiagrams ? Icons.check : Icons.close,
                      color: metadata.containsDiagrams ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Icon _getActionIcon(String type) {
    switch (type) {
      case 'task': return const Icon(Icons.task, color: Colors.orange);
      case 'reminder': return const Icon(Icons.alarm, color: Colors.red);
      case 'meeting': return const Icon(Icons.people, color: Colors.blue);
      case 'note': return const Icon(Icons.note, color: Colors.green);
      default: return const Icon(Icons.circle, color: Colors.grey);
    }
  }

  Icon _getSectionIcon(String type) {
    switch (type) {
      case 'text': return const Icon(Icons.text_fields, color: Colors.teal);
      case 'list': return const Icon(Icons.list, color: Colors.teal);
      case 'table': return const Icon(Icons.table_chart, color: Colors.teal);
      case 'diagram': return const Icon(Icons.timeline, color: Colors.teal);
      default: return const Icon(Icons.article, color: Colors.teal);
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'good':
      case 'high': return Colors.green.withOpacity(0.2);
      case 'fair':
      case 'medium': return Colors.orange.withOpacity(0.2);
      case 'poor':
      case 'low': return Colors.red.withOpacity(0.2);
      default: return Colors.grey.withOpacity(0.2);
    }
  }

  void _saveAsNote(BuildContext context, WidgetRef ref, RocketbookAnalysis analysis) {
    // TODO: Implementa il salvataggio come nota
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funzione di salvataggio in sviluppo'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Estensione rimossa, ora il metodo è direttamente nella classe OpenAIService
