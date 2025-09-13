import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../models/notification_models.dart';
import '../services/notification_navigation_service.dart';

/// Screen for viewing notification history (T089)
class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends ConsumerState<NotificationHistoryScreen> {
  String _selectedFilter = 'all';
  bool _showOnlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(notificationHistoryProvider);
    final filteredHistory = _filterNotifications(history);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronologia Notifiche'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Segna tutte come lette'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Cancella cronologia'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Filtra per tipo: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value ?? 'all';
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tutte')),
                            DropdownMenuItem(value: 'family_invitation', child: Text('Inviti famiglia')),
                            DropdownMenuItem(value: 'note_shared', child: Text('Note condivise')),
                            DropdownMenuItem(value: 'note_comment', child: Text('Commenti')),
                            DropdownMenuItem(value: 'note_updated', child: Text('Aggiornamenti')),
                            DropdownMenuItem(value: 'system', child: Text('Sistema')),
                            DropdownMenuItem(value: 'emergency', child: Text('Emergenza')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnlyUnread,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyUnread = value ?? false;
                          });
                        },
                      ),
                      const Text('Solo non lette'),
                      const Spacer(),
                      Text('${filteredHistory.length} notifiche'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Notification List
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final notification = filteredHistory[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<NotificationHistory> _filterNotifications(List<NotificationHistory> history) {
    var filtered = history;

    // Filter by type
    if (_selectedFilter != 'all') {
      NotificationType? typeEnum;
      try {
        typeEnum = NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == _selectedFilter,
          orElse: () => NotificationType.system,
        );
      } catch (_) {
        typeEnum = NotificationType.system;
      }
      filtered = filtered.where((n) => n.type == typeEnum).toList();
    }

    // Filter by read status
    if (_showOnlyUnread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    // Sort by timestamp (newest first)
  filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna notifica trovata',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter != 'all' || _showOnlyUnread
                ? 'Prova a modificare i filtri'
                : 'Le notifiche appariranno qui quando le riceverai',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationHistory notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: notification.isRead ? 1 : 3,
      child: ListTile(
        leading: _getNotificationIcon(notification),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(notification.priority.name),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPriorityLabel(notification.priority.name),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                _markAsRead(notification.id);
                break;
              case 'mark_unread':
                _markAsUnread(notification.id);
                break;
              case 'delete':
                _deleteNotification(notification.id);
                break;
              case 'open':
                _openNotification(notification);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Segna come letta'),
                  ],
                ),
              ),
            if (notification.isRead)
              const PopupMenuItem(
                value: 'mark_unread',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread),
                    SizedBox(width: 8),
                    Text('Segna come non letta'),
                  ],
                ),
              ),
            if (notification.actionData != null)
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new),
                    SizedBox(width: 8),
                    Text('Apri'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Elimina', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          if (notification.actionData != null) {
            _openNotification(notification);
          }
        },
      ),
    );
  }

  Widget _getNotificationIcon(NotificationHistory notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.familyInvitation:
        iconData = Icons.family_restroom;
        iconColor = Colors.blue;
        break;
      case NotificationType.sharedNote:
        iconData = Icons.share;
        iconColor = Colors.green;
        break;
      case NotificationType.comment:
        iconData = Icons.comment;
        iconColor = Colors.orange;
        break;
      case NotificationType.familyActivity:
        iconData = Icons.update;
        iconColor = Colors.purple;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m fa';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h fa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g fa';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      case 'emergency':
        return Colors.red[900]!;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'BASSA';
      case 'normal':
        return 'NORMALE';
      case 'high':
        return 'ALTA';
      case 'urgent':
        return 'URGENTE';
      case 'emergency':
        return 'EMERGENZA';
      default:
        return 'NORMALE';
    }
  }

  void _markAsRead(String notificationId) {
    ref.read(notificationHistoryProvider.notifier).markAsRead(notificationId);
  }

  void _markAsUnread(String notificationId) {
    ref.read(notificationHistoryProvider.notifier).markAsUnread(notificationId);
  }

  void _markAllAsRead() {
    ref.read(notificationHistoryProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutte le notifiche sono state segnate come lette'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteNotification(String notificationId) {
    ref.read(notificationHistoryProvider.notifier).deleteNotification(notificationId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifica eliminata'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancella cronologia'),
        content: const Text('Sei sicuro di voler cancellare tutta la cronologia delle notifiche? Questa azione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationHistoryProvider.notifier).clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cronologia notifiche cancellata'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Cancella', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openNotification(NotificationHistory notification) {
    if (notification.actionData != null) {
      NotificationNavigationService.navigateFromNotification(notification.actionData!);
    }
  }
}