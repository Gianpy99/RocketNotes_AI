// ==========================================
// lib/ui/widgets/shopping/voice_input_dialog.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shopping_service.dart';
import '../../../core/services/family_service.dart';

// TODO: SHOPPING_FEATURES - Add advanced voice features
// - Add speech-to-text integration
// - Add voice command parsing
// - Add voice feedback
// - Add wake word detection

class VoiceInputDialog extends StatefulWidget {
  final String listId;

  const VoiceInputDialog({super.key, required this.listId});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  bool _isListening = false;
  String _recognizedText = '';
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice Input'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice recording button
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red.shade100 : AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: _isListening ? Colors.red : AppColors.primary,
                  width: 3,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  size: 48,
                  color: _isListening ? Colors.red : AppColors.primary,
                ),
                onPressed: _toggleListening,
              ),
            ),
            const SizedBox(height: 16),

            // Status text
            Text(
              _isListening ? 'Listening...' : 'Tap to start recording',
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Recognized text display
            if (_recognizedText.isNotEmpty) ...[
              const Text(
                'Recognized:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_recognizedText),
              ),
              const SizedBox(height: 16),
            ],

            // Manual text input as fallback
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Or type your items',
                hintText: 'e.g., add milk, check off bread',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _processInput,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Process'),
        ),
      ],
    );
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      // TODO: Start speech recognition
      _startListening();
    } else {
      // TODO: Stop speech recognition
      _stopListening();
    }
  }

  void _startListening() {
    // TODO: Implement actual speech-to-text
    // For now, simulate recognition after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isListening) {
        setState(() {
          _recognizedText = 'Add organic milk and fresh bread';
          _isListening = false;
        });
      }
    });
  }

  void _stopListening() {
    // TODO: Stop speech recognition
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processInput() async {
    final text = _textController.text.trim().isNotEmpty
        ? _textController.text.trim()
        : _recognizedText;

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide some input'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // TODO: Implement proper voice command parsing
      await _parseAndExecuteCommands(text);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice commands processed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process voice input: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _parseAndExecuteCommands(String input) async {
    // Simple command parsing - can be enhanced with NLP later
    final commands = input.toLowerCase().split(',').map((cmd) => cmd.trim());

    for (final command in commands) {
      if (command.startsWith('add ') || command.startsWith('buy ')) {
        final itemName = command.replaceFirst(RegExp(r'^(add|buy)\s+'), '');
        await _addItemFromVoice(itemName);
      } else if (command.startsWith('check ') || command.startsWith('mark ')) {
        final itemName = command.replaceFirst(RegExp(r'^(check|mark)\s+'), '');
        await _checkOffItemFromVoice(itemName);
      } else if (command.startsWith('remove ') || command.startsWith('delete ')) {
        final itemName = command.replaceFirst(RegExp(r'^(remove|delete)\s+'), '');
        await _removeItemFromVoice(itemName);
      }
    }
  }

  Future<void> _addItemFromVoice(String itemName) async {
    final currentUser = await FamilyService.instance.getCurrentUser();
    if (currentUser == null) return;

    final item = await ShoppingService.instance.createQuickItem(
      itemName,
      createdBy: currentUser.id,
      category: 'pantry', // Default category
    );

    await ShoppingService.instance.addItemToList(widget.listId, item);
  }

  Future<void> _checkOffItemFromVoice(String itemName) async {
    final currentUser = await FamilyService.instance.getCurrentUser();
    final list = await ShoppingService.instance.getShoppingList(widget.listId);

    if (list == null || currentUser == null) return;

    // Find item by name (simple matching)
    final item = list.items.firstWhere(
      (item) => item.name.toLowerCase().contains(itemName.toLowerCase()),
      orElse: () => throw Exception('Item "$itemName" not found'),
    );

    await ShoppingService.instance.toggleItemCompletion(
      widget.listId,
      item.id,
      completedBy: currentUser.id,
    );
  }

  Future<void> _removeItemFromVoice(String itemName) async {
    final list = await ShoppingService.instance.getShoppingList(widget.listId);

    if (list == null) return;

    // Find item by name (simple matching)
    final item = list.items.firstWhere(
      (item) => item.name.toLowerCase().contains(itemName.toLowerCase()),
      orElse: () => throw Exception('Item "$itemName" not found'),
    );

    await ShoppingService.instance.removeItemFromList(widget.listId, item.id);
  }
}
