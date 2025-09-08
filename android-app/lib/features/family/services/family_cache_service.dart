import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';
import '../../../models/shared_note.dart';

/// Cache service for family operations to improve performance
class FamilyCacheService {
  static const String _familyBox = 'family_cache';
  static const String _membersBox = 'family_members_cache';
  static const String _sharedNotesBox = 'shared_notes_cache';
  static const String _timestampsBox = 'cache_timestamps';
  static const Duration _cacheDuration = Duration(minutes: 30);

  late Box<String> _familyCache;
  late Box<String> _membersCache;
  late Box<String> _sharedNotesCache;
  late Box<String> _timestampsCache;

  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _familyCache = await Hive.openBox<String>(_familyBox);
      _membersCache = await Hive.openBox<String>(_membersBox);
      _sharedNotesCache = await Hive.openBox<String>(_sharedNotesBox);
      _timestampsCache = await Hive.openBox<String>(_timestampsBox);

      _isInitialized = true;
      debugPrint('Family cache service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing family cache: $e');
      rethrow;
    }
  }

  /// Cache family data with timestamp
  Future<void> cacheFamily(Family family) async {
    await _ensureInitialized();
    final familyJson = jsonEncode(family.toJson());
    await _familyCache.put(family.id, familyJson);
    await _timestampsCache.put('family_${family.id}', DateTime.now().toIso8601String());
  }

  /// Get cached family data if not expired
  Family? getCachedFamily(String familyId) {
    if (!_isInitialized) return null;

    try {
      final familyJson = _familyCache.get(familyId);
      if (familyJson == null) return null;

      final timestampKey = 'family_$familyId';
      final timestampStr = _timestampsCache.get(timestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        _familyCache.delete(familyId);
        _timestampsCache.delete(timestampKey);
        return null;
      }

      final familyMap = jsonDecode(familyJson) as Map<String, dynamic>;
      return Family.fromJson(familyMap);
    } catch (e) {
      debugPrint('Error getting cached family: $e');
      return null;
    }
  }

  /// Cache family members with timestamp
  Future<void> cacheFamilyMembers(String familyId, List<FamilyMember> members) async {
    await _ensureInitialized();
    final membersJson = jsonEncode(members.map((m) => m.toJson()).toList());
    await _membersCache.put(familyId, membersJson);
    await _timestampsCache.put('members_$familyId', DateTime.now().toIso8601String());
  }

  /// Get cached family members if not expired
  List<FamilyMember>? getCachedFamilyMembers(String familyId) {
    if (!_isInitialized) return null;

    try {
      final membersJson = _membersCache.get(familyId);
      if (membersJson == null) return null;

      final timestampKey = 'members_$familyId';
      final timestampStr = _timestampsCache.get(timestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        _membersCache.delete(familyId);
        _timestampsCache.delete(timestampKey);
        return null;
      }

      final membersList = jsonDecode(membersJson) as List;
      return membersList.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting cached family members: $e');
      return null;
    }
  }

  /// Cache shared notes with timestamp
  Future<void> cacheSharedNotes(String familyId, List<SharedNote> notes) async {
    await _ensureInitialized();
    final notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());
    await _sharedNotesCache.put(familyId, notesJson);
    await _timestampsCache.put('notes_$familyId', DateTime.now().toIso8601String());
  }

  /// Get cached shared notes if not expired
  List<SharedNote>? getCachedSharedNotes(String familyId) {
    if (!_isInitialized) return null;

    try {
      final notesJson = _sharedNotesCache.get(familyId);
      if (notesJson == null) return null;

      final timestampKey = 'notes_$familyId';
      final timestampStr = _timestampsCache.get(timestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        // Cache expired
        _sharedNotesCache.delete(familyId);
        _timestampsCache.delete(timestampKey);
        return null;
      }

      final notesList = jsonDecode(notesJson) as List;
      return notesList.map((n) => SharedNote.fromJson(n as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting cached shared notes: $e');
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _ensureInitialized();
    await _familyCache.clear();
    await _membersCache.clear();
    await _sharedNotesCache.clear();
    await _timestampsCache.clear();
    debugPrint('Family cache cleared');
  }

  /// Clear cache for specific family
  Future<void> clearFamilyCache(String familyId) async {
    await _ensureInitialized();
    await _familyCache.delete(familyId);
    await _membersCache.delete(familyId);
    await _sharedNotesCache.delete(familyId);
    await _timestampsCache.delete('family_$familyId');
    await _timestampsCache.delete('members_$familyId');
    await _timestampsCache.delete('notes_$familyId');
    debugPrint('Cache cleared for family: $familyId');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    if (!_isInitialized) return {};

    return {
      'family_cache_size': _familyCache.length,
      'members_cache_size': _membersCache.length,
      'shared_notes_cache_size': _sharedNotesCache.length,
      'timestamps_cache_size': _timestampsCache.length,
      'cache_duration_minutes': _cacheDuration.inMinutes,
    };
  }

  /// Ensure cache is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose cache service
  Future<void> dispose() async {
    if (_isInitialized) {
      await _familyCache.close();
      await _membersCache.close();
      await _sharedNotesCache.close();
      await _timestampsCache.close();
      _isInitialized = false;
      debugPrint('Family cache service disposed');
    }
  }
}
