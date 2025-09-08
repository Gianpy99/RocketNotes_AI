import 'package:flutter/foundation.dart';
import '../../core/services/firebase_service.dart';

/// Service for caching user names to improve performance
/// Reduces API calls by storing user name lookups in memory
class UserNameCacheService {
  static final UserNameCacheService _instance = UserNameCacheService._internal();
  final FirebaseService _firebaseService = FirebaseService();

  factory UserNameCacheService() {
    return _instance;
  }

  UserNameCacheService._internal();

  /// Cache for user names: userId -> displayName
  final Map<String, String> _nameCache = {};

  /// Cache for ongoing requests to avoid duplicate API calls
  final Map<String, Future<String?>> _pendingRequests = {};

  /// Get user display name by user ID with caching
  Future<String?> getUserName(String userId) async {
    // Return from cache if available
    if (_nameCache.containsKey(userId)) {
      return _nameCache[userId];
    }

    // Return pending request if one is already in progress
    if (_pendingRequests.containsKey(userId)) {
      return _pendingRequests[userId];
    }

    // Start new request
    final request = _fetchUserName(userId);
    _pendingRequests[userId] = request;

    try {
      final name = await request;
      _nameCache[userId] = name ?? 'Unknown User';
      return _nameCache[userId];
    } finally {
      _pendingRequests.remove(userId);
    }
  }

  /// Fetch user name from Firebase
  Future<String?> _fetchUserName(String userId) async {
    try {
      final userProfile = await _firebaseService.getUserProfileById(userId);
      return userProfile?.displayName;
    } catch (e) {
      // Log error but don't throw - return null to use fallback
      debugPrint('Error fetching user name for $userId');
      return null;
    }
  }

  /// Get multiple user names at once with batching
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    final results = <String, String>{};
    final futures = <Future<void>>[];

    for (final userId in userIds) {
      final future = getUserName(userId).then((name) {
        results[userId] = name ?? 'Unknown User';
      });
      futures.add(future);
    }

    await Future.wait(futures);
    return results;
  }

  /// Clear cache (useful for logout or cache invalidation)
  void clearCache() {
    _nameCache.clear();
    _pendingRequests.clear();
  }

  /// Get cache size for monitoring
  int get cacheSize => _nameCache.length;

  /// Preload user names for better performance
  Future<void> preloadUserNames(List<String> userIds) async {
    await getUserNames(userIds);
  }
}
