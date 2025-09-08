import 'package:flutter/material.dart';
import '../../models/shared_note.dart';
import '../../models/note_permission.dart';

class SharedNoteCard extends StatelessWidget {
  final SharedNote sharedNote;
  final VoidCallback? onTap;

  const SharedNoteCard({
    super.key,
    required this.sharedNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and permission badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sharedNote.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPermissionBadge(sharedNote.permission),
                ],
              ),

              if (sharedNote.description != null && sharedNote.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sharedNote.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Metadata row
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Shared by ${sharedNote.sharedBy}', // TODO: Get actual name
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(sharedNote.sharedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Status indicator
              if (sharedNote.status != SharingStatus.approved) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      sharedNote.status == SharingStatus.pending
                          ? Icons.hourglass_empty
                          : Icons.cancel,
                      size: 16,
                      color: sharedNote.status == SharingStatus.pending
                          ? Colors.orange
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sharedNote.status == SharingStatus.pending
                          ? 'Pending approval'
                          : 'Rejected',
                      style: TextStyle(
                        fontSize: 12,
                        color: sharedNote.status == SharingStatus.pending
                            ? Colors.orange
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionBadge(NotePermission permission) {
    // Determine the highest level of permission
    if (permission.canInviteCollaborators) {
      return _buildBadge('Admin', Colors.red, Icons.admin_panel_settings);
    } else if (permission.canEdit) {
      return _buildBadge('Edit', Colors.orange, Icons.edit);
    } else if (permission.canComment) {
      return _buildBadge('Comment', Colors.green, Icons.comment);
    } else if (permission.canView) {
      return _buildBadge('View', Colors.blue, Icons.visibility);
    } else {
      return _buildBadge('None', Colors.grey, Icons.block);
    }
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
