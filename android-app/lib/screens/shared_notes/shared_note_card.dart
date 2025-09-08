import 'package:flutter/material.dart';
import '../../models/shared_note.dart';
import '../../models/note_permission.dart';
import '../../core/services/firebase_service.dart';

class SharedNoteCard extends StatefulWidget {
  final SharedNote sharedNote;
  final VoidCallback? onTap;

  const SharedNoteCard({
    super.key,
    required this.sharedNote,
    this.onTap,
  });

  @override
  State<SharedNoteCard> createState() => _SharedNoteCardState();
}

class _SharedNoteCardState extends State<SharedNoteCard> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _sharedByName;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchSharedByName();
  }

  Future<void> _fetchSharedByName() async {
    try {
      final userProfile = await _firebaseService.getUserProfileById(widget.sharedNote.sharedBy);
      if (mounted) {
        setState(() {
          _sharedByName = userProfile?.displayName ?? 'Unknown User';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sharedByName = 'Unknown User';
          _isLoadingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
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
                      widget.sharedNote.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPermissionBadge(widget.sharedNote.permission),
                ],
              ),

              if (widget.sharedNote.description != null && widget.sharedNote.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.sharedNote.description!,
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
                    _isLoadingName ? 'Loading...' : 'Shared by $_sharedByName',
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
                    _formatDate(widget.sharedNote.sharedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Status indicator
              if (widget.sharedNote.status != SharingStatus.approved) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      widget.sharedNote.status == SharingStatus.pending
                          ? Icons.hourglass_empty
                          : Icons.cancel,
                      size: 16,
                      color: widget.sharedNote.status == SharingStatus.pending
                          ? Colors.orange
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.sharedNote.status == SharingStatus.pending
                          ? 'Pending approval'
                          : 'Rejected',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.sharedNote.status == SharingStatus.pending
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
