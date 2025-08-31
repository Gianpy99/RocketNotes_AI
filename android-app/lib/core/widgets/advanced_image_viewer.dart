// ==========================================
// lib/core/widgets/advanced_image_viewer.dart
// ==========================================

import 'package:flutter/material.dart';
import '../utils/web_image_handler.dart';

/// Widget avanzato per visualizzazione immagini con controlli zoom e info
class AdvancedImageViewer extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final bool showControls;
  final String? title;
  
  const AdvancedImageViewer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.showControls = true,
    this.title,
  });

  @override
  _AdvancedImageViewerState createState() => _AdvancedImageViewerState();
}

class _AdvancedImageViewerState extends State<AdvancedImageViewer> {
  BoxFit _currentFit = BoxFit.contain;
  bool _showInfo = false;
  
  final List<BoxFit> _fitOptions = [
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];
  
  final Map<BoxFit, String> _fitNames = {
    BoxFit.contain: 'Contiene',
    BoxFit.cover: 'Copre',
    BoxFit.fill: 'Riempie',
    BoxFit.fitWidth: 'Larghezza',
    BoxFit.fitHeight: 'Altezza',
  };
  
  final Map<BoxFit, IconData> _fitIcons = {
    BoxFit.contain: Icons.fit_screen,
    BoxFit.cover: Icons.fullscreen,
    BoxFit.fill: Icons.aspect_ratio,
    BoxFit.fitWidth: Icons.width_normal,
    BoxFit.fitHeight: Icons.height,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header con titolo e controlli
          if (widget.showControls || widget.title != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (widget.title != null) ...[
                    Icon(Icons.image, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  
                  if (widget.showControls) ...[
                    // Selezione modalità visualizzazione
                    PopupMenuButton<BoxFit>(
                      icon: Icon(
                        _fitIcons[_currentFit],
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Modalità visualizzazione: ${_fitNames[_currentFit]}',
                      onSelected: (BoxFit fit) {
                        setState(() {
                          _currentFit = fit;
                        });
                      },
                      itemBuilder: (context) => _fitOptions.map((fit) {
                        return PopupMenuItem<BoxFit>(
                          value: fit,
                          child: Row(
                            children: [
                              Icon(
                                _fitIcons[fit],
                                size: 18,
                                color: _currentFit == fit 
                                  ? Theme.of(context).primaryColor 
                                  : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _fitNames[fit]!,
                                style: TextStyle(
                                  color: _currentFit == fit 
                                    ? Theme.of(context).primaryColor 
                                    : null,
                                  fontWeight: _currentFit == fit 
                                    ? FontWeight.w600 
                                    : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(width: 4),
                    
                    // Toggle info
                    IconButton(
                      icon: Icon(
                        _showInfo ? Icons.info : Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: _showInfo ? 'Nascondi info' : 'Mostra info',
                      onPressed: () {
                        setState(() {
                          _showInfo = !_showInfo;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          
          // Immagine principale
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: WebImageHandler.createWebCompatibleImage(
                widget.imagePath,
                width: widget.width,
                height: widget.height,
                fit: _currentFit,
              ),
            ),
          ),
          
          // Info panel (se attivo)
          if (_showInfo && widget.showControls)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informazioni Immagine',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Modalità', _fitNames[_currentFit]!),
                  _buildInfoRow('Percorso', _getShortPath(widget.imagePath)),
                  if (widget.width != null)
                    _buildInfoRow('Larghezza', '${widget.width!.toInt()}px'),
                  if (widget.height != null)
                    _buildInfoRow('Altezza', '${widget.height!.toInt()}px'),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getShortPath(String path) {
    if (path.startsWith('blob:')) {
      return 'Blob URL (temporaneo)';
    } else if (path.contains('base64')) {
      return 'Codifica Base64';
    } else if (path.length > 40) {
      return '...${path.substring(path.length - 40)}';
    }
    return path;
  }
}

/// Dialog fullscreen per visualizzazione immagini
class FullscreenImageDialog extends StatelessWidget {
  final String imagePath;
  final String? title;
  
  const FullscreenImageDialog({
    super.key,
    required this.imagePath,
    this.title,
  });
  
  static void show(BuildContext context, String imagePath, {String? title}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FullscreenImageDialog(
        imagePath: imagePath,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: title != null ? Text(title!) : const Text('Immagine'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.1,
          maxScale: 10.0,
          child: Center(
            child: WebImageHandler.createWebCompatibleImage(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
