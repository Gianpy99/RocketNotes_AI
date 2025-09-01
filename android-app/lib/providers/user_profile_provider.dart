import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/models/user_profile.dart';

// User Profile Provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    _loadUserProfile();
  }

  static const String _userProfileKey = 'current_user_profile';

  // Load user profile from Hive
  Future<void> _loadUserProfile() async {
    try {
      final box = Hive.box('settings');
      final profileData = box.get(_userProfileKey);
      
      if (profileData != null && profileData is UserProfile) {
        state = profileData;
        debugdebugPrint('✅ User profile loaded: ${profileData.displayName}');
      } else {
        debugdebugPrint('ℹ️ No user profile found, user needs to login');
      }
    } catch (e) {
      debugdebugPrint('❌ Error loading user profile: $e');
    }
  }

  // Login with email/password or social auth
  Future<bool> loginUser({
    required String userId,
    required String displayName,
    required String email,
    String? profileImageUrl,
    bool isAnonymous = false,
  }) async {
    try {
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        email: email,
        isAnonymous: isAnonymous,
        lastSyncTime: DateTime.now(),
        profileImageUrl: profileImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cloudSyncEnabled: !isAnonymous,
        cloudProvider: isAnonymous ? null : 'firebase',
      );

      // Save to Hive
      final box = Hive.box('settings');
      await box.put(_userProfileKey, profile);
      
      // Update state
      state = profile;
      
      debugPrint('✅ User logged in: ${profile.displayName}');
      return true;
    } catch (e) {
      debugPrint('❌ Error logging in user: $e');
      return false;
    }
  }

  // Login as anonymous user (offline mode)
  Future<bool> loginAnonymous() async {
    try {
      final profile = UserProfile.anonymous();
      
      // Save to Hive
      final box = Hive.box('settings');
      await box.put(_userProfileKey, profile);
      
      // Update state
      state = profile;
      
      debugPrint('✅ Anonymous user created: ${profile.userId}');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating anonymous user: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Remove from Hive
      final box = Hive.box('settings');
      await box.delete(_userProfileKey);
      
      // Clear state
      state = null;
      
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Error logging out: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? profileImageUrl,
    bool? cloudSyncEnabled,
  }) async {
    if (state == null) return;

    try {
      final updatedProfile = UserProfile(
        userId: state!.userId,
        displayName: displayName ?? state!.displayName,
        email: email ?? state!.email,
        isAnonymous: state!.isAnonymous,
        lastSyncTime: state!.lastSyncTime,
        profileImageUrl: profileImageUrl ?? state!.profileImageUrl,
        createdAt: state!.createdAt,
        updatedAt: DateTime.now(),
        cloudSyncEnabled: cloudSyncEnabled ?? state!.cloudSyncEnabled,
        cloudProvider: state!.cloudProvider,
        syncSettings: state!.syncSettings,
      );

      // Save to Hive
      final box = Hive.box('settings');
      await box.put(_userProfileKey, updatedProfile);
      
      // Update state
      state = updatedProfile;
      
      debugPrint('✅ User profile updated');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
    }
  }

  // Mark sync completed
  void markSynced() {
    if (state != null) {
      state!.markSynced();
      // Trigger rebuild
      state = state;
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => state != null;

  // Check if user has cloud sync enabled
  bool get hasCloudSync => state?.cloudSyncEnabled == true && state?.isAnonymous == false;

  // Get current user ID
  String? get currentUserId => state?.userId;

  // Check if sync is needed
  bool get needsSync => state?.needsSync() == true;
}
