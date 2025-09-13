import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';

/// T093: Real-time Shopping List Collaboration Service
class ShoppingCollaborationService {
  static final ShoppingCollaborationService _instance = ShoppingCollaborationService._internal();
  static ShoppingCollaborationService get instance => _instance;
  ShoppingCollaborationService._internal();

  final StreamController<CollaborationEvent> _eventStreamController = StreamController.broadcast();
  final Map<String, List<CollaborationUser>> _activeUsers = {};
  final Map<String, List<ItemEditSession>> _activeSessions = {};
  
  Stream<CollaborationEvent> get eventStream => _eventStreamController.stream;

  /// Inizializza il servizio
  Future<void> initialize() async {
    debugPrint('✅ Shopping Collaboration Service initialized');
  }

  /// Entra in una sessione di collaborazione per una lista
  Future<void> joinListSession(String listId, String userId, String userName) async {
    try {
      final user = CollaborationUser(
        id: userId,
        name: userName,
        avatar: _generateAvatar(userName),
        joinedAt: DateTime.now(),
        isOnline: true,
      );

      _activeUsers.putIfAbsent(listId, () => []);
      
      // Rimuovi l'utente se già presente e aggiungilo aggiornato
      _activeUsers[listId]!.removeWhere((u) => u.id == userId);
      _activeUsers[listId]!.add(user);

      // Notifica agli altri utenti
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.userJoined,
        listId: listId,
        user: user,
        timestamp: DateTime.now(),
      ));

