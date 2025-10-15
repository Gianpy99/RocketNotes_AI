// ==========================================
// lib/core/services/family_service.dart
// ==========================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/family_member_model.dart';
import '../../data/models/shared_notebook_model.dart';

// Implementazione servizio famiglia completata

class FamilyService {
  static const String familyMembersBox = 'familyMembers';
  static const String sharedNotebooksBox = 'sharedNotebooks';

  static FamilyService? _instance;
  static FamilyService get instance {
    _instance ??= FamilyService._();
    return _instance!;
  }

  FamilyService._();

  Box<FamilyMember>? _familyMembersBox;
  Box<SharedNotebook>? _sharedNotebooksBox;

  Future<void> initialize() async {
    try {
      // Open family members box
      _familyMembersBox = await Hive.openBox<FamilyMember>(familyMembersBox);

      // Open shared notebooks box
      _sharedNotebooksBox = await Hive.openBox<SharedNotebook>(sharedNotebooksBox);

      debugPrint('✅ Family service initialized successfully');

      // Create default family member if none exists, or update if name is "Me"
      if (_familyMembersBox!.isEmpty) {
        await _createDefaultFamilyMember();
      } else {
        // Update existing member if name is still "Me"
        final existingMember = _familyMembersBox!.get('default_user');
        if (existingMember != null && existingMember.name == 'Me') {
          await _updateDefaultFamilyMemberName();
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing family service: $e');
      rethrow;
    }
  }

  Future<void> _createDefaultFamilyMember() async {
    // Get display name from Firebase Auth if available
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Me';
    
    final defaultMember = FamilyMember(
      id: 'default_user',
      name: displayName,
      relationship: 'self',
      permissions: ['read', 'write', 'admin'],
    );

    await _familyMembersBox!.put(defaultMember.id, defaultMember);
    debugPrint('✅ Created default family member: $displayName');
  }

  Future<void> _updateDefaultFamilyMemberName() async {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Me';
    
    final existingMember = _familyMembersBox!.get('default_user');
    if (existingMember != null) {
      final updatedMember = existingMember.copyWith(name: displayName);
      await _familyMembersBox!.put('default_user', updatedMember);
      debugPrint('✅ Updated default family member name to: $displayName');
    }
  }

  // Family Member Management
  Future<List<FamilyMember>> getAllFamilyMembers() async {
    return _familyMembersBox?.values.toList() ?? [];
  }

  Future<FamilyMember?> getFamilyMember(String id) async {
    return _familyMembersBox?.get(id);
  }

  Future<void> addFamilyMember(FamilyMember member) async {
    await _familyMembersBox?.put(member.id, member);
    debugPrint('✅ Added family member: ${member.name}');
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    final updatedMember = member.copyWith(updatedAt: DateTime.now());
    await _familyMembersBox?.put(member.id, updatedMember);
    debugPrint('✅ Updated family member: ${member.name}');
  }

  Future<void> removeFamilyMember(String id) async {
    await _familyMembersBox?.delete(id);
    debugPrint('✅ Removed family member: $id');
  }

  // Shared Notebook Management
  Future<List<SharedNotebook>> getAllSharedNotebooks() async {
    return _sharedNotebooksBox?.values.toList() ?? [];
  }

  Future<SharedNotebook?> getSharedNotebook(String id) async {
    return _sharedNotebooksBox?.get(id);
  }

  Future<void> addSharedNotebook(SharedNotebook notebook) async {
    await _sharedNotebooksBox?.put(notebook.id, notebook);
    debugPrint('✅ Added shared notebook: ${notebook.name}');
  }

  Future<void> updateSharedNotebook(SharedNotebook notebook) async {
    final updatedNotebook = notebook.copyWith(updatedAt: DateTime.now());
    await _sharedNotebooksBox?.put(notebook.id, updatedNotebook);
    debugPrint('✅ Updated shared notebook: ${notebook.name}');
  }

  Future<void> removeSharedNotebook(String id) async {
    await _sharedNotebooksBox?.delete(id);
    debugPrint('✅ Removed shared notebook: $id');
  }

  // Permission Checking
  Future<bool> hasPermission(String memberId, String notebookId, String permission) async {
    final notebook = await getSharedNotebook(notebookId);
    return notebook?.hasPermission(memberId, permission) ?? false;
  }

  // Utility Methods
  Future<FamilyMember?> getCurrentUser() async {
    final members = await getAllFamilyMembers();
    return members.isNotEmpty ? members.first : null;
  }

  Future<List<SharedNotebook>> getNotebooksForMember(String memberId) async {
    final allNotebooks = await getAllSharedNotebooks();
    return allNotebooks.where((notebook) => notebook.memberIds.contains(memberId)).toList();
  }

  // Data Export/Import for Backup
  Future<String> exportFamilyData() async {
    final members = await getAllFamilyMembers();
    final notebooks = await getAllSharedNotebooks();

    final data = {
      'familyMembers': members.map((m) => m.toJson()).toList(),
      'sharedNotebooks': notebooks.map((n) => n.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  Future<void> importFamilyData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // Import family members
      final membersData = data['familyMembers'] as List?;
      if (membersData != null) {
        for (final memberData in membersData) {
          final member = FamilyMember.fromJson(memberData);
          await addFamilyMember(member);
        }
      }

      // Import shared notebooks
      final notebooksData = data['sharedNotebooks'] as List?;
      if (notebooksData != null) {
        for (final notebookData in notebooksData) {
          final notebook = SharedNotebook.fromJson(notebookData);
          await addSharedNotebook(notebook);
        }
      }

      debugPrint('✅ Imported family data successfully');
    } catch (e) {
      debugPrint('❌ Error importing family data: $e');
      rethrow;
    }
  }

  // Cleanup
  Future<void> dispose() async {
    await _familyMembersBox?.close();
    await _sharedNotebooksBox?.close();
    _familyMembersBox = null;
    _sharedNotebooksBox = null;
  }
}
