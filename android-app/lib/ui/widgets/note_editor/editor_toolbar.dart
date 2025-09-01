// lib/ui/widgets/note_editor/editor_toolbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../core/constants/app_colors.dart';

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
        color: isDarkMode 
          ? AppColors.surfaceDark.withValues(alpha: 0.8)
          : AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDarkMode 
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.bold),
              icon: const Icon(Icons.format_bold),
            ),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.italic),
              icon: const Icon(Icons.format_italic),
            ),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.underline),
              icon: const Icon(Icons.format_underlined),
            ),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.strikeThrough),
              icon: const Icon(Icons.strikethrough_s),
            ),
            const SizedBox(width: 8),
            // Header styles - simplified
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.h1),
              icon: const Text('H1', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.h2),
              icon: const Text('H2', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.ol),
              icon: const Icon(Icons.format_list_numbered),
            ),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.ul),
              icon: const Icon(Icons.format_list_bulleted),
            ),
            IconButton(
              onPressed: () => controller.formatSelection(quill.Attribute.blockQuote),
              icon: const Icon(Icons.format_quote),
            ),
          ],
        ),
      ),
    );
  }
}
