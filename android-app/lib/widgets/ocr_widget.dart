import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/ocr_service.dart';

/// Widget per gestione OCR con UI intuitiva
class OCRWidget extends StatefulWidget {
  final String imagePath;
  final Function(OCRResult)? onOCRComplete;
  final bool autoExtract;

  const OCRWidget({
    super.key,
    required this.imagePath,
    this.onOCRComplete,
    this.autoExtract = false,
  });

  @override
  State<OCRWidget> createState() => _OCRWidgetState();
}

class _OCRWidgetState extends State<OCRWidget> {
  OCRResult? _ocrResult;
  bool _isProcessing = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoExtract) {
      _extractText();
    }
  }

  Future<void> _extractText() async {
    setState(() {
      _isProcessing = true;
      _hasStarted = true;
      _ocrResult = null;
    });

    try {
      debugPrint('🔍 OCR_WIDGET: Iniziando estrazione da: ${widget.imagePath}');
      final result = await OCRService.extractTextFromImage(widget.imagePath);
      debugPrint('🔍 OCR_WIDGET: Risultato - Success: ${result.isSuccess}');
      if (result.isSuccess) {
        final preview = result.text.length > 50 ? result.text.substring(0, 50) + '...' : result.text;
        debugPrint('🔍 OCR_WIDGET: Testo estratto: $preview');
      } else {
        debugPrint('🔍 OCR_WIDGET: Errore: ${result.error}');
      }
      
      setState(() {
        _ocrResult = result;
        _isProcessing = false;
      });

      widget.onOCRComplete?.call(result);

      if (result.isSuccess) {
        _showSuccessSnackBar();
      } else if (result.hasError) {
        _showErrorSnackBar(result.error!);
      }
    } catch (e) {
      debugPrint('❌ OCR_WIDGET: Eccezione durante OCR: $e');
      setState(() {
        _ocrResult = OCRResult.error('Errore imprevisto: $e');
        _isProcessing = false;
      });
      _showErrorSnackBar('Errore imprevisto: $e');
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OCR completato: ${_ocrResult!.text.length} caratteri estratti',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Copia',
          textColor: Colors.white,
          onPressed: _copyTextToClipboard,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Riprova',
          textColor: Colors.white,
          onPressed: _extractText,
        ),
      ),
    );
  }

  void _copyTextToClipboard() {
    if (_ocrResult?.text != null) {
      Clipboard.setData(ClipboardData(text: _ocrResult!.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testo copiato negli appunti'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFullResults() {
    if (_ocrResult == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: OCRResultDetailWidget(
            result: _ocrResult!,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isProcessing) _buildLoadingWidget(),
            if (_ocrResult != null) _buildResultWidget(),
            if (!_hasStarted) _buildStartWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.text_fields, color: Colors.blue),
        const SizedBox(width: 8),
        const Text(
          'OCR - Estrazione Testo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_ocrResult?.isSuccess == true)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showFullResults,
            tooltip: 'Dettagli completi',
          ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elaborazione in corso...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estrazione testo con Google ML Kit',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultWidget() {
    final result = _ocrResult!;
    
    if (result.hasError) {
      return _buildErrorWidget(result.error!);
    }

    if (result.isEmpty) {
      return _buildEmptyWidget();
    }

    return _buildSuccessWidget(result);
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Errore OCR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _extractText,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.text_fields_outlined, 
               size: 48, 
               color: Colors.orange.shade700),
          const SizedBox(height: 8),
          Text(
            'Nessun testo rilevato',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Prova con un\'immagine più nitida o con più testo'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _extractText,
            icon: const Icon(Icons.refresh),
            label: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(OCRResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Testo estratto con successo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultStats(result),
          const SizedBox(height: 12),
          _buildTextPreview(result.text),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultStats(OCRResult result) {
    return Wrap(
      spacing: 12,
      children: [
        _buildStatChip('${result.text.length} caratteri', Icons.text_fields),
        _buildStatChip('${(result.confidence * 100).toStringAsFixed(1)}%', Icons.speed),
        _buildStatChip(result.language.toUpperCase(), Icons.language),
        if (result.isWebFallback)
          _buildStatChip('Web Fallback', Icons.web, color: Colors.orange),
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon, {Color? color}) {
    final materialColor = color is MaterialColor ? color : Colors.blue;
    return Chip(
      avatar: Icon(icon, size: 16, color: materialColor.shade700),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: materialColor.shade100,
    );
  }

  Widget _buildTextPreview(String text) {
    final preview = text.length > 200 ? '${text.substring(0, 200)}...' : text;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anteprima testo:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: const TextStyle(fontSize: 14),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _copyTextToClipboard,
            icon: const Icon(Icons.copy),
            label: const Text('Copia Testo'),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showFullResults,
          icon: const Icon(Icons.visibility),
          label: const Text('Dettagli'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStartWidget() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.text_fields_outlined, 
               size: 64, 
               color: Colors.blue.shade300),
          const SizedBox(height: 16),
          const Text(
            'Estrai testo dall\'immagine',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa Google ML Kit per riconoscere il testo scritto',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _extractText,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Avvia OCR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per mostrare i dettagli completi del risultato OCR
class OCRResultDetailWidget extends StatelessWidget {
  final OCRResult result;
  final ScrollController? scrollController;

  const OCRResultDetailWidget({
    super.key,
    required this.result,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatistics(),
                const SizedBox(height: 16),
                _buildFullText(),
                const SizedBox(height: 16),
                if (result.blocks.isNotEmpty) _buildTextBlocks(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.analytics, color: Colors.blue),
        const SizedBox(width: 8),
        const Text(
          'Risultati OCR Dettagliati',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final stats = result.statistics;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiche',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Caratteri', '${stats['text_length']}'),
            _buildStatRow('Confidenza', '${stats['confidence_percentage']}%'),
            _buildStatRow('Parole', '${stats['word_count']}'),
            _buildStatRow('Righe', '${stats['line_count']}'),
            _buildStatRow('Blocchi', '${stats['block_count']}'),
            _buildStatRow('Lingua', '${stats['language']}'),
            _buildStatRow('Tempo', '${stats['processing_time_ms']}ms'),
            if (stats['is_web_fallback'] == true)
              _buildStatRow('Modalità', 'Web Fallback', isWarning: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.orange : null,
              fontWeight: isWarning ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullText() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Testo Completo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.text));
                  },
                  tooltip: 'Copia tutto',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                result.text.isNotEmpty ? result.text : 'Nessun testo estratto',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBlocks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blocchi di Testo (${result.blocks.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...result.blocks.asMap().entries.map((entry) {
              final index = entry.key;
              final block = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blocco ${index + 1} (${(block.confidence * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(block.text),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
