import 'package:flutter/material.dart';
import '../core/utils/web_image_handler.dart';

class AdvancedImageViewer extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool showControls;

  const AdvancedImageViewer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.showControls = true,
  });

  @override
  State<AdvancedImageViewer> createState() => _AdvancedImageViewerState();
}

class _AdvancedImageViewerState extends State<AdvancedImageViewer> {
  BoxFit _currentFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    _currentFit = widget.fit ?? BoxFit.contain;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showControls) _buildControls(),
        Expanded(
          child: Center(
            child: WebImageHandler.createWebCompatibleImage(
              widget.imagePath,
              width: widget.width,
              height: widget.height,
              fit: _currentFit,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFitButton('Adatta', BoxFit.contain),
          _buildFitButton('Riempi', BoxFit.cover),
          _buildFitButton('Riempibile', BoxFit.fill),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _showFullscreen,
            tooltip: 'Schermo intero',
          ),
        ],
      ),
    );
  }

  Widget _buildFitButton(String label, BoxFit fit) {
    final isSelected = _currentFit == fit;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentFit = fit;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  void _showFullscreen() {
    showDialog(
      context: context,
      builder: (context) => FullscreenImageDialog(imagePath: widget.imagePath),
    );
  }
}

class FullscreenImageDialog extends StatefulWidget {
  final String imagePath;

  const FullscreenImageDialog({
    super.key,
    required this.imagePath,
  });

  @override
  State<FullscreenImageDialog> createState() => _FullscreenImageDialogState();
}

class _FullscreenImageDialogState extends State<FullscreenImageDialog> {
  BoxFit _currentFit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visualizzazione Immagine'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Controlli di fit
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFitButton('Adatta', BoxFit.contain),
                  _buildFitButton('Riempi', BoxFit.cover),
                  _buildFitButton('Riempibile', BoxFit.fill),
                ],
              ),
            ),
            // Immagine
            Expanded(
              child: Center(
                child: WebImageHandler.createWebCompatibleImage(
                  widget.imagePath,
                  fit: _currentFit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitButton(String label, BoxFit fit) {
    final isSelected = _currentFit == fit;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentFit = fit;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}
