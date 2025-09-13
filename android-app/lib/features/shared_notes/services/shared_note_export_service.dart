import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/shared_note.dart';
import '../../../models/shared_note_comment.dart';
import 'package:intl/intl.dart';

/// Export format options
enum ExportFormat {
  text,
  pdf,
  markdown,
  html
}

/// Export options configuration
class ExportOptions {
  final ExportFormat format;
  final bool includeComments;
  final bool includeMetadata;
  final bool includeTimestamps;

  const ExportOptions({
    required this.format,
    this.includeComments = true,
    this.includeMetadata = true,
    this.includeTimestamps = true,
  });
}

/// Service for exporting and sharing shared notes
class SharedNoteExportService {
  static const String _tempFolderName = 'rocket_notes_exports';

  /// Export a shared note with the specified options
  Future<String> exportNote({
    required SharedNote note,
    required List<SharedNoteComment> comments,
    required ExportOptions options,
    String? noteContent, // Add note content parameter since SharedNote doesn't have content field
  }) async {
    switch (options.format) {
      case ExportFormat.text:
        return _exportAsText(note, comments, options, noteContent);
      case ExportFormat.pdf:
        return await _exportAsPdf(note, comments, options, noteContent);
      case ExportFormat.markdown:
        return _exportAsMarkdown(note, comments, options, noteContent);
      case ExportFormat.html:
        return _exportAsHtml(note, comments, options, noteContent);
    }
  }

  /// Generate a shareable link for the note
  String generateShareLink({
    required String noteId,
    String? baseUrl,
  }) {
    final url = baseUrl ?? 'https://rocketnotes.app';
    return '$url/shared-note/$noteId';
  }

  /// Share note via native sharing
  Future<void> shareNote({
    required SharedNote note,
    required List<SharedNoteComment> comments,
    required ExportOptions options,
    String? subject,
    String? noteContent,
  }) async {
    try {
      final content = await exportNote(
        note: note,
        comments: comments,
        options: options,
        noteContent: noteContent,
      );

      if (options.format == ExportFormat.pdf) {
        // Share PDF file path
        await SharePlus.instance.share(
          ShareParams(text: 'Shared PDF file: $content'),
        );
      } else {
        // Share text content
        await SharePlus.instance.share(
          ShareParams(text: content),
        );
      }
    } catch (e) {
      throw Exception('Failed to share note: $e');
    }
  }

  /// Share link only
  Future<void> shareLink({
    required String noteId,
    String? subject,
    String? baseUrl,
  }) async {
    final link = generateShareLink(noteId: noteId, baseUrl: baseUrl);
    await SharePlus.instance.share(ShareParams(
      text: link,
    ));
  }

  /// Export as plain text
  String _exportAsText(
    SharedNote note,
    List<SharedNoteComment> comments,
    ExportOptions options,
    String? noteContent,
  ) {
    final buffer = StringBuffer();
    
    // Note metadata
    if (options.includeMetadata) {
      buffer.writeln('SHARED NOTE');
      buffer.writeln('=' * 40);
      buffer.writeln('Title: ${note.title}');
      buffer.writeln('Shared by: ${note.sharedBy}');
      if (options.includeTimestamps) {
        buffer.writeln('Shared: ${_formatDateTime(note.sharedAt)}');
        buffer.writeln('Last modified: ${_formatDateTime(note.updatedAt)}');
      }
      buffer.writeln();
    }

    // Note content
    buffer.writeln('CONTENT');
    buffer.writeln('-' * 20);
    buffer.writeln(noteContent ?? 'Content not available');
    buffer.writeln();

    // Comments section
    if (options.includeComments && comments.isNotEmpty) {
      buffer.writeln('COMMENTS (${comments.length})');
      buffer.writeln('-' * 20);
      
      for (final comment in comments) {
        buffer.writeln();
        buffer.writeln('${comment.userDisplayName} wrote:');
        if (options.includeTimestamps) {
          buffer.writeln('  ${_formatDateTime(comment.createdAt)}');
        }
        buffer.writeln('  ${comment.content}');
        
        if (comment.likeCount > 0) {
          buffer.writeln('  👍 ${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}');
        }
      }
    }

    return buffer.toString();
  }

