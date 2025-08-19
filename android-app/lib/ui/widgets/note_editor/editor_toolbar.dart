// lib/ui/widgets/note_editor/editor_toolbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditorToolbar extends StatelessWidget {
  final quill.QuillController controller;
  final bool isDarkMode;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: quill.QuillSimpleToolbar(
        controller: controller,
        configurations: const quill.QuillSimpleToolbarConfigurations(),
      ),
    );
  }
}
