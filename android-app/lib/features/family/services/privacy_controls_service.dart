import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Privacy levels for data handling
enum PrivacyLevel {
  public,     // No encryption, visible to all family members
  private,    // Encrypted, visible only to owner
  sensitive,  // Encrypted, requires biometric authentication
}

/// Data encryption service for privacy controls
class PrivacyEncryptionService {
  static const String _encryptionKeyKey = 'privacy_encryption_key';

  /// Generate a new encryption key
  String _generateEncryptionKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return base64.encode(key.bytes);
  }

  /// Get or create encryption key
  Future<encrypt.Key> _getEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? keyString = prefs.getString(_encryptionKeyKey);
    if (keyString == null) {
      keyString = _generateEncryptionKey();
      await prefs.setString(_encryptionKeyKey, keyString);
    }
    return encrypt.Key(base64.decode(keyString));
  }

  /// Encrypt data with AES
  Future<String> encryptData(String data, PrivacyLevel level) async {
    if (level == PrivacyLevel.public) return data;

    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);
    final encryptedData = base64.encode(iv.bytes + encrypted.bytes);

    return encryptedData;
  }

  /// Decrypt data with AES
  Future<String> decryptData(String encryptedData, PrivacyLevel level) async {
    if (level == PrivacyLevel.public) return encryptedData;

    try {
      final key = await _getEncryptionKey();
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encryptedBytes = base64.decode(encryptedData);
      final iv = encrypt.IV(Uint8List.fromList(encryptedBytes.sublist(0, 16)));
      final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes.sublist(16)));

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Hash sensitive data for storage (one-way)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final hash = crypto.sha256.convert(bytes);
    return hash.toString();
  }

  /// Clear all encryption keys (for logout/reset)
  Future<void> clearEncryptionKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_encryptionKeyKey);
  }
}

/// Privacy settings for different data types
class PrivacySettings {
  final PrivacyLevel familyDataLevel;
  final PrivacyLevel personalDataLevel;
  final PrivacyLevel financialDataLevel;
  final PrivacyLevel medicalDataLevel;
  final bool enableBiometricForSensitive;
  final bool enableDataAnonymization;
  final int dataRetentionDays;

  const PrivacySettings({
    this.familyDataLevel = PrivacyLevel.private,
    this.personalDataLevel = PrivacyLevel.sensitive,
    this.financialDataLevel = PrivacyLevel.sensitive,
    this.medicalDataLevel = PrivacyLevel.sensitive,
    this.enableBiometricForSensitive = true,
    this.enableDataAnonymization = false,
    this.dataRetentionDays = 365,
  });

  Map<String, dynamic> toJson() => {
    'familyDataLevel': familyDataLevel.name,
    'personalDataLevel': personalDataLevel.name,
    'financialDataLevel': financialDataLevel.name,
    'medicalDataLevel': medicalDataLevel.name,
    'enableBiometricForSensitive': enableBiometricForSensitive,
    'enableDataAnonymization': enableDataAnonymization,
    'dataRetentionDays': dataRetentionDays,
  };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => PrivacySettings(
    familyDataLevel: PrivacyLevel.values.firstWhere(
      (e) => e.name == json['familyDataLevel'],
      orElse: () => PrivacyLevel.private,
    ),
    personalDataLevel: PrivacyLevel.values.firstWhere(
      (e) => e.name == json['personalDataLevel'],
      orElse: () => PrivacyLevel.sensitive,
    ),
    financialDataLevel: PrivacyLevel.values.firstWhere(
      (e) => e.name == json['financialDataLevel'],
      orElse: () => PrivacyLevel.sensitive,
    ),
    medicalDataLevel: PrivacyLevel.values.firstWhere(
      (e) => e.name == json['medicalDataLevel'],
      orElse: () => PrivacyLevel.sensitive,
    ),
    enableBiometricForSensitive: json['enableBiometricForSensitive'] ?? true,
    enableDataAnonymization: json['enableDataAnonymization'] ?? false,
    dataRetentionDays: json['dataRetentionDays'] ?? 365,
  );
}

/// Main privacy controls service
class PrivacyControlsService {
  final PrivacyEncryptionService _encryptionService = PrivacyEncryptionService();

