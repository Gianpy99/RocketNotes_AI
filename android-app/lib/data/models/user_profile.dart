import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 12)
class UserProfile extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  String email;

  @HiveField(3)
  bool isAnonymous;

  @HiveField(4)
  DateTime lastSyncTime;

  @HiveField(5)
  Map<String, dynamic> syncSettings;

  @HiveField(6)
  String? profileImageUrl;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  bool cloudSyncEnabled;

  @HiveField(10)
  String? cloudProvider; // 'firebase', 'supabase', 'custom'

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    this.isAnonymous = false,
    required this.lastSyncTime,
    this.syncSettings = const {},
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.cloudSyncEnabled = true,
    this.cloudProvider,
  });

  factory UserProfile.anonymous() {
    final now = DateTime.now();
    return UserProfile(
      userId: 'anonymous_${now.millisecondsSinceEpoch}',
      displayName: 'Utente Anonimo',
      email: '',
      isAnonymous: true,
      lastSyncTime: now,
      createdAt: now,
      updatedAt: now,
      cloudSyncEnabled: false,
    );
  }

  factory UserProfile.fromFirebase({
    required String uid,
    required String displayName,
    required String email,
    String? photoURL,
  }) {
    final now = DateTime.now();
    return UserProfile(
      userId: uid,
      displayName: displayName,
      email: email,
      isAnonymous: false,
      lastSyncTime: now,
      profileImageUrl: photoURL,
      createdAt: now,
      updatedAt: now,
      cloudSyncEnabled: true,
      cloudProvider: 'firebase',
    );
  }

  // Update sync timestamp
  void markSynced() {
    lastSyncTime = DateTime.now();
    updatedAt = DateTime.now();
    save(); // Hive method to persist changes
  }

  // Check if sync is needed (older than 5 minutes)
  bool needsSync() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return lastSyncTime.isBefore(fiveMinutesAgo);
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'isAnonymous': isAnonymous,
      'lastSyncTime': lastSyncTime.toIso8601String(),
      'syncSettings': syncSettings,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cloudSyncEnabled': cloudSyncEnabled,
      'cloudProvider': cloudProvider,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      displayName: json['displayName'],
      email: json['email'],
      isAnonymous: json['isAnonymous'] ?? false,
      lastSyncTime: DateTime.parse(json['lastSyncTime']),
      syncSettings: Map<String, dynamic>.from(json['syncSettings'] ?? {}),
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cloudSyncEnabled: json['cloudSyncEnabled'] ?? true,
      cloudProvider: json['cloudProvider'],
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, displayName: $displayName, email: $email, isAnonymous: $isAnonymous)';
  }
}
