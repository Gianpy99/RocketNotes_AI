import 'package:flutter/material.dart';
import '../services/shared_note_export_service.dart';

/// Widget for selecting export options
class ExportOptionsDialog extends StatefulWidget {
  final Function(ExportOptions) onExport;
  final Function() onCancel;

  const ExportOptionsDialog({
    super.key,
    required this.onExport,
    required this.onCancel,
  });

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _includeComments = true;
  bool _includeMetadata = true;
  bool _includeTimestamps = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Format',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildFormatSelection(),
            const SizedBox(height: 16),
            const Text(
              'Include',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildIncludeOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleExport,
          child: const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      children: ExportFormat.values.map((format) {
        return RadioMenuButton<ExportFormat>(
          value: format,
          groupValue: _selectedFormat,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFormat = value;
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getFormatDisplayName(format)),
              Text(
                _getFormatDescription(format),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncludeOptions() {
    return Column(
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Comments'),
          subtitle: const Text('Include all comments and replies'),
          value: _includeComments,
          onChanged: (value) {
            setState(() {
              _includeComments = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Metadata'),
          subtitle: const Text('Include author and sharing information'),
          value: _includeMetadata,
          onChanged: (value) {
            setState(() {
              _includeMetadata = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Timestamps'),
          subtitle: const Text('Include creation and modification dates'),
          value: _includeTimestamps,
          onChanged: (value) {
            setState(() {
              _includeTimestamps = value ?? true;
            });
          },
        ),
      ],
    );
  }

  String _getFormatDisplayName(ExportFormat format) {
    switch (format) {
      case ExportFormat.text:
        return 'Text (.txt)';
      case ExportFormat.pdf:
        return 'PDF (.pdf)';
      case ExportFormat.markdown:
        return 'Markdown (.md)';
      case ExportFormat.html:
        return 'HTML (.html)';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.text:
        return 'Plain text format, easy to read and edit';
      case ExportFormat.pdf:
        return 'Formatted document, perfect for printing';
      case ExportFormat.markdown:
        return 'Markdown format, great for documentation';
      case ExportFormat.html:
        return 'Web page format with styling';
    }
  }

  void _handleExport() {
    final options = ExportOptions(
      format: _selectedFormat,
      includeComments: _includeComments,
      includeMetadata: _includeMetadata,
      includeTimestamps: _includeTimestamps,
    );
    
    widget.onExport(options);
  }
}

/// Widget for share options dialog
class ShareOptionsDialog extends StatelessWidget {
  final Function(ExportOptions) onShareContent;
  final Function() onShareLink;
  final Function() onCancel;

  const ShareOptionsDialog({
    super.key,
    required this.onShareContent,
    required this.onShareLink,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Share Link'),
            subtitle: const Text('Share a link to this note'),
            onTap: () {
              Navigator.of(context).pop();
              onShareLink();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Share Content'),
            subtitle: const Text('Share the note content with options'),
            onTap: () {
              Navigator.of(context).pop();
              _showContentShareOptions(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showContentShareOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        onExport: (options) {
          Navigator.of(context).pop();
          onShareContent(options);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
