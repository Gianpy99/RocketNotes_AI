// lib/presentation/widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';

class SyncStatusWidget extends ConsumerWidget {
  final bool showText;
  final MainAxisSize mainAxisSize;
  
  const SyncStatusWidget({
    super.key,
    this.showText = true,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    
    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        Icon(
          syncStatus.isOnline ? Icons.wifi : Icons.wifi_off,
          color: syncStatus.isOnline ? Colors.green : Colors.red,
          size: 18,
        ),
        if (syncStatus.isSyncing) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
        if (showText && syncStatus.lastSyncTime != null) ...[
          const SizedBox(width: 8),
          Text(
            'Last sync: ${_formatTime(syncStatus.lastSyncTime!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        if (syncStatus.error != null) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 16,
          ),
        ],
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(time);
    }
  }
}
