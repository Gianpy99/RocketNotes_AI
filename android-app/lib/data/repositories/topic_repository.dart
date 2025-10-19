// ==========================================
// lib/data/repositories/topic_repository.dart
// ==========================================

import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/topic.dart';

class TopicRepository {
  static const String boxName = 'topics';
  late Box<Topic> _topicsBox;
  
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  TopicRepository() {
    _topicsBox = Hive.box<Topic>(boxName);
  }

  /// Get all topics for current user
  Future<List<Topic>> getAllTopics() async {
    try {
      debugPrint('[TopicRepo] Getting all topics from box...');
      final allTopics = _topicsBox.values.toList();
      
      // Filter by current user
      final userTopics = allTopics.where((topic) {
        return topic.userId == null || topic.userId == _currentUserId;
      }).toList();
      
      // Sort by name
      userTopics.sort((a, b) => a.name.compareTo(b.name));
      
      debugPrint('[TopicRepo] Loaded ${userTopics.length} topics for current user');
      return userTopics;
    } catch (e) {
      debugPrint('[TopicRepo] Error loading topics: $e');
      return [];
    }
  }

  /// Get topic by ID
  Future<Topic?> getTopicById(String id) async {
    return _topicsBox.get(id);
  }

  /// Save topic (create or update)
  Future<void> saveTopic(Topic topic) async {
    try {
      debugPrint('[TopicRepo] Saving topic ${topic.id} to Hive box...');
      
      // Auto-assign userId if not set
      final topicToSave = topic.userId == null
          ? topic.copyWith(userId: _currentUserId)
          : topic;
      
      await _topicsBox.put(topicToSave.id, topicToSave);
      debugPrint('[TopicRepo] Topic saved successfully');
    } catch (e) {
      debugPrint('[TopicRepo] Error saving topic: $e');
      rethrow;
    }
  }

  /// Delete topic
  Future<void> deleteTopic(String id) async {
    await _topicsBox.delete(id);
    debugPrint('[TopicRepo] Topic $id deleted');
  }

  /// Get favorite topics
  Future<List<Topic>> getFavoriteTopics() async {
    final allTopics = await getAllTopics();
    return allTopics.where((topic) => topic.isFavorite).toList();
  }

  /// Update topic note count
  Future<void> updateNoteCount(String topicId, int count) async {
    final topic = await getTopicById(topicId);
    if (topic != null) {
      final updated = topic.copyWith(noteCount: count);
      await saveTopic(updated);
    }
  }

  /// Search topics by name or description
  Future<List<Topic>> searchTopics(String query) async {
    final allTopics = await getAllTopics();
    final lowercaseQuery = query.toLowerCase();
    
    return allTopics.where((topic) {
      return topic.name.toLowerCase().contains(lowercaseQuery) ||
             (topic.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final topic = await getTopicById(id);
    if (topic != null) {
      final updated = topic.copyWith(isFavorite: !topic.isFavorite);
      await saveTopic(updated);
    }
  }
}
