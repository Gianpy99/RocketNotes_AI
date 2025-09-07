import 'package:flutter/material.dart';
import '../../../models/family_member.dart';

class FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final String? displayName; // Optional display name from Firebase Auth
  final VoidCallback? onTap;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.displayName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = displayName ?? 'User ${member.userId.substring(0, 8)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(member.role),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.roleDisplayName),
            Text(
              'Joined ${_formatDate(member.joinedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: member.isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.access_time, color: Colors.orange),
        onTap: onTap,
      ),
    );
  }

  Color _getRoleColor(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return Colors.purple;
      case FamilyRole.admin:
        return Colors.blue;
      case FamilyRole.editor:
        return Colors.green;
      case FamilyRole.viewer:
        return Colors.orange;
      case FamilyRole.limited:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }
}
