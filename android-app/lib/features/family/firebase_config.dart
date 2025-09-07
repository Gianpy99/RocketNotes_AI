/// Firebase Configuration for Family Management Features
///
/// This file configures Firebase services specifically for family management:
/// - Authentication for family members
/// - Firestore collections for families, members, and shared notes
/// - Security rules for family data access
/// - Real-time listeners for family state synchronization

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase configuration options for family features
class FamilyFirebaseConfig {
  static const String familiesCollection = 'families';
  static const String familyMembersCollection = 'family_members';
  static const String familyInvitationsCollection = 'family_invitations';
  static const String sharedNotesCollection = 'shared_notes';
  static const String notePermissionsCollection = 'note_permissions';
  static const String auditLogsCollection = 'audit_logs';

  /// Initialize Firebase for family features
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        appId: String.fromEnvironment('FIREBASE_APP_ID'),
      ),
    );

    // Configure Firestore settings for family features
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Enable offline persistence for family data
    FirebaseFirestore.instance.enableNetwork();
  }

  /// Get Firestore instance configured for family features
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Get Auth instance for family member authentication
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Get reference to families collection
  static CollectionReference<Map<String, dynamic>> get familiesRef =>
      firestore.collection(familiesCollection);

  /// Get reference to family members collection
  static CollectionReference<Map<String, dynamic>> get familyMembersRef =>
      firestore.collection(familyMembersCollection);

  /// Get reference to family invitations collection
  static CollectionReference<Map<String, dynamic>> get familyInvitationsRef =>
      firestore.collection(familyInvitationsCollection);

  /// Get reference to shared notes collection
  static CollectionReference<Map<String, dynamic>> get sharedNotesRef =>
      firestore.collection(sharedNotesCollection);

  /// Get reference to note permissions collection
  static CollectionReference<Map<String, dynamic>> get notePermissionsRef =>
      firestore.collection(notePermissionsCollection);

  /// Get reference to audit logs collection
  static CollectionReference<Map<String, dynamic>> get auditLogsRef =>
      firestore.collection(auditLogsCollection);
}

/// Firestore Security Rules Template for Family Features
///
/// This should be applied to your Firestore security rules in Firebase Console
const String familyFirestoreSecurityRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isFamilyOwner(familyId) {
      return isAuthenticated() &&
             exists(/databases/\$(database)/documents/families/\$(familyId)) &&
             get(/databases/\$(database)/documents/families/\$(familyId)).data.ownerId == request.auth.uid;
    }

    function isFamilyMember(familyId) {
      return isAuthenticated() &&
             exists(/databases/\$(database)/documents/family_members/\$(familyId)_\$(request.auth.uid));
    }

    function hasPermission(familyId, permission) {
      return isAuthenticated() &&
             exists(/databases/\$(database)/documents/family_members/\$(familyId)_\$(request.auth.uid)) &&
             get(/databases/\$(database)/documents/family_members/\$(familyId)_\$(request.auth.uid)).data.permissions[permission] == true;
    }

    // Families collection
    match /families/{familyId} {
      allow read: if isFamilyMember(familyId) || isFamilyOwner(familyId);
      allow create: if isAuthenticated() &&
                       request.auth.uid == resource.data.ownerId;
      allow update: if isFamilyOwner(familyId);
      allow delete: if isFamilyOwner(familyId);
    }

    // Family members collection
    match /family_members/{memberId} {
      allow read: if isAuthenticated();
      allow write: if isFamilyOwner(memberId.split('_')[0]) ||
                      (isFamilyMember(memberId.split('_')[0]) &&
                       hasPermission(memberId.split('_')[0], 'canManageMembers'));
    }

    // Family invitations collection
    match /family_invitations/{invitationId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
                       hasPermission(resource.data.familyId, 'canInviteMembers');
      allow update: if isAuthenticated() &&
                       (resource.data.invitedBy == request.auth.uid ||
                        isFamilyOwner(resource.data.familyId));
      allow delete: if isAuthenticated() &&
                       (resource.data.invitedBy == request.auth.uid ||
                        isFamilyOwner(resource.data.familyId));
    }

    // Shared notes collection
    match /shared_notes/{sharedNoteId} {
      allow read: if isAuthenticated() &&
                     exists(/databases/\$(database)/documents/note_permissions/\$(sharedNoteId)_\$(request.auth.uid));
      allow create: if isAuthenticated() &&
                       hasPermission(resource.data.familyId, 'canShareNotes');
      allow update: if isAuthenticated() &&
                       (resource.data.sharedBy == request.auth.uid ||
                        exists(/databases/\$(database)/documents/note_permissions/\$(sharedNoteId)_\$(request.auth.uid)) &&
                        get(/databases/\$(database)/documents/note_permissions/\$(sharedNoteId)_\$(request.auth.uid)).data.canEdit == true);
      allow delete: if isAuthenticated() &&
                       (resource.data.sharedBy == request.auth.uid ||
                        isFamilyOwner(resource.data.familyId));
    }

    // Note permissions collection
    match /note_permissions/{permissionId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() &&
                      (permissionId.split('_')[1] == request.auth.uid ||
                       hasPermission(get(/databases/\$(database)/documents/shared_notes/\$(permissionId.split('_')[0])).data.familyId, 'canManagePermissions'));
    }

    // Audit logs collection
    match /audit_logs/{logId} {
      allow read: if isFamilyMember(resource.data.familyId);
      allow create: if isAuthenticated();
      allow update: if false; // Audit logs are immutable
      allow delete: if false; // Audit logs cannot be deleted
    }
  }
}
''';

/// Firebase Auth Custom Claims for Family Features
///
/// These claims should be set on user tokens for family-specific permissions
class FamilyAuthClaims {
  static const String familyId = 'familyId';
  static const String familyRole = 'familyRole';
  static const String permissions = 'permissions';

  /// Set custom claims for a family member
  static Future<void> setFamilyClaims(String uid, {
    required String familyId,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    // This would typically be done from a Cloud Function
    // For now, we'll use client-side claims (limited functionality)
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }
}