  /// Export as PDF
  Future<String> _exportAsPdf(
    SharedNote note,
    List<SharedNoteComment> comments,
    ExportOptions options,
    String? noteContent,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final content = <pw.Widget>[];

          // Title
          content.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          // Metadata
          if (options.includeMetadata) {
            content.add(pw.SizedBox(height: 16));
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Shared by: ${note.sharedBy}'),
                    if (options.includeTimestamps) ...[
                      pw.Text('Shared: ${_formatDateTime(note.sharedAt)}'),
                      pw.Text('Last modified: ${_formatDateTime(note.updatedAt)}'),
                    ],
                  ],
                ),
              ),
            );
          }

          // Content
          content.add(pw.SizedBox(height: 24));
          content.add(
            pw.Text(
              'Content',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          content.add(pw.SizedBox(height: 8));
          content.add(pw.Text(noteContent ?? 'Content not available'));

          // Comments
          if (options.includeComments && comments.isNotEmpty) {
            content.add(pw.SizedBox(height: 24));
            content.add(
              pw.Text(
                'Comments (${comments.length})',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 8));

            for (final comment in comments) {
              content.add(pw.SizedBox(height: 16));
              content.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            comment.userDisplayName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          if (options.includeTimestamps) ...[
                            pw.Spacer(),
                            pw.Text(
                              _formatDateTime(comment.createdAt),
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(comment.content),
                      if (comment.likeCount > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '👍 ${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          }

          return content;
        },
      ),
    );

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory('${tempDir.path}/$_tempFolderName');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export as Markdown
  String _exportAsMarkdown(
    SharedNote note,
    List<SharedNoteComment> comments,
    ExportOptions options,
    String? noteContent,
  ) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln('# ${note.title}');
    buffer.writeln();

    // Metadata
    if (options.includeMetadata) {
      buffer.writeln('> **Shared by:** ${note.sharedBy}  ');
      if (options.includeTimestamps) {
        buffer.writeln('> **Shared:** ${_formatDateTime(note.sharedAt)}  ');
        buffer.writeln('> **Last modified:** ${_formatDateTime(note.updatedAt)}  ');
      }
      buffer.writeln();
    }

    // Content
    buffer.writeln('## Content');
    buffer.writeln();
    buffer.writeln(noteContent ?? 'Content not available');
    buffer.writeln();

    // Comments
    if (options.includeComments && comments.isNotEmpty) {
      buffer.writeln('## Comments (${comments.length})');
      buffer.writeln();

      for (final comment in comments) {
        buffer.writeln('### ${comment.userDisplayName}');
        if (options.includeTimestamps) {
          buffer.writeln('*${_formatDateTime(comment.createdAt)}*');
          buffer.writeln();
        }
        buffer.writeln(comment.content);
        
        if (comment.likeCount > 0) {
          buffer.writeln();
          buffer.writeln('👍 ${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}');
        }
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Export as HTML
  String _exportAsHtml(
    SharedNote note,
    List<SharedNoteComment> comments,
    ExportOptions options,
    String? noteContent,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${note.title}</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }');
    buffer.writeln('    .metadata { background-color: #f5f5f5; padding: 15px; border-radius: 8px; margin-bottom: 20px; }');
    buffer.writeln('    .comment { background-color: #f9f9f9; padding: 12px; border-radius: 8px; margin-bottom: 15px; }');
    buffer.writeln('    .comment-author { font-weight: bold; }');
    buffer.writeln('    .comment-date { font-size: 0.9em; color: #666; }');
    buffer.writeln('    .like-count { font-size: 0.9em; color: #666; margin-top: 5px; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Title
    buffer.writeln('  <h1>${_escapeHtml(note.title)}</h1>');

    // Metadata
    if (options.includeMetadata) {
      buffer.writeln('  <div class="metadata">');
      buffer.writeln('    <strong>Shared by:</strong> ${_escapeHtml(note.sharedBy)}<br>');
      if (options.includeTimestamps) {
        buffer.writeln('    <strong>Shared:</strong> ${_formatDateTime(note.sharedAt)}<br>');
        buffer.writeln('    <strong>Last modified:</strong> ${_formatDateTime(note.updatedAt)}');
      }
      buffer.writeln('  </div>');
    }

    // Content
    buffer.writeln('  <h2>Content</h2>');
    buffer.writeln('  <div class="content">');
    buffer.writeln('    ${_escapeHtml(noteContent ?? 'Content not available').replaceAll('\n', '<br>')}');
    buffer.writeln('  </div>');

    // Comments
    if (options.includeComments && comments.isNotEmpty) {
      buffer.writeln('  <h2>Comments (${comments.length})</h2>');
      
      for (final comment in comments) {
        buffer.writeln('  <div class="comment">');
        buffer.writeln('    <div class="comment-author">${_escapeHtml(comment.userDisplayName)}</div>');
        if (options.includeTimestamps) {
          buffer.writeln('    <div class="comment-date">${_formatDateTime(comment.createdAt)}</div>');
        }
        buffer.writeln('    <div class="comment-content">${_escapeHtml(comment.content).replaceAll('\n', '<br>')}</div>');
        
        if (comment.likeCount > 0) {
          buffer.writeln('    <div class="like-count">👍 ${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}</div>');
        }
        buffer.writeln('  </div>');
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy at h:mm a').format(dateTime);
  }

  /// Escape HTML special characters
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory('${tempDir.path}/$_tempFolderName');
      if (await exportDir.exists()) {
        await exportDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore cleanup errors
      debugPrint('Failed to cleanup temp files: $e');
    }
  }
}
