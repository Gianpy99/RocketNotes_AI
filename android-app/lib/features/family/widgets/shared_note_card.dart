import 'package:flutter/material.dart';
import '../../../models/shared_note.dart';

class SharedNoteCard extends StatelessWidget {
  final SharedNote note;
  final String? sharedByName; // Optional display name from Firebase Auth
  final VoidCallback? onTap;

  const SharedNoteCard({
    super.key,
    required this.note,
    this.sharedByName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sharerName = sharedByName ?? 'User ${note.sharedBy.substring(0, 8)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPermissionColor(note.permission),
          child: Icon(
            _getPermissionIcon(note.permission),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.description != null && note.description!.isNotEmpty)
              Text(
                note.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Shared by $sharerName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(note.sharedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (note.allowCollaboration)
              const Icon(
                Icons.group,
                color: Colors.blue,
                size: 16,
              ),
            if (note.expiresAt != null)
              Text(
                'Expires ${_formatExpiryDate(note.expiresAt!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                ),
              ),
            if (note.status != SharingStatus.approved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(note.status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  note.status.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getPermissionColor(NotePermission permission) {
    if (permission.canEdit) {
      return Colors.green;
    } else if (permission.canView) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  IconData _getPermissionIcon(NotePermission permission) {
    if (permission.canEdit) {
      return Icons.edit;
    } else if (permission.canView) {
      return Icons.visibility;
    } else {
      return Icons.lock;
    }
  }

  Color _getStatusColor(SharingStatus status) {
    switch (status) {
      case SharingStatus.pending:
        return Colors.orange;
      case SharingStatus.approved:
        return Colors.green;
      case SharingStatus.rejected:
        return Colors.red;
      case SharingStatus.expired:
        return Colors.grey;
      case SharingStatus.revoked:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  String _formatExpiryDate(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    }
  }
}
