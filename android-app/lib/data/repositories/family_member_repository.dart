// lib/data/repositories/family_member_repository.dart
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/family_member_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/debug/debug_logger.dart';
import '../../core/constants/app_constants.dart';

class FamilyMemberRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();

  Box<FamilyMember>? _familyBox;

  Box<FamilyMember> get familyBox {
    if (_familyBox == null || !_familyBox!.isOpen) {
      try {
        _familyBox = Hive.box<FamilyMember>(AppConstants.familyMembersBox);
      } catch (e) {
        throw Exception('Family members box not found. Make sure Hive is properly initialized: $e');
      }
    }
    return _familyBox!;
  }

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none) && result.isNotEmpty;
  }

  Future<List<FamilyMember>> getAllFamilyMembers() async {
    try {
      // Try to get family members from Firebase if online
      if (await _isOnline() && _firebaseService.currentUser != null) {
        final cloudMembers = await _firebaseService.getFamilyMembers();
        // Sync cloud data to local storage
        await _syncMembersToLocal(cloudMembers);
        return cloudMembers;
      } else {
        // Fall back to local storage
        return await _getLocalFamilyMembers();
      }
    } catch (e) {
      DebugLogger().log('❌ Error getting family members: $e');
      // Fall back to local storage on error
      return await _getLocalFamilyMembers();
    }
  }

  Future<List<FamilyMember>> _getLocalFamilyMembers() async {
    final members = familyBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    DebugLogger().log('👨‍👩‍👧‍👦 Repository: Loaded ${members.length} local family members');
    return members;
  }

  Future<void> _syncMembersToLocal(List<FamilyMember> cloudMembers) async {
    for (final member in cloudMembers) {
      await familyBox.put(member.id, member);
    }
    DebugLogger().log('✅ Synced ${cloudMembers.length} family members from cloud to local');
  }

  Future<FamilyMember?> getFamilyMemberById(String id) async {
    // Try local first for faster access
    final localMember = familyBox.get(id);
    if (localMember != null) {
      return localMember;
    }

    // If not found locally and online, try cloud
    if (await _isOnline() && _firebaseService.currentUser != null) {
      try {
        final cloudMembers = await _firebaseService.getFamilyMembers();
        final cloudMember = cloudMembers.where((member) => member.id == id).firstOrNull;
        if (cloudMember != null) {
          // Cache in local storage
          await familyBox.put(cloudMember.id, cloudMember);
          return cloudMember;
        }
      } catch (e) {
        DebugLogger().log('❌ Error fetching family member from cloud: $e');
      }
    }

    return null;
  }

  Future<void> saveFamilyMember(FamilyMember member) async {
    try {
      // Save to local storage first (for immediate UI update)
      await familyBox.put(member.id, member);

      // If online, also save to cloud
      if (await _isOnline() && _firebaseService.currentUser != null) {
        if (await _isMemberInCloud(member.id)) {
          await _firebaseService.updateFamilyMember(member);
        } else {
          await _firebaseService.createFamilyMember(member);
        }
        DebugLogger().log('✅ Family member synced to cloud: ${member.name}');
      } else {
        DebugLogger().log('📱 Family member saved locally (offline): ${member.name}');
      }
    } catch (e) {
      DebugLogger().log('❌ Error saving family member: $e');
      // Still save locally even if cloud sync fails
      await familyBox.put(member.id, member);
    }
  }

  Future<bool> _isMemberInCloud(String memberId) async {
    try {
      final cloudMembers = await _firebaseService.getFamilyMembers();
      return cloudMembers.any((member) => member.id == memberId);
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteFamilyMember(String memberId) async {
    try {
      // Delete from local storage
      await familyBox.delete(memberId);

      // If online, also delete from cloud
      if (await _isOnline() && _firebaseService.currentUser != null) {
        await _firebaseService.deleteFamilyMember(memberId);
        DebugLogger().log('✅ Family member deleted from cloud: $memberId');
      } else {
        DebugLogger().log('📱 Family member deleted locally (offline): $memberId');
      }
    } catch (e) {
      DebugLogger().log('❌ Error deleting family member: $e');
      // Still delete locally even if cloud sync fails
      await familyBox.delete(memberId);
    }
  }

  Future<void> syncFamilyMembers() async {
    if (!await _isOnline() || _firebaseService.currentUser == null) {
      DebugLogger().log('📱 Skipping family sync - offline or not authenticated');
      return;
    }

    try {
      DebugLogger().log('🔄 Starting family members synchronization...');

      // Get all cloud family members
      final cloudMembers = await _firebaseService.getFamilyMembers();

      // Get all local family members
      final localMembers = familyBox.values.toList();

      // Sync cloud to local
      for (final cloudMember in cloudMembers) {
        final localMember = localMembers.where((member) => member.id == cloudMember.id).firstOrNull;

        if (localMember == null) {
          // New member from cloud
          await familyBox.put(cloudMember.id, cloudMember);
          DebugLogger().log('📥 Synced new family member from cloud: ${cloudMember.name}');
        } else if (cloudMember.updatedAt.isAfter(localMember.updatedAt)) {
          // Cloud version is newer
          await familyBox.put(cloudMember.id, cloudMember);
          DebugLogger().log('🔄 Updated local family member from cloud: ${cloudMember.name}');
        } else if (localMember.updatedAt.isAfter(cloudMember.updatedAt)) {
          // Local version is newer
          await _firebaseService.updateFamilyMember(localMember);
          DebugLogger().log('🔄 Updated cloud family member from local: ${localMember.name}');
        }
      }

      // Find local members that don't exist in cloud (new local members)
      for (final localMember in localMembers) {
        final existsInCloud = cloudMembers.any((member) => member.id == localMember.id);
        if (!existsInCloud) {
          await _firebaseService.createFamilyMember(localMember);
          DebugLogger().log('📤 Synced new local family member to cloud: ${localMember.name}');
        }
      }

      DebugLogger().log('✅ Family members synchronization completed');
    } catch (e) {
      DebugLogger().log('❌ Error during family members synchronization: $e');
    }
  }

  // Get family members by relationship type
  Future<List<FamilyMember>> getFamilyMembersByRelationship(String relationship) async {
    final allMembers = await getAllFamilyMembers();
    return allMembers.where((member) => member.relationship == relationship).toList();
  }

  // Get emergency contacts
  Future<List<FamilyMember>> getEmergencyContacts() async {
    final allMembers = await getAllFamilyMembers();
    return allMembers.where((member) => member.isEmergencyContact).toList();
  }
}
