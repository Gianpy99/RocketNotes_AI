import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';

/// T092: Family Sharing Service per Shopping Lists
class FamilyShoppingService {
  static final FamilyShoppingService _instance = FamilyShoppingService._internal();
  static FamilyShoppingService get instance => _instance;
  FamilyShoppingService._internal();

  final List<FamilyMember> _familyMembers = [];
  final Map<String, List<String>> _listPermissions = {};

  /// Inizializza il servizio con i membri della famiglia demo
  Future<void> initialize() async {
    _familyMembers.clear();
    _familyMembers.addAll([
      FamilyMember(
        id: 'family1',
        name: 'Mario Rossi',
        email: 'mario@example.com',
        role: FamilyRole.parent,
        avatar: '👨',
      ),
      FamilyMember(
        id: 'family2',
        name: 'Anna Rossi',
        email: 'anna@example.com',
        role: FamilyRole.parent,
        avatar: '👩',
      ),
      FamilyMember(
        id: 'family3',
        name: 'Luca Rossi',
        email: 'luca@example.com',
        role: FamilyRole.child,
        avatar: '👦',
      ),
    ]);
    debugPrint('✅ Family Shopping Service initialized with ${_familyMembers.length} members');
  }

  /// Ottiene tutti i membri della famiglia
  List<FamilyMember> getFamilyMembers() => List.unmodifiable(_familyMembers);

  /// Condivide una lista con specifici membri della famiglia
  Future<bool> shareShoppingList(String listId, List<String> memberIds, SharePermission permission) async {
    try {
      // Simula API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _listPermissions[listId] = memberIds;
      debugPrint('📤 Lista $listId condivisa con ${memberIds.length} membri');
      return true;
    } catch (e) {
      debugPrint('❌ Errore condivisione lista: $e');
      return false;
    }
  }

  /// Rimuove la condivisione di una lista
  Future<bool> unshareShoppingList(String listId, List<String> memberIds) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final currentShared = _listPermissions[listId] ?? [];
      final updated = currentShared.where((id) => !memberIds.contains(id)).toList();
      
      if (updated.isEmpty) {
        _listPermissions.remove(listId);
      } else {
        _listPermissions[listId] = updated;
      }
      
      debugPrint('🚫 Rimossa condivisione lista $listId per ${memberIds.length} membri');
      return true;
    } catch (e) {
      debugPrint('❌ Errore rimozione condivisione: $e');
      return false;
    }
  }

  /// Ottiene i membri con cui è condivisa una lista
  List<String> getSharedMembers(String listId) {
    return _listPermissions[listId] ?? [];
  }

  /// Verifica se un membro ha accesso a una lista
  bool hasAccess(String listId, String memberId) {
    return _listPermissions[listId]?.contains(memberId) ?? false;
  }

  /// Invita un nuovo membro via email
  Future<bool> inviteMemberByEmail(String email, String listId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('📧 Invito inviato a $email per lista $listId');
      return true;
    } catch (e) {
      debugPrint('❌ Errore invio invito: $e');
      return false;
    }
  }

  /// Sincronizza le modifiche di una lista condivisa
  Future<ShoppingList?> syncSharedList(String listId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('🔄 Lista $listId sincronizzata');
      
      // Simula aggiornamenti da altri membri
      return null; // La lista sincronizzata sarà gestita dal provider
    } catch (e) {
      debugPrint('❌ Errore sincronizzazione: $e');
      return null;
    }
  }
}

/// Modello per membro della famiglia
class FamilyMember {
  final String id;
  final String name;
  final String email;
  final FamilyRole role;
  final String avatar;
  final DateTime? lastActive;

  FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
    this.lastActive,
  });

  String get displayName => name;
  String get initials => name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
  
  bool get isParent => role == FamilyRole.parent;
  bool get isChild => role == FamilyRole.child;
}

/// Ruoli famiglia
enum FamilyRole {
  parent,
  child,
  guest,
}

/// Permessi di condivisione
enum SharePermission {
  view,      // Solo visualizzazione
  edit,      // Modifica elementi
  manage,    // Gestione completa (aggiungere/rimuovere membri)
}

/// Provider per family shopping service
final familyShoppingServiceProvider = Provider<FamilyShoppingService>((ref) {
  return FamilyShoppingService.instance;
});

/// Provider per membri famiglia
final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final service = ref.read(familyShoppingServiceProvider);
  await service.initialize();
  return service.getFamilyMembers();
});

/// Provider per membri condivisi di una lista specifica
final sharedMembersProvider = Provider.family<List<String>, String>((ref, listId) {
  final service = ref.read(familyShoppingServiceProvider);
  return service.getSharedMembers(listId);
});

/// State notifier per gestire la condivisione
class SharingStateNotifier extends StateNotifier<SharingState> {
  final FamilyShoppingService _service;

  SharingStateNotifier(this._service) : super(const SharingState());

  /// Condivide una lista con membri selezionati
  Future<void> shareList(String listId, List<String> memberIds, SharePermission permission) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final success = await _service.shareShoppingList(listId, memberIds, permission);
    
    if (success) {
      state = state.copyWith(
        isLoading: false,
        lastSharedListId: listId,
        lastSharedMembers: memberIds,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore durante la condivisione',
      );
    }
  }

  /// Rimuove condivisione
  Future<void> unshareList(String listId, List<String> memberIds) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final success = await _service.unshareShoppingList(listId, memberIds);
    
    state = state.copyWith(
      isLoading: false,
      error: success ? null : 'Errore rimozione condivisione',
    );
  }

  /// Invita membro via email
  Future<void> inviteMember(String email, String listId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final success = await _service.inviteMemberByEmail(email, listId);
    
    state = state.copyWith(
      isLoading: false,
      error: success ? null : 'Errore invio invito',
    );
  }

  /// Reset stato
  void reset() {
    state = const SharingState();
  }
}

/// Stato per condivisione
class SharingState {
  final bool isLoading;
  final String? error;
  final String? lastSharedListId;
  final List<String> lastSharedMembers;

  const SharingState({
    this.isLoading = false,
    this.error,
    this.lastSharedListId,
    this.lastSharedMembers = const [],
  });

  SharingState copyWith({
    bool? isLoading,
    String? error,
    String? lastSharedListId,
    List<String>? lastSharedMembers,
  }) {
    return SharingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSharedListId: lastSharedListId ?? this.lastSharedListId,
      lastSharedMembers: lastSharedMembers ?? this.lastSharedMembers,
    );
  }
}

/// Provider per sharing state
final sharingStateProvider = StateNotifierProvider<SharingStateNotifier, SharingState>((ref) {
  final service = ref.read(familyShoppingServiceProvider);
  return SharingStateNotifier(service);
});