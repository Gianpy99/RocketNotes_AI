import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shopping_collaboration_service.dart';

/// T093: Widget per mostrare collaborazione in tempo reale
class CollaborationIndicator extends ConsumerWidget {
  final String listId;
  final String? currentItemId;

  const CollaborationIndicator({
    super.key,
    required this.listId,
    this.currentItemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUsersAsync = ref.watch(activeUsersProvider(listId));
    final activeSessionsAsync = ref.watch(activeEditSessionsProvider(listId));

    return Column(
      children: [
        // Utenti attivi
        activeUsersAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (users) => users.isNotEmpty ? _buildActiveUsers(users) : const SizedBox.shrink(),
        ),
        
        // Indicatori di editing per l'elemento corrente
        if (currentItemId != null)
          activeSessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
            data: (sessions) {
              final session = sessions.where((s) => s.itemId == currentItemId).firstOrNull;
              return session != null ? _buildEditingIndicator(session) : const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildActiveUsers(List<CollaborationUser> users) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '${users.length} attivi',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          ...users.take(3).map((user) => Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Tooltip(
              message: '${user.name}${user.isTyping ? ' (sta scrivendo...)' : ''}',
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: user.isOnline ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: user.isTyping ? Colors.orange : 
                           user.isOnline ? Colors.green : Colors.grey,
                    width: user.isTyping ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    user.avatar,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          )),
          if (users.length > 3)
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(left: 2.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '+${users.length - 3}',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditingIndicator(ItemEditSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${session.userName} sta modificando...',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per mostrare eventi di collaborazione in tempo reale
class CollaborationFeed extends ConsumerWidget {
  final String listId;

  const CollaborationFeed({
    super.key,
    required this.listId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(collaborationEventsProvider(listId));

    return eventsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (event) => _buildEventNotification(context, event),
    );
  }

  Widget _buildEventNotification(BuildContext context, CollaborationEvent event) {
    final message = _getEventMessage(event);
    final icon = _getEventIcon(event);
    final color = _getEventColor(event);

    if (message.isEmpty) return const SizedBox.shrink();

    // Mostra snackbar per eventi importanti
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldShowSnackbar(event.type)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatTime(event.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getEventMessage(CollaborationEvent event) {
    switch (event.type) {
      case CollaborationEventType.userJoined:
        return '${event.userName} si è unito alla lista';
      case CollaborationEventType.userLeft:
        return '${event.userName} ha lasciato la lista';
      case CollaborationEventType.itemAdded:
        return '${event.userName} ha aggiunto "${event.item?.name}"';
      case CollaborationEventType.itemChanged:
        return '${event.userName} ha modificato "${event.item?.name}"';
      case CollaborationEventType.itemRemoved:
        return '${event.userName} ha rimosso un elemento';
      case CollaborationEventType.itemEditStarted:
        return '${event.userName} sta modificando un elemento';
      case CollaborationEventType.itemEditEnded:
        return '${event.userName} ha finito di modificare';
      case CollaborationEventType.userStartedTyping:
        return '${event.userName} sta scrivendo...';
      case CollaborationEventType.userStoppedTyping:
        return '';
      case CollaborationEventType.listChanged:
        return '${event.userName} ha modificato la lista';
    }
  }

  IconData _getEventIcon(CollaborationEvent event) {
    switch (event.type) {
      case CollaborationEventType.userJoined:
        return Icons.person_add;
      case CollaborationEventType.userLeft:
        return Icons.person_remove;
      case CollaborationEventType.itemAdded:
        return Icons.add_circle;
      case CollaborationEventType.itemChanged:
        return Icons.edit;
      case CollaborationEventType.itemRemoved:
        return Icons.remove_circle;
      case CollaborationEventType.itemEditStarted:
      case CollaborationEventType.itemEditEnded:
        return Icons.edit_note;
      case CollaborationEventType.userStartedTyping:
      case CollaborationEventType.userStoppedTyping:
        return Icons.keyboard;
      case CollaborationEventType.listChanged:
        return Icons.list_alt;
    }
  }

  Color _getEventColor(CollaborationEvent event) {
    switch (event.type) {
      case CollaborationEventType.userJoined:
        return Colors.green;
      case CollaborationEventType.userLeft:
        return Colors.orange;
      case CollaborationEventType.itemAdded:
        return Colors.blue;
      case CollaborationEventType.itemChanged:
        return Colors.purple;
      case CollaborationEventType.itemRemoved:
        return Colors.red;
      case CollaborationEventType.itemEditStarted:
      case CollaborationEventType.itemEditEnded:
        return Colors.orange;
      case CollaborationEventType.userStartedTyping:
      case CollaborationEventType.userStoppedTyping:
        return Colors.grey;
      case CollaborationEventType.listChanged:
        return Colors.indigo;
    }
  }

  bool _shouldShowSnackbar(CollaborationEventType type) {
    switch (type) {
      case CollaborationEventType.userJoined:
      case CollaborationEventType.userLeft:
      case CollaborationEventType.itemAdded:
      case CollaborationEventType.itemRemoved:
        return true;
      default:
        return false;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes == 0) {
      return 'ora';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m fa';
    } else {
      return '${diff.inHours}h fa';
    }
  }
}

/// Widget per avatar utenti attivi con animazioni
class AnimatedUserAvatars extends ConsumerWidget {
  final String listId;
  final int maxAvatars;

  const AnimatedUserAvatars({
    super.key,
    required this.listId,
    this.maxAvatars = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUsersAsync = ref.watch(activeUsersProvider(listId));

    return activeUsersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (users) {
        if (users.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (users.length > maxAvatars) ? maxAvatars + 1 : users.length,
            itemBuilder: (context, index) {
              if (index == maxAvatars && users.length > maxAvatars) {
                return _buildMoreIndicator(users.length - maxAvatars);
              }
              
              return _buildAnimatedAvatar(users[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAvatar(CollaborationUser user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: '${user.name}${user.isTyping ? ' (sta scrivendo...)' : ''}',
        child: Stack(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: user.isOnline ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: user.isTyping ? Colors.orange : 
                         user.isOnline ? Colors.green : Colors.grey,
                  width: user.isTyping ? 3 : 2,
                ),
              ),
              child: Center(
                child: Text(
                  user.avatar,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (user.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            if (user.isTyping)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(int count) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}