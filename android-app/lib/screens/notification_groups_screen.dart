import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../models/notification_models.dart';
import '../services/notification_navigation_service.dart';

/// Screen for viewing grouped notifications (T090)
class NotificationGroupsScreen extends ConsumerStatefulWidget {
  const NotificationGroupsScreen({super.key});

  @override
  ConsumerState<NotificationGroupsScreen> createState() => _NotificationGroupsScreenState();
}

class _NotificationGroupsScreenState extends ConsumerState<NotificationGroupsScreen> {
  String _groupingMode = 'type'; // 'type', 'date', 'priority'
  final Set<String> _expandedGroups = <String>{};

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(notificationHistoryProvider);
    final groups = _createGroups(history);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche Raggruppate'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.group_work),
            onSelected: (value) {
              setState(() {
                _groupingMode = value;
                _expandedGroups.clear();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'type',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Raggruppa per tipo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('Raggruppa per data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(Icons.priority_high),
                    SizedBox(width: 8),
                    Text('Raggruppa per priorità'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'expand_all':
                  setState(() {
                    _expandedGroups.addAll(groups.map((g) => g.id));
                  });
                  break;
                case 'collapse_all':
                  setState(() {
                    _expandedGroups.clear();
                  });
                  break;
                case 'mark_all_read':
                  _markAllGroupsAsRead(groups);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'expand_all',
                child: Row(
                  children: [
                    Icon(Icons.expand_more),
                    SizedBox(width: 8),
                    Text('Espandi tutto'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collapse_all',
                child: Row(
                  children: [
                    Icon(Icons.expand_less),
                    SizedBox(width: 8),
                    Text('Comprimi tutto'),
                  ],
                ),
              ),
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
            ],
          ),
        ],
      ),
      body: groups.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupCard(group);
              },
            ),
    );
  }

  List<NotificationGroup> _createGroups(List<NotificationHistory> notifications) {
    final Map<String, List<NotificationHistory>> groupMap = {};

    for (final notification in notifications) {
      String groupKey;

      switch (_groupingMode) {
        case 'type':
          groupKey = notification.type.name;
          break;
        case 'date':
          final date = DateTime(
            notification.timestamp.year,
            notification.timestamp.month,
            notification.timestamp.day,
          );
          groupKey = date.toIso8601String().split('T')[0];
          break;
        case 'priority':
          groupKey = notification.priority.name;
          break;
        default:
          groupKey = 'all';
      }

      if (!groupMap.containsKey(groupKey)) {
        groupMap[groupKey] = [];
      }
      groupMap[groupKey]!.add(notification);
    }

    // Convert to NotificationGroup objects and sort
    final groups = groupMap.entries.map((entry) {
      final notifications = entry.value;
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return NotificationGroup(
        id: entry.key,
        type: _groupingMode == 'type' ? NotificationType.values.byName(entry.key) : NotificationType.system,
        title: _getGroupTitle(entry.key),
        notifications: notifications,
        lastUpdated: notifications.isNotEmpty ? notifications.first.timestamp : DateTime.now(),
        isExpanded: _expandedGroups.contains(entry.key),
      );
    }).toList();

    // Sort groups
    switch (_groupingMode) {
      case 'date':
        groups.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case 'priority':
        final priorityOrder = ['emergency', 'urgent', 'high', 'normal', 'low'];
        groups.sort((a, b) {
          final aIndex = priorityOrder.indexOf(a.id);
          final bIndex = priorityOrder.indexOf(b.id);
          return aIndex.compareTo(bIndex);
        });
        break;
      default:
        groups.sort((a, b) => b.unreadCount.compareTo(a.unreadCount));
    }

    return groups;
  }

  String _getGroupTitle(String groupKey) {
    switch (_groupingMode) {
      case 'type':
        return _getTypeDisplayName(groupKey);
      case 'date':
        return _getDateDisplayName(DateTime.parse(groupKey));
      case 'priority':
        return _getPriorityDisplayName(groupKey);
      default:
        return groupKey;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'family_invitation':
        return 'Inviti famiglia';
      case 'note_shared':
        return 'Note condivise';
      case 'note_comment':
        return 'Commenti';
      case 'note_updated':
        return 'Aggiornamenti note';
      case 'system':
        return 'Sistema';
      case 'emergency':
        return 'Emergenza';
      default:
        return 'Altro';
    }
  }

  String _getDateDisplayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(today)) {
      return 'Oggi';
    } else if (date.isAtSameMomentAs(yesterday)) {
      return 'Ieri';
    } else if (now.difference(date).inDays < 7) {
      final weekday = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
      return weekday[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getPriorityDisplayName(String priority) {
    switch (priority) {
      case 'low':
        return 'Priorità Bassa';
      case 'normal':
        return 'Priorità Normale';
      case 'high':
        return 'Priorità Alta';
      case 'urgent':
        return 'Priorità Urgente';
      case 'emergency':
        return 'Emergenza';
      default:
        return 'Priorità Normale';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_work_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna notifica da raggruppare',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(NotificationGroup group) {
    final isExpanded = _expandedGroups.contains(group.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2,
      child: Column(
        children: [
          // Group Header
          ListTile(
            leading: _getGroupIcon(group),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (group.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${group.totalCount} notifiche • ${_formatTimestamp(group.lastUpdated)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.unreadCount > 0)
                  IconButton(
                    icon: const Icon(Icons.mark_email_read, size: 20),
                    onPressed: () => _markGroupAsRead(group),
                    tooltip: 'Segna gruppo come letto',
                  ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => _toggleGroup(group.id),
                ),
              ],
            ),
            onTap: () => _toggleGroup(group.id),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1),
            ...group.notifications.map((notification) => _buildNotificationItem(notification)),
            
            // Group Actions
            if (group.notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (group.unreadCount > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.mark_email_read),
                        label: const Text('Segna tutte come lette'),
                        onPressed: () => _markGroupAsRead(group),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Elimina gruppo'),
                      onPressed: () => _deleteGroup(group),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _getGroupIcon(NotificationGroup group) {
    IconData iconData;
    Color iconColor;

    switch (_groupingMode) {
      case 'type':
        switch (group.id) {
          case 'family_invitation':
            iconData = Icons.family_restroom;
            iconColor = Colors.blue;
            break;
          case 'note_shared':
            iconData = Icons.share;
            iconColor = Colors.green;
            break;
          case 'note_comment':
            iconData = Icons.comment;
            iconColor = Colors.orange;
            break;
          case 'note_updated':
            iconData = Icons.update;
            iconColor = Colors.purple;
            break;
          case 'system':
            iconData = Icons.info;
            iconColor = Colors.grey;
            break;
          case 'emergency':
            iconData = Icons.emergency;
            iconColor = Colors.red;
            break;
          default:
            iconData = Icons.notifications;
            iconColor = Colors.blue;
        }
        break;
      case 'date':
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case 'priority':
        switch (group.id) {
          case 'emergency':
            iconData = Icons.emergency;
            iconColor = Colors.red[900]!;
            break;
          case 'urgent':
            iconData = Icons.priority_high;
            iconColor = Colors.red;
            break;
          case 'high':
            iconData = Icons.keyboard_arrow_up;
            iconColor = Colors.orange;
            break;
          case 'normal':
            iconData = Icons.remove;
            iconColor = Colors.blue;
            break;
          case 'low':
            iconData = Icons.keyboard_arrow_down;
            iconColor = Colors.grey;
            break;
          default:
            iconData = Icons.priority_high;
            iconColor = Colors.blue;
        }
        break;
      default:
        iconData = Icons.group_work;
        iconColor = Colors.blue;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildNotificationItem(NotificationHistory notification) {
    return Container(
      color: notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
      child: ListTile(
        dense: true,
        leading: Icon(
          notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
          size: 16,
          color: notification.isRead ? Colors.grey : Colors.blue,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.message,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTimestamp(notification.timestamp),
          style: const TextStyle(fontSize: 10),
        ),
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationHistoryProvider.notifier).markAsRead(notification.id);
          }
          if (notification.actionData != null) {
            _openNotification(notification);
          }
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}g';
    }
  }

  void _toggleGroup(String groupId) {
    setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
      }
    });
  }

  void _markGroupAsRead(NotificationGroup group) {
    for (final notification in group.notifications) {
      if (!notification.isRead) {
        ref.read(notificationHistoryProvider.notifier).markAsRead(notification.id);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${group.title} segnato come letto'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markAllGroupsAsRead(List<NotificationGroup> groups) {
    ref.read(notificationHistoryProvider.notifier).markAllAsRead();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutte le notifiche segnate come lette'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteGroup(NotificationGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina ${group.title}'),
        content: Text('Sei sicuro di voler eliminare tutte le notifiche in "${group.title}"? Questa azione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              for (final notification in group.notifications) {
                ref.read(notificationHistoryProvider.notifier).deleteNotification(notification.id);
              }
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${group.title} eliminato'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
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