import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pensieve/services/family_service.dart';

/// Backup types
enum BackupType {
  incremental,
  full,
  familyOnly,
  personalOnly,
}

/// Backup status
enum BackupStatus {
  pending,
  processing,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Encryption levels
enum EncryptionLevel {
  none,
  standard,
  enhanced,
  biometric,
}

/// Cloud storage destinations
enum CloudDestination {
  firebaseStorage,
  googleDrive,
  iCloudDrive,
  dropbox,
  oneDrive,
}

/// Advanced backup service with cloud storage and encryption
class BackupService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FamilyService _familyService;

  BackupService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    FamilyService? familyService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _familyService = familyService ?? FamilyService();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _backupsCollection =>
      _firestore.collection('backups');

  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection('notes');

  CollectionReference<Map<String, dynamic>> get _sharedNotesCollection =>
      _firestore.collection('shared_notes');

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Creates a new backup
  Future<ServiceResult<BackupMetadata>> createBackup({
    required BackupType backupType,
    bool includeFamilyData = true,
    bool includeMedia = true,
    EncryptionLevel encryptionLevel = EncryptionLevel.standard,
    CloudDestination destination = CloudDestination.firebaseStorage,
    String? customEncryptionKey,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final backupId = _backupsCollection.doc().id;
      final now = DateTime.now();

      // Create backup metadata
      final metadata = BackupMetadata(
        backupId: backupId,
        userId: user.uid,
        backupType: backupType,
        status: BackupStatus.pending,
        includeFamilyData: includeFamilyData,
        includeMedia: includeMedia,
        encryptionLevel: encryptionLevel,
        cloudDestination: destination,
        createdAt: now,
        estimatedSizeBytes: 0,
        progress: BackupProgress(
          percentage: 0,
          currentPhase: 'initializing',
          processedItems: 0,
          totalItems: 0,
        ),
      );

      // Save initial backup record
      await _backupsCollection.doc(backupId).set(metadata.toJson());

      // Start backup process asynchronously
      _performBackup(metadata, customEncryptionKey);

      return ServiceResult.success(data: metadata);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to create backup: ${e.toString()}',
        code: 'BACKUP_CREATION_FAILED',
      );
    }
  }

  /// Performs the actual backup process
  Future<void> _performBackup(BackupMetadata metadata, String? customKey) async {
    try {
      // Update status to processing
      await _updateBackupStatus(metadata.backupId, BackupStatus.processing);

      // Step 1: Collect data
      await _updateBackupProgress(metadata.backupId, 
          const BackupProgress(percentage: 10, currentPhase: 'collecting_data', processedItems: 0, totalItems: 0));

      final backupData = await _collectBackupData(metadata);

      // Step 2: Calculate total size
      final totalSize = _calculateBackupSize(backupData);
      await _updateBackupMetadata(metadata.backupId, {
        'estimatedSizeBytes': totalSize,
        'progress.totalItems': backupData.itemCount,
      });

      // Step 3: Encrypt data
      await _updateBackupProgress(metadata.backupId,
          const BackupProgress(percentage: 30, currentPhase: 'encrypting', processedItems: 0, totalItems: 0));

      final encryptedData = await _encryptBackupData(backupData, metadata.encryptionLevel, customKey);

      // Step 4: Generate checksum
      await _updateBackupProgress(metadata.backupId,
          const BackupProgress(percentage: 50, currentPhase: 'generating_checksum', processedItems: 0, totalItems: 0));

      final checksum = _generateChecksum(encryptedData);

      // Step 5: Upload to cloud storage
      await _updateBackupStatus(metadata.backupId, BackupStatus.uploading);
      await _updateBackupProgress(metadata.backupId,
          const BackupProgress(percentage: 60, currentPhase: 'uploading', processedItems: 0, totalItems: 0));

      final storageUrl = await _uploadToStorage(metadata, encryptedData);

      // Step 6: Save final metadata
      await _updateBackupProgress(metadata.backupId,
          const BackupProgress(percentage: 90, currentPhase: 'finalizing', processedItems: 0, totalItems: 0));

      await _updateBackupMetadata(metadata.backupId, {
        'status': BackupStatus.completed.toString(),
        'storageUrl': storageUrl,
        'checksumSHA256': checksum,
        'fileSizeBytes': encryptedData.length,
        'completedAt': FieldValue.serverTimestamp(),
        'progress.percentage': 100,
        'progress.currentPhase': 'completed',
      });

    } catch (e) {
      await _updateBackupStatus(metadata.backupId, BackupStatus.failed);
      await _updateBackupMetadata(metadata.backupId, {
        'error': e.toString(),
        'failedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Collects data for backup based on type
  Future<BackupData> _collectBackupData(BackupMetadata metadata) async {
    final user = currentUser!;
    final data = BackupData();

    // Personal notes
    final notesQuery = await _notesCollection
        .where('userId', isEqualTo: user.uid)
        .get();

    data.personalNotes = notesQuery.docs.map((doc) {
      final noteData = doc.data();
      noteData['id'] = doc.id;
      return noteData;
    }).toList();

    // Family data if requested
    if (metadata.includeFamilyData) {
      final familyResult = await _familyService.getUserFamilies();
      if (familyResult.isSuccess) {
        final families = familyResult.data!;
        
        for (final family in families) {
          // Shared notes for this family
          final sharedNotesQuery = await _sharedNotesCollection
              .where('familyId', isEqualTo: family.id)
              .get();

          data.sharedNotes.addAll(sharedNotesQuery.docs.map((doc) {
            final noteData = doc.data();
            noteData['id'] = doc.id;
            return noteData;
          }));

          // Family metadata
          data.familyData.add({
            'familyId': family.id,
            'familyName': family.name,
            'members': family.memberIds,
            'settings': family.settings.toJson(),
          });
        }
      }
    }

    // User settings and preferences
    data.userSettings = {
      'userId': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Media files if requested
    if (metadata.includeMedia) {
      data.mediaFiles = await _collectMediaFiles(user.uid);
    }

    return data;
  }

  /// Collects media files for backup
  Future<List<Map<String, dynamic>>> _collectMediaFiles(String userId) async {
    // This would collect audio files, images, etc. from Firebase Storage
    // For now, return empty list as media handling is complex
    return [];
  }

  /// Calculates estimated backup size
  int _calculateBackupSize(BackupData data) {
    final jsonData = jsonEncode(data.toJson());
    return utf8.encode(jsonData).length;
  }

  /// Encrypts backup data
  Future<Uint8List> _encryptBackupData(
    BackupData data,
    EncryptionLevel level,
    String? customKey,
  ) async {
    final jsonData = jsonEncode(data.toJson());
    final dataBytes = utf8.encode(jsonData);

    switch (level) {
      case EncryptionLevel.none:
        return Uint8List.fromList(dataBytes);

      case EncryptionLevel.standard:
        return _encryptWithAES(dataBytes, customKey);

      case EncryptionLevel.enhanced:
        return _encryptWithChaCha20(dataBytes, customKey);

      case EncryptionLevel.biometric:
        return _encryptWithBiometric(dataBytes, customKey);
    }
  }

  /// Encrypts data with AES
  Uint8List _encryptWithAES(List<int> data, String? customKey) {
    final key = customKey != null 
        ? Key.fromBase64(customKey) 
        : Key.fromSecureRandom(32);
    
    final encrypter = Encrypter(AES(key));
    final iv = IV.fromSecureRandom(16);
    
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // Prepend IV to encrypted data
    final result = <int>[];
    result.addAll(iv.bytes);
    result.addAll(encrypted.bytes);
    
    return Uint8List.fromList(result);
  }

  /// Encrypts data with ChaCha20 (enhanced security)
  Uint8List _encryptWithChaCha20(List<int> data, String? customKey) {
    // For enhanced encryption, would use ChaCha20-Poly1305
    // For now, fallback to AES
    return _encryptWithAES(data, customKey);
  }

  /// Encrypts data with biometric protection
  Uint8List _encryptWithBiometric(List<int> data, String? customKey) {
    // This would integrate with platform biometric APIs
    // For now, use standard AES with device-specific key
    return _encryptWithAES(data, customKey);
  }

  /// Generates SHA256 checksum
  String _generateChecksum(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Uploads backup to cloud storage
  Future<String> _uploadToStorage(BackupMetadata metadata, Uint8List data) async {
    final user = currentUser!;
    final fileName = 'backup_${metadata.backupId}_${DateTime.now().millisecondsSinceEpoch}.enc';
    final path = 'backups/${user.uid}/$fileName';

    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(
      data,
      SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: {
          'backupId': metadata.backupId,
          'userId': user.uid,
          'backupType': metadata.backupType.toString(),
          'encryptionLevel': metadata.encryptionLevel.toString(),
        },
      ),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Restores backup from cloud storage
  Future<ServiceResult<bool>> restoreBackup({
    required String backupId,
    String? decryptionKey,
    bool verifyIntegrity = true,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get backup metadata
      final backupDoc = await _backupsCollection.doc(backupId).get();
      if (!backupDoc.exists) {
        return ServiceResult.failure(
          error: 'Backup not found',
          code: 'BACKUP_NOT_FOUND',
        );
      }

      final metadata = BackupMetadata.fromJson(backupDoc.data()!);

      // Verify ownership
      if (metadata.userId != user.uid) {
        return ServiceResult.failure(
          error: 'Access denied to backup',
          code: 'ACCESS_DENIED',
        );
      }

      // Download backup data
      final encryptedData = await _downloadFromStorage(metadata.storageUrl!);

      // Verify integrity if requested
      if (verifyIntegrity && metadata.checksumSHA256 != null) {
        final calculatedChecksum = _generateChecksum(encryptedData);
        if (calculatedChecksum != metadata.checksumSHA256) {
          return ServiceResult.failure(
            error: 'Backup integrity check failed',
            code: 'INTEGRITY_CHECK_FAILED',
          );
        }
      }

      // Decrypt data
      final decryptedData = await _decryptBackupData(
        encryptedData,
        metadata.encryptionLevel,
        decryptionKey,
      );

      // Parse backup data
      final jsonString = utf8.decode(decryptedData);
      final backupData = BackupData.fromJson(jsonDecode(jsonString));

      // Restore data
      await _restoreBackupData(backupData);

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to restore backup: ${e.toString()}',
        code: 'RESTORE_FAILED',
      );
    }
  }

  /// Downloads backup from storage
  Future<Uint8List> _downloadFromStorage(String url) async {
    final ref = _storage.refFromURL(url);
    final data = await ref.getData();
    if (data == null) {
      throw Exception('Failed to download backup data');
    }
    return data;
  }

  /// Decrypts backup data
  Future<Uint8List> _decryptBackupData(
    Uint8List encryptedData,
    EncryptionLevel level,
    String? decryptionKey,
  ) async {
    switch (level) {
      case EncryptionLevel.none:
        return encryptedData;

      case EncryptionLevel.standard:
        return _decryptWithAES(encryptedData, decryptionKey);

      case EncryptionLevel.enhanced:
        return _decryptWithChaCha20(encryptedData, decryptionKey);

      case EncryptionLevel.biometric:
        return _decryptWithBiometric(encryptedData, decryptionKey);
    }
  }

  /// Decrypts data with AES
  Uint8List _decryptWithAES(Uint8List encryptedData, String? customKey) {
    if (customKey == null) {
      throw Exception('Decryption key required');
    }

    final key = Key.fromBase64(customKey);
    final encrypter = Encrypter(AES(key));

    // Extract IV from the beginning of encrypted data
    final iv = IV(encryptedData.sublist(0, 16));
    final cipherText = encryptedData.sublist(16);

    final encrypted = Encrypted(cipherText);
    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

    return Uint8List.fromList(decrypted);
  }

  /// Decrypts data with ChaCha20
  Uint8List _decryptWithChaCha20(Uint8List encryptedData, String? customKey) {
    // Fallback to AES for now
    return _decryptWithAES(encryptedData, customKey);
  }

  /// Decrypts data with biometric protection
  Uint8List _decryptWithBiometric(Uint8List encryptedData, String? customKey) {
    // Would integrate with biometric APIs
    return _decryptWithAES(encryptedData, customKey);
  }

  /// Restores backup data to Firestore
  Future<void> _restoreBackupData(BackupData data) async {
    final batch = _firestore.batch();

    // Restore personal notes
    for (final noteData in data.personalNotes) {
      final noteId = noteData['id'] ?? _notesCollection.doc().id;
      noteData.remove('id'); // Remove ID from data before saving
      batch.set(_notesCollection.doc(noteId), noteData);
    }

    // Restore shared notes
    for (final sharedNoteData in data.sharedNotes) {
      final noteId = sharedNoteData['id'] ?? _sharedNotesCollection.doc().id;
      sharedNoteData.remove('id');
      batch.set(_sharedNotesCollection.doc(noteId), sharedNoteData);
    }

    await batch.commit();
  }

  /// Gets user's backup history
  Future<ServiceResult<List<BackupMetadata>>> getBackupHistory({
    int limit = 20,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final snapshot = await _backupsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final backups = snapshot.docs.map((doc) {
        final data = doc.data();
        data['backupId'] = doc.id;
        return BackupMetadata.fromJson(data);
      }).toList();

      return ServiceResult.success(data: backups);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get backup history: ${e.toString()}',
        code: 'GET_HISTORY_FAILED',
      );
    }
  }

  /// Deletes a backup
  Future<ServiceResult<bool>> deleteBackup(String backupId) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get backup metadata
      final backupDoc = await _backupsCollection.doc(backupId).get();
      if (!backupDoc.exists) {
        return ServiceResult.failure(
          error: 'Backup not found',
          code: 'BACKUP_NOT_FOUND',
        );
      }

      final metadata = BackupMetadata.fromJson(backupDoc.data()!);

      // Verify ownership
      if (metadata.userId != user.uid) {
        return ServiceResult.failure(
          error: 'Access denied to backup',
          code: 'ACCESS_DENIED',
        );
      }

      // Delete from storage if exists
      if (metadata.storageUrl != null) {
        try {
          final ref = _storage.refFromURL(metadata.storageUrl!);
          await ref.delete();
        } catch (e) {
          // Continue even if storage deletion fails
          developer.log('Failed to delete backup from storage: $e', name: 'BackupService');
        }
      }

      // Delete metadata
      await _backupsCollection.doc(backupId).delete();

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to delete backup: ${e.toString()}',
        code: 'DELETE_FAILED',
      );
    }
  }

  /// Schedules automatic backups
  Future<ServiceResult<bool>> scheduleAutomaticBackup({
    required BackupType backupType,
    required Duration interval,
    bool includeFamilyData = true,
    bool includeMedia = false,
    EncryptionLevel encryptionLevel = EncryptionLevel.standard,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Save backup schedule to user preferences
      await _firestore.collection('user_preferences').doc(user.uid).set({
        'autoBackup': {
          'enabled': true,
          'backupType': backupType.toString(),
          'intervalHours': interval.inHours,
          'includeFamilyData': includeFamilyData,
          'includeMedia': includeMedia,
          'encryptionLevel': encryptionLevel.toString(),
          'lastBackup': null,
          'nextBackup': DateTime.now().add(interval).toIso8601String(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to schedule backup: ${e.toString()}',
        code: 'SCHEDULE_FAILED',
      );
    }
  }

  // Helper methods

  /// Updates backup status
  Future<void> _updateBackupStatus(String backupId, BackupStatus status) async {
    await _backupsCollection.doc(backupId).update({
      'status': status.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates backup progress
  Future<void> _updateBackupProgress(String backupId, BackupProgress progress) async {
    await _backupsCollection.doc(backupId).update({
      'progress': progress.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates backup metadata
  Future<void> _updateBackupMetadata(String backupId, Map<String, dynamic> updates) async {
    await _backupsCollection.doc(backupId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Service result wrapper
class ServiceResult<T> {
  final T? data;
  final String? error;
  final String? code;
  final bool isSuccess;

  const ServiceResult._({
    this.data,
    this.error,
    this.code,
    required this.isSuccess,
  });

  factory ServiceResult.success({required T data}) {
    return ServiceResult._(data: data, isSuccess: true);
  }

  factory ServiceResult.failure({required String error, String? code}) {
    return ServiceResult._(error: error, code: code, isSuccess: false);
  }
}

/// Backup metadata model
class BackupMetadata {
  final String backupId;
  final String userId;
  final BackupType backupType;
  final BackupStatus status;
  final bool includeFamilyData;
  final bool includeMedia;
  final EncryptionLevel encryptionLevel;
  final CloudDestination cloudDestination;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final int estimatedSizeBytes;
  final int? fileSizeBytes;
  final String? storageUrl;
  final String? checksumSHA256;
  final String? error;
  final BackupProgress progress;

  const BackupMetadata({
    required this.backupId,
    required this.userId,
    required this.backupType,
    required this.status,
    required this.includeFamilyData,
    required this.includeMedia,
    required this.encryptionLevel,
    required this.cloudDestination,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
    required this.estimatedSizeBytes,
    this.fileSizeBytes,
    this.storageUrl,
    this.checksumSHA256,
    this.error,
    required this.progress,
  });

  Map<String, dynamic> toJson() {
    return {
      'backupId': backupId,
      'userId': userId,
      'backupType': backupType.toString(),
      'status': status.toString(),
      'includeFamilyData': includeFamilyData,
      'includeMedia': includeMedia,
      'encryptionLevel': encryptionLevel.toString(),
      'cloudDestination': cloudDestination.toString(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
      'estimatedSizeBytes': estimatedSizeBytes,
      'fileSizeBytes': fileSizeBytes,
      'storageUrl': storageUrl,
      'checksumSHA256': checksumSHA256,
      'error': error,
      'progress': progress.toJson(),
    };
  }

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      backupId: json['backupId'],
      userId: json['userId'],
      backupType: BackupType.values.firstWhere(
        (e) => e.toString() == json['backupType'],
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      includeFamilyData: json['includeFamilyData'],
      includeMedia: json['includeMedia'],
      encryptionLevel: EncryptionLevel.values.firstWhere(
        (e) => e.toString() == json['encryptionLevel'],
      ),
      cloudDestination: CloudDestination.values.firstWhere(
        (e) => e.toString() == json['cloudDestination'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      failedAt: json['failedAt'] != null 
          ? DateTime.parse(json['failedAt']) 
          : null,
      estimatedSizeBytes: json['estimatedSizeBytes'],
      fileSizeBytes: json['fileSizeBytes'],
      storageUrl: json['storageUrl'],
      checksumSHA256: json['checksumSHA256'],
      error: json['error'],
      progress: BackupProgress.fromJson(json['progress']),
    );
  }
}

/// Backup progress model
class BackupProgress {
  final int percentage;
  final String currentPhase;
  final int processedItems;
  final int totalItems;

  const BackupProgress({
    required this.percentage,
    required this.currentPhase,
    required this.processedItems,
    required this.totalItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'percentage': percentage,
      'currentPhase': currentPhase,
      'processedItems': processedItems,
      'totalItems': totalItems,
    };
  }

  factory BackupProgress.fromJson(Map<String, dynamic> json) {
    return BackupProgress(
      percentage: json['percentage'],
      currentPhase: json['currentPhase'],
      processedItems: json['processedItems'],
      totalItems: json['totalItems'],
    );
  }
}

/// Backup data model
class BackupData {
  List<Map<String, dynamic>> personalNotes = [];
  List<Map<String, dynamic>> sharedNotes = [];
  List<Map<String, dynamic>> familyData = [];
  List<Map<String, dynamic>> mediaFiles = [];
  Map<String, dynamic> userSettings = {};

  BackupData(); // Default constructor

  int get itemCount => 
      personalNotes.length + 
      sharedNotes.length + 
      familyData.length + 
      mediaFiles.length + 
      1; // +1 for user settings

  Map<String, dynamic> toJson() {
    return {
      'personalNotes': personalNotes,
      'sharedNotes': sharedNotes,
      'familyData': familyData,
      'mediaFiles': mediaFiles,
      'userSettings': userSettings,
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final data = BackupData();
    data.personalNotes = List<Map<String, dynamic>>.from(json['personalNotes'] ?? []);
    data.sharedNotes = List<Map<String, dynamic>>.from(json['sharedNotes'] ?? []);
    data.familyData = List<Map<String, dynamic>>.from(json['familyData'] ?? []);
    data.mediaFiles = List<Map<String, dynamic>>.from(json['mediaFiles'] ?? []);
    data.userSettings = Map<String, dynamic>.from(json['userSettings'] ?? {});
    return data;
  }
}