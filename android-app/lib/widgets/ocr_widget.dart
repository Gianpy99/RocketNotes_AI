import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/rocketbook/ocr/ocr_service_real.dart';
import '../features/rocketbook/models/scanned_content.dart';

/// Widget per gestione OCR con UI intuitiva
class OCRWidget extends StatefulWidget {
  final String imagePath;
  final Function(ScannedContent)? onOCRComplete;
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
  ScannedContent? _ocrResult;
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
      final result = await OCRService.instance.processImage(widget.imagePath);
      debugPrint('🔍 OCR_WIDGET: Risultato - Status: ${result.status}');
      if (result.status == ProcessingStatus.completed) {
        final preview = result.rawText.length > 50 ? '${result.rawText.substring(0, 50)}...' : result.rawText;
        debugPrint('🔍 OCR_WIDGET: Testo estratto: $preview');
      } else {
        debugPrint('🔍 OCR_WIDGET: Status: ${result.status}');
      }
      
      setState(() {
        _ocrResult = result;
        _isProcessing = false;
      });

      widget.onOCRComplete?.call(result);

      if (result.status == ProcessingStatus.completed) {
        _showSuccessSnackBar();
      } else if (result.status == ProcessingStatus.failed) {
        _showErrorSnackBar('OCR processing failed');
      }
    } catch (e) {
      debugPrint('❌ OCR_WIDGET: Eccezione durante OCR: $e');
      setState(() {
        _ocrResult = ScannedContent.fromImage(widget.imagePath);
        _ocrResult!.status = ProcessingStatus.failed;
        _ocrResult!.rawText = 'Errore imprevisto: $e';
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
                'OCR completato: ${_ocrResult!.rawText.length} caratteri estratti',
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
    if (_ocrResult?.rawText != null) {
      Clipboard.setData(ClipboardData(text: _ocrResult!.rawText));
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
          child: Column(
            children: [
              Text(
                'Testo Estratto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    _ocrResult!.rawText.isNotEmpty ? _ocrResult!.rawText : 'Nessun testo estratto',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
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
        if (_ocrResult?.status == ProcessingStatus.completed)
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
    
    if (result.status == ProcessingStatus.failed) {
      return _buildErrorWidget('OCR processing failed');
    }

    if (result.rawText.isEmpty) {
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

  Widget _buildSuccessWidget(ScannedContent result) {
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
          _buildTextPreview(result.rawText),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultStats(ScannedContent result) {
    return Wrap(
      spacing: 12,
      children: [
        _buildStatChip('${result.rawText.length} caratteri', Icons.text_fields),
        _buildStatChip('${(result.ocrMetadata.overallConfidence * 100).toStringAsFixed(1)}%', Icons.speed),
        _buildStatChip('EN', Icons.language),
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