  /// Get privacy settings for current user
  Future<PrivacySettings> getPrivacySettings(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('privacy')
        .doc('settings')
        .get();

    if (doc.exists) {
      return PrivacySettings.fromJson(doc.data()!);
    }

    return const PrivacySettings();
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('privacy')
        .doc('settings')
        .set(settings.toJson());
  }

  /// Encrypt data based on privacy level
  Future<String> encryptFamilyData(String data, PrivacyLevel level) async {
    return await _encryptionService.encryptData(data, level);
  }

  /// Decrypt data based on privacy level
  Future<String> decryptFamilyData(String encryptedData, PrivacyLevel level) async {
    return await _encryptionService.decryptData(encryptedData, level);
  }

  /// Store encrypted family data
  Future<void> storeEncryptedFamilyData(
    String userId,
    String dataId,
    String data,
    PrivacyLevel level,
    String dataType,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final encryptedData = await encryptFamilyData(data, level);

    await firestore
        .collection('users')
        .doc(userId)
        .collection('encrypted_data')
        .doc(dataId)
        .set({
          'encryptedData': encryptedData,
          'privacyLevel': level.name,
          'dataType': dataType,
          'createdAt': FieldValue.serverTimestamp(),
          'lastModified': FieldValue.serverTimestamp(),
        });
  }

  /// Retrieve and decrypt family data
  Future<String?> retrieveDecryptedFamilyData(String userId, String dataId) async {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('encrypted_data')
        .doc(dataId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    final encryptedData = data['encryptedData'] as String;
    final level = PrivacyLevel.values.firstWhere(
      (e) => e.name == data['privacyLevel'],
      orElse: () => PrivacyLevel.private,
    );

    return await decryptFamilyData(encryptedData, level);
  }

  /// Delete old data based on retention policy
  Future<void> enforceDataRetention(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final settings = await getPrivacySettings(userId);
    final cutoffDate = DateTime.now().subtract(
      Duration(days: settings.dataRetentionDays),
    );

    final oldData = await firestore
        .collection('users')
        .doc(userId)
        .collection('encrypted_data')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = firestore.batch();
    for (final doc in oldData.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Anonymize data for analytics (if enabled)
  Future<String> anonymizeData(String data) async {
    final hash = _encryptionService.hashData(data);
    return hash.substring(0, 8); // Use first 8 characters of hash
  }

  /// Clear all user data (GDPR compliance)
  Future<void> clearAllUserData(String userId) async {
    final firestore = FirebaseFirestore.instance;
    // Clear encrypted data
    final encryptedData = await firestore
        .collection('users')
        .doc(userId)
        .collection('encrypted_data')
        .get();

    final batch = firestore.batch();
    for (final doc in encryptedData.docs) {
      batch.delete(doc.reference);
    }

    // Clear privacy settings
    batch.delete(firestore
        .collection('users')
        .doc(userId)
        .collection('privacy')
        .doc('settings'));

    await batch.commit();

    // Clear local encryption keys
    await _encryptionService.clearEncryptionKeys();
  }

  /// Get data access log for audit
  Future<List<Map<String, dynamic>>> getDataAccessLog(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final logDocs = await firestore
        .collection('users')
        .doc(userId)
        .collection('privacy')
        .doc('access_log')
        .collection('entries')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return logDocs.docs.map((doc) => doc.data()).toList();
  }

  /// Log data access for audit purposes
  Future<void> logDataAccess(
    String userId,
    String dataId,
    String action,
    String reason,
  ) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('privacy')
        .doc('access_log')
        .collection('entries')
        .add({
          'dataId': dataId,
          'action': action,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
        });
  }
}

/// Riverpod providers
final privacyEncryptionServiceProvider = Provider<PrivacyEncryptionService>((ref) {
  return PrivacyEncryptionService();
});

final privacyControlsServiceProvider = Provider<PrivacyControlsService>((ref) {
  return PrivacyControlsService();
});

final privacySettingsProvider = FutureProvider.family<PrivacySettings, String>((ref, userId) {
  final service = ref.watch(privacyControlsServiceProvider);
  return service.getPrivacySettings(userId);
});
