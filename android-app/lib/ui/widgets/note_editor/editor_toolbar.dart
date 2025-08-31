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
          ? AppColors.surfaceDark.withOpacity(0.8)
          : AppColors.surfaceLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDarkMode 
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: quill.QuillSimpleToolbar(
        controller: controller,
        configurations: quill.QuillSimpleToolbarConfigurations(
          showCodeBlock: false,
          showInlineCode: true,
          showColorButton: false,
          showBackgroundColorButton: false,
          showListCheck: true,
          showListBullets: true,
          showListNumbers: true,
          showIndent: true,
          showDirection: false,
          showHeaderStyle: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showClearFormat: true,
          showAlignmentButtons: false,
          showSubscript: false,
          showSuperscript: false,
          showQuote: true,
          showLink: true,
          multiRowsDisplay: false,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          buttonOptions: quill.QuillSimpleToolbarButtonOptions(
            base: quill.QuillToolbarBaseButtonOptions(
              iconTheme: quill.QuillIconTheme(
                iconButtonSelectedData: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    backgroundColor: isDarkMode 
                      ? AppColors.primaryBlue.withOpacity(0.2)
                      : AppColors.primaryBlue.withOpacity(0.1),
                  ),
                ),
                iconButtonUnselectedData: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    foregroundColor: isDarkMode 
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