      debugPrint('👥 User $userName joined list $listId');
    } catch (e) {
      debugPrint('❌ Error joining session: $e');
    }
  }

  /// Lascia una sessione di collaborazione
  Future<void> leaveListSession(String listId, String userId) async {
    try {
      _activeUsers[listId]?.removeWhere((u) => u.id == userId);
      
      // Rimuovi le sessioni di editing attive dell'utente
      _activeSessions[listId]?.removeWhere((s) => s.userId == userId);

      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.userLeft,
        listId: listId,
        userId: userId,
        timestamp: DateTime.now(),
      ));

      debugPrint('👋 User $userId left list $listId');
    } catch (e) {
      debugPrint('❌ Error leaving session: $e');
    }
  }

  /// Inizia editing di un elemento
  Future<void> startItemEdit(String listId, String itemId, String userId, String userName) async {
    try {
      final session = ItemEditSession(
        itemId: itemId,
        userId: userId,
        userName: userName,
        startedAt: DateTime.now(),
      );

      _activeSessions.putIfAbsent(listId, () => []);
      
      // Rimuovi sessioni precedenti dello stesso elemento
      _activeSessions[listId]!.removeWhere((s) => s.itemId == itemId);
      _activeSessions[listId]!.add(session);

      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.itemEditStarted,
        listId: listId,
        itemId: itemId,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
      ));

      debugPrint('✏️ User $userName started editing item $itemId');
    } catch (e) {
      debugPrint('❌ Error starting edit: $e');
    }
  }

  /// Termina editing di un elemento
  Future<void> endItemEdit(String listId, String itemId, String userId) async {
    try {
      _activeSessions[listId]?.removeWhere((s) => s.itemId == itemId && s.userId == userId);

      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.itemEditEnded,
        listId: listId,
        itemId: itemId,
        userId: userId,
        timestamp: DateTime.now(),
      ));

      debugPrint('📝 User $userId finished editing item $itemId');
    } catch (e) {
      debugPrint('❌ Error ending edit: $e');
    }
  }

  /// Notifica modifica elemento
  Future<void> notifyItemChanged(String listId, ShoppingItem item, String userId, String userName) async {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.itemChanged,
        listId: listId,
        itemId: item.id,
        userId: userId,
        userName: userName,
        item: item,
        timestamp: DateTime.now(),
      ));

      debugPrint('🔄 Item ${item.name} changed by $userName');
    } catch (e) {
      debugPrint('❌ Error notifying change: $e');
    }
  }

  /// Notifica aggiunta elemento
  Future<void> notifyItemAdded(String listId, ShoppingItem item, String userId, String userName) async {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.itemAdded,
        listId: listId,
        itemId: item.id,
        userId: userId,
        userName: userName,
        item: item,
        timestamp: DateTime.now(),
      ));

      debugPrint('➕ Item ${item.name} added by $userName');
    } catch (e) {
      debugPrint('❌ Error notifying addition: $e');
    }
  }

  /// Notifica rimozione elemento
  Future<void> notifyItemRemoved(String listId, String itemId, String userId, String userName) async {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.itemRemoved,
        listId: listId,
        itemId: itemId,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
      ));

      debugPrint('🗑️ Item $itemId removed by $userName');
    } catch (e) {
      debugPrint('❌ Error notifying removal: $e');
    }
  }

  /// Ottiene utenti attivi in una lista
  List<CollaborationUser> getActiveUsers(String listId) {
    return _activeUsers[listId] ?? [];
  }

  /// Ottiene sessioni di editing attive
  List<ItemEditSession> getActiveSessions(String listId) {
    return _activeSessions[listId] ?? [];
  }

  /// Verifica se un elemento è in editing
  bool isItemBeingEdited(String listId, String itemId) {
    return _activeSessions[listId]?.any((s) => s.itemId == itemId) ?? false;
  }

  /// Ottiene chi sta editando un elemento
  ItemEditSession? getItemEditSession(String listId, String itemId) {
    return _activeSessions[listId]?.where((s) => s.itemId == itemId).firstOrNull;
  }

  /// Simula presenza/typing indicator
  Future<void> notifyUserTyping(String listId, String userId, String userName, bool isTyping) async {
    try {
      _emitEvent(CollaborationEvent(
        type: isTyping ? CollaborationEventType.userStartedTyping : CollaborationEventType.userStoppedTyping,
        listId: listId,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('❌ Error notifying typing: $e');
    }
  }

  void _emitEvent(CollaborationEvent event) {
    if (!_eventStreamController.isClosed) {
      _eventStreamController.add(event);
    }
  }

  String _generateAvatar(String name) {
    final avatars = ['👤', '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '👨‍🎓', '👩‍🎓'];
    return avatars[name.hashCode % avatars.length];
  }

  void dispose() {
    _eventStreamController.close();
  }
}

/// Modello utente collaborazione
class CollaborationUser {
  final String id;
  final String name;
  final String avatar;
  final DateTime joinedAt;
  final bool isOnline;
  final bool isTyping;

  CollaborationUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.joinedAt,
    required this.isOnline,
    this.isTyping = false,
  });

  CollaborationUser copyWith({
    String? id,
    String? name,
    String? avatar,
    DateTime? joinedAt,
    bool? isOnline,
    bool? isTyping,
  }) {
    return CollaborationUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      joinedAt: joinedAt ?? this.joinedAt,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

/// Sessione di editing elemento
class ItemEditSession {
  final String itemId;
  final String userId;
  final String userName;
  final DateTime startedAt;

  ItemEditSession({
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.startedAt,
  });

  Duration get duration => DateTime.now().difference(startedAt);
}

/// Eventi di collaborazione
class CollaborationEvent {
  final CollaborationEventType type;
  final String listId;
  final String? itemId;
  final String? userId;
  final String? userName;
  final CollaborationUser? user;
  final ShoppingItem? item;
  final DateTime timestamp;

  CollaborationEvent({
    required this.type,
    required this.listId,
    this.itemId,
    this.userId,
    this.userName,
    this.user,
    this.item,
    required this.timestamp,
  });
}

/// Tipi di eventi collaborazione
enum CollaborationEventType {
  userJoined,
  userLeft,
  userStartedTyping,
  userStoppedTyping,
  itemEditStarted,
  itemEditEnded,
  itemChanged,
  itemAdded,
  itemRemoved,
  listChanged,
}

/// Provider per collaboration service
final shoppingCollaborationServiceProvider = Provider<ShoppingCollaborationService>((ref) {
  return ShoppingCollaborationService.instance;
});

/// Provider per utenti attivi in una lista
final activeUsersProvider = StreamProvider.family<List<CollaborationUser>, String>((ref, listId) async* {
  final service = ref.read(shoppingCollaborationServiceProvider);
  
  yield service.getActiveUsers(listId);
  
  await for (final event in service.eventStream) {
    if (event.listId == listId) {
      switch (event.type) {
        case CollaborationEventType.userJoined:
        case CollaborationEventType.userLeft:
        case CollaborationEventType.userStartedTyping:
        case CollaborationEventType.userStoppedTyping:
          yield service.getActiveUsers(listId);
          break;
        default:
          break;
      }
    }
  }
});

/// Provider per eventi di collaborazione
final collaborationEventsProvider = StreamProvider.family<CollaborationEvent, String>((ref, listId) {
  final service = ref.read(shoppingCollaborationServiceProvider);
  return service.eventStream.where((event) => event.listId == listId);
});

/// Provider per sessioni di editing attive
final activeEditSessionsProvider = StreamProvider.family<List<ItemEditSession>, String>((ref, listId) async* {
  final service = ref.read(shoppingCollaborationServiceProvider);
  
  yield service.getActiveSessions(listId);
  
  await for (final event in service.eventStream) {
    if (event.listId == listId) {
      switch (event.type) {
        case CollaborationEventType.itemEditStarted:
        case CollaborationEventType.itemEditEnded:
          yield service.getActiveSessions(listId);
          break;
        default:
          break;
      }
    }
  }
});