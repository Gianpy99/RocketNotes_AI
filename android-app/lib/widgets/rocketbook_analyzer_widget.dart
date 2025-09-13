import 'package:flutter/material.dart';
import '../core/services/rocketbook_template_service.dart';
import '../core/services/image_template_recognition.dart';
import '../core/services/chatgpt_integration_service.dart';

/// Widget per l'analisi intelligente delle pagine Rocketbook
class RocketbookAnalyzerWidget extends StatefulWidget {
  final String imagePath;
  final Function(ChatGptRequest)? onAnalysisGenerated;

  const RocketbookAnalyzerWidget({
    super.key,
    required this.imagePath,
    this.onAnalysisGenerated,
  });

  @override
  State<RocketbookAnalyzerWidget> createState() => _RocketbookAnalyzerWidgetState();
}

class _RocketbookAnalyzerWidgetState extends State<RocketbookAnalyzerWidget> {
  TemplateDetectionResult? _detectionResult;
  ChatGptMode _selectedMode = ChatGptMode.analyze;
  bool _isAnalyzing = false;
  String _userPrompt = '';

  @override
  void initState() {
    super.initState();
    _analyzeTemplate();
  }

  Future<void> _analyzeTemplate() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await ImageTemplateRecognition.analyzeImage(widget.imagePath);
      setState(() {
        _detectionResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nell\'analisi: $e')),
        );
      }
    }
  }

  Future<void> _generateAnalysis() async {
    if (_detectionResult == null) return;

    try {
      final request = await ChatGptIntegrationService.generateOptimizedRequest(
        imagePath: widget.imagePath,
        userPrompt: _userPrompt.isNotEmpty ? _userPrompt : null,
        mode: _selectedMode,
      );

      widget.onAnalysisGenerated?.call(request);
      
      if (mounted) {
        _showPromptDialog(request);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella generazione: $e')),
        );
      }
    }
  }

  void _showPromptDialog(ChatGptRequest request) {
    showDialog(
      context: context,
      builder: (context) => ChatGptPromptDialog(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isAnalyzing) _buildLoadingWidget(),
            if (_detectionResult != null) ...[
              _buildDetectionResult(),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildCustomPromptField(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, color: Colors.blue),
        const SizedBox(width: 8),
        const Text(
          'Analisi Rocketbook AI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _analyzeTemplate,
          tooltip: 'Rianalizza template',
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Analizzando template...'),
        ],
      ),
    );
  }

  Widget _buildDetectionResult() {
    final result = _detectionResult!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isReliable ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isReliable ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isReliable ? Icons.check_circle : Icons.warning,
                color: result.isReliable ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.userDescription,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTemplateInfo(result.template),
          const SizedBox(height: 8),
          _buildFeaturesList(result.features),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo(RocketbookTemplate template) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 ${template.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            template.description,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            '🏷️ Categoria: ${template.category}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(ImageFeatures features) {
    final detectedFeatures = features.detectedFeatures;
    if (detectedFeatures.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔍 Caratteristiche rilevate:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: detectedFeatures.map((feature) => Chip(
            label: Text(
              feature,
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: Colors.blue.shade100,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Modalità di analisi:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ChatGptMode.values.map((mode) {
            final isSelected = mode == _selectedMode;
            return FilterChip(
              label: Text(_getModeLabel(mode)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedMode = mode;
                });
              },
              selectedColor: Colors.blue.shade200,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💬 Prompt personalizzato (opzionale):',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Aggiungi istruzioni specifiche per l\'analisi...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _userPrompt = value;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generateAnalysis,
            icon: const Icon(Icons.smart_toy),
            label: const Text('Genera Prompt ChatGPT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _showTips,
          icon: const Icon(Icons.tips_and_updates),
          tooltip: 'Consigli per migliorare il riconoscimento',
        ),
      ],
    );
  }

  String _getModeLabel(ChatGptMode mode) {
    switch (mode) {
      case ChatGptMode.analyze:
        return '📊 Analizza';
      case ChatGptMode.summarize:
        return '📝 Riassumi';
      case ChatGptMode.actionItems:
        return '✅ Action Items';
      case ChatGptMode.enhance:
        return '✨ Migliora';
      case ChatGptMode.convert:
        return '🔄 Converti';
      case ChatGptMode.insights:
        return '💡 Insights';
    }
  }

  void _showTips() {
    final tips = ImageTemplateRecognition.getRecognitionTips();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Consigli per il Riconoscimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tips.map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(tip)),
              ],
            ),
          )).toList(),
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

/// Dialog per mostrare il prompt generato per ChatGPT
class ChatGptPromptDialog extends StatelessWidget {
  final ChatGptRequest request;

  const ChatGptPromptDialog({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.green),
          SizedBox(width: 8),
          Text('Prompt ChatGPT Generato'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetadataChips(),
              const SizedBox(height: 16),
              const Text(
                'Prompt:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  request.prompt,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Copia negli appunti implementata
            Navigator.of(context).pop();
          },
          child: const Text('📋 Copia'),
        ),
        ElevatedButton(
          onPressed: () => _sendToChatGPT(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('🤖 Invia a ChatGPT'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }

  Widget _buildMetadataChips() {
    return Wrap(
      spacing: 8,
      children: [
        Chip(
          label: Text(request.template.name),
          backgroundColor: Colors.blue.shade100,
        ),
        Chip(
          label: Text('${(request.confidence * 100).toStringAsFixed(1)}%'),
          backgroundColor: request.confidence > 0.8 
              ? Colors.green.shade100 
              : Colors.orange.shade100,
        ),
        Chip(
          label: Text(request.mode.toString().split('.').last),
          backgroundColor: Colors.purple.shade100,
        ),
      ],
    );
  }

  /// Invia il prompt direttamente a ChatGPT
  void _sendToChatGPT(BuildContext context) async {
    Navigator.of(context).pop(); // Chiudi il dialog corrente
    
    // Mostra dialog di caricamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Invio a ChatGPT...'),
          ],
        ),
      ),
    );

    try {
      // Chiama l'API ChatGPT
      final response = await ChatGptIntegrationService.sendToChatGPT(
        imagePath: request.metadata['imagePath'] ?? '',
        userPrompt: null, // Usa il prompt già generato
        mode: request.mode,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Chiudi dialog caricamento

        // Mostra la risposta
        _showChatGptResponse(context, response);
      }
      
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Chiudi dialog caricamento
        
        // Mostra errore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostra la risposta di ChatGPT
  void _showChatGptResponse(BuildContext context, ChatGptResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.green),
            SizedBox(width: 8),
            Text('Risposta ChatGPT'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (response.summary.isNotEmpty) ...[
                  const Text('📋 Riassunto:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(response.summary),
                  const SizedBox(height: 16),
                ],
                const Text('💬 Risposta completa:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: SelectableText(
                    response.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (response.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('💡 Suggerimenti:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...response.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $s'),
                  )),
                ],
                if (response.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('✅ Azioni:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...response.actionItems.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $a'),
                  )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}
