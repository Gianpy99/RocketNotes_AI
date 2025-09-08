// lib/core/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../../data/models/note_model.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/family_member_model.dart';

class FirebaseService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get _authInstance {
    _auth ??= FirebaseConfig.isConfigured ? FirebaseConfig.auth : null;
    if (_auth == null) throw Exception('Firebase not configured');
    return _auth!;
  }

  FirebaseFirestore get _firestoreInstance {
    _firestore ??= FirebaseConfig.isConfigured ? FirebaseConfig.firestore : null;
    if (_firestore == null) throw Exception('Firebase not configured');
    return _firestore!;
  }

  // Auth methods
  Future<UserCredential> signUp(String email, String password) async {
    return await _authInstance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _authInstance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _authInstance.signOut();
  }

  User? get currentUser => _authInstance.currentUser;

  // Notes CRUD operations
  Future<List<NoteModel>> getNotes({String? userId}) async {
    final userIdToUse = userId ?? currentUser?.uid;
    if (userIdToUse == null) {
      throw Exception('User not authenticated');
    }
    
    final querySnapshot = await _firestoreInstance
        .collection('notes')
        .where('user_id', isEqualTo: userIdToUse)
        .orderBy('updated_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => NoteModel.fromJson(doc.data()))
        .toList();
  }

  Future<NoteModel> createNote(NoteModel note) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final noteData = {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'mode': note.mode,
      'user_id': userId,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
      'tags': note.tags,
      'ai_summary': note.aiSummary ?? '',
      'attachments': note.attachments,
      'nfc_tag_id': note.nfcTagId ?? '',
      'is_favorite': note.isFavorite,
    };

    await _firestoreInstance.collection('notes').doc(note.id).set(noteData);
    return note;
  }

  Future<NoteModel> updateNote(NoteModel note) async {
    final noteData = {
      'title': note.title,
      'content': note.content,
      'mode': note.mode,
      'updated_at': note.updatedAt.toIso8601String(),
      'tags': note.tags,
      'ai_summary': note.aiSummary,
      'attachments': note.attachments,
      'nfc_tag_id': note.nfcTagId,
      'is_favorite': note.isFavorite,
    };

    await _firestoreInstance.collection('notes').doc(note.id).update(noteData);
    return note;
  }

  Future<void> deleteNote(String noteId) async {
    await _firestoreInstance.collection('notes').doc(noteId).delete();
  }  // Family members CRUD operations
  Future<List<FamilyMember>> getFamilyMembers() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final querySnapshot = await _firestoreInstance
        .collection('family_members')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => FamilyMember.fromJson(doc.data()))
        .toList();
  }

  Future<FamilyMember> createFamilyMember(FamilyMember member) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final memberData = {
      'id': member.id,
      'name': member.name,
      'avatar_path': member.avatarPath ?? '',
      'relationship': member.relationship,
      'birth_date': member.birthDate?.toIso8601String(),
      'phone_number': member.phoneNumber ?? '',
      'is_emergency_contact': member.isEmergencyContact,
      'permissions': member.permissions,
      'user_id': userId,
      'created_at': member.createdAt.toIso8601String(),
      'updated_at': member.updatedAt.toIso8601String(),
    };

    await _firestoreInstance.collection('family_members').doc(member.id).set(memberData);
    return member;
  }

  Future<FamilyMember> updateFamilyMember(FamilyMember member) async {
    final memberData = {
      'name': member.name,
      'avatar_path': member.avatarPath,
      'relationship': member.relationship,
      'birth_date': member.birthDate?.toIso8601String(),
      'phone_number': member.phoneNumber,
      'is_emergency_contact': member.isEmergencyContact,
      'permissions': member.permissions,
      'updated_at': member.updatedAt.toIso8601String(),
    };

    await _firestoreInstance.collection('family_members').doc(member.id).update(memberData);
    return member;
  }

  Future<void> deleteFamilyMember(String memberId) async {
    await _firestoreInstance.collection('family_members').doc(memberId).delete();
  }

  // User profile operations
  Future<UserProfile> getUserProfile() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docSnapshot = await _firestoreInstance.collection('user_profiles').doc(userId).get();

    if (!docSnapshot.exists) {
      throw Exception('User profile not found');
    }

    return UserProfile.fromJson(docSnapshot.data()!);
  }

  Future<UserProfile> createUserProfile(UserProfile profile) async {
    final userId = currentUser?.uid ?? profile.userId;

    final profileData = {
      'user_id': userId,
      'display_name': profile.displayName,
      'email': profile.email,
      'is_anonymous': profile.isAnonymous,
      'last_sync_time': profile.lastSyncTime.toIso8601String(),
      'sync_settings': profile.syncSettings,
      'profile_image_url': profile.profileImageUrl ?? '',
      'created_at': profile.createdAt.toIso8601String(),
      'updated_at': profile.updatedAt.toIso8601String(),
      'cloud_sync_enabled': profile.cloudSyncEnabled,
      'cloud_provider': profile.cloudProvider ?? 'firebase',
    };

    await _firestoreInstance.collection('user_profiles').doc(userId).set(profileData);
    return profile;
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    final profileData = {
      'display_name': profile.displayName,
      'email': profile.email,
      'is_anonymous': profile.isAnonymous,
      'last_sync_time': profile.lastSyncTime.toIso8601String(),
      'sync_settings': profile.syncSettings,
      'profile_image_url': profile.profileImageUrl,
      'updated_at': profile.updatedAt.toIso8601String(),
      'cloud_sync_enabled': profile.cloudSyncEnabled,
      'cloud_provider': profile.cloudProvider,
    };

    await _firestoreInstance.collection('user_profiles').doc(profile.userId).update(profileData);
    return profile;
  }

  /// Gets a user profile by user ID
  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final docSnapshot = await _firestoreInstance.collection('user_profiles').doc(userId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return UserProfile.fromJson(docSnapshot.data()!);
    } catch (e) {
      // Return null if there's an error (user not found, network issues, etc.)
      return null;
    }
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> subscribeToNotes() {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestoreInstance
        .collection('notes')
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> subscribeToFamilyMembers() {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestoreInstance
        .collection('family_members')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
