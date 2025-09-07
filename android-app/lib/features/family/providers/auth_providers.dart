import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_config.dart';

/// Provider for family-aware authentication state
final familyAuthStateProvider = StreamProvider<FamilyAuthState>((ref) {
  return FamilyFirebaseConfig.auth.authStateChanges().asyncMap((user) async {
    if (user == null) {
      return FamilyAuthState.unauthenticated();
    }

    try {
      // Get user's family information
      final userDoc = await FamilyFirebaseConfig.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final familyId = userDoc.data()?['familyId'] as String?;
      final familyRole = userDoc.data()?['familyRole'] as String?;

      if (familyId != null) {
        // Get family member details
        final memberDoc = await FamilyFirebaseConfig.firestore
            .collection('family_members')
            .doc('${familyId}_${user.uid}')
            .get();

        final permissions = Map<String, bool>.from(
          memberDoc.data()?['permissions'] ?? {},
        );

        return FamilyAuthState.authenticatedWithFamily(
          user: user,
          familyId: familyId,
          role: familyRole ?? 'member',
          permissions: permissions,
        );
      } else {
        return FamilyAuthState.authenticatedWithoutFamily(user: user);
      }
    } catch (error) {
      return FamilyAuthState.error(error: error.toString());
    }
  });
});

/// Provider for current family authentication context
final currentFamilyAuthProvider = Provider<FamilyAuthState>((ref) {
  final authState = ref.watch(familyAuthStateProvider);
  return authState.maybeWhen(
    data: (state) => state,
    orElse: () => FamilyAuthState.unauthenticated(),
  );
});

/// Provider for authentication guards
final authGuardProvider = Provider<AuthGuard>((ref) {
  final authState = ref.watch(currentFamilyAuthProvider);
  return AuthGuard(authState);
});

/// Family authentication state
class FamilyAuthState {
  final bool isAuthenticated;
  final User? user;
  final String? familyId;
  final String? role;
  final Map<String, bool> permissions;
  final String? error;

  FamilyAuthState._({
    required this.isAuthenticated,
    this.user,
    this.familyId,
    this.role,
    this.permissions = const {},
    this.error,
  });

  factory FamilyAuthState.unauthenticated() => FamilyAuthState._(
    isAuthenticated: false,
  );

  factory FamilyAuthState.authenticatedWithoutFamily({required User user}) => FamilyAuthState._(
    isAuthenticated: true,
    user: user,
  );

  factory FamilyAuthState.authenticatedWithFamily({
    required User user,
    required String familyId,
    required String role,
    required Map<String, bool> permissions,
  }) => FamilyAuthState._(
    isAuthenticated: true,
    user: user,
    familyId: familyId,
    role: role,
    permissions: permissions,
  );

  factory FamilyAuthState.error({required String error}) => FamilyAuthState._(
    isAuthenticated: false,
    error: error,
  );

  bool get hasFamily => familyId != null;
  bool get isFamilyOwner => role == 'owner';
  bool get isFamilyAdmin => role == 'admin' || isFamilyOwner;

  bool hasPermission(String permission) => permissions[permission] ?? false;
}

/// Authentication guard for protecting family operations
class AuthGuard {
  final FamilyAuthState authState;

  AuthGuard(this.authState);

  /// Check if user can perform family operations
  bool canAccessFamilyFeatures() => authState.isAuthenticated;

  /// Check if user has a family
  bool hasFamily() => authState.hasFamily;

  /// Check if user can invite members
  bool canInviteMembers() => authState.hasPermission('canInviteMembers');

  /// Check if user can manage members
  bool canManageMembers() => authState.hasPermission('canManageMembers');

  /// Check if user can share notes
  bool canShareNotes() => authState.hasPermission('canShareNotes');

  /// Check if user can manage permissions
  bool canManagePermissions() => authState.hasPermission('canManagePermissions');

  /// Check if user can view audit logs
  bool canViewAuditLogs() => authState.hasPermission('canViewAuditLogs');

  /// Check if user is family owner
  bool isOwner() => authState.isFamilyOwner;

  /// Check if user is family admin
  bool isAdmin() => authState.isFamilyAdmin;

  /// Get user's family ID
  String? get familyId => authState.familyId;

  /// Get user's role
  String? get role => authState.role;

  /// Get current user
  User? get user => authState.user;

  /// Throw error if user is not authenticated
  void requireAuthentication() {
    if (!authState.isAuthenticated) {
      throw Exception('User must be authenticated');
    }
  }

  /// Throw error if user has no family
  void requireFamily() {
    requireAuthentication();
    if (!authState.hasFamily) {
      throw Exception('User must be part of a family');
    }
  }

  /// Throw error if user lacks specific permission
  void requirePermission(String permission) {
    requireFamily();
    if (!authState.hasPermission(permission)) {
      throw Exception('User lacks permission: $permission');
    }
  }

  /// Throw error if user is not family owner
  void requireOwner() {
    requireFamily();
    if (!authState.isFamilyOwner) {
      throw Exception('User must be family owner');
    }
  }

  /// Throw error if user is not family admin
  void requireAdmin() {
    requireFamily();
    if (!authState.isFamilyAdmin) {
      throw Exception('User must be family admin');
    }
  }
}

/// State notifier for authentication operations
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      await FamilyFirebaseConfig.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      await FamilyFirebaseConfig.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await FamilyFirebaseConfig.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    try {
      await FamilyFirebaseConfig.auth.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});
