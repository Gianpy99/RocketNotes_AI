import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

/// Types of offline operations
enum OfflineOperationType {
  createFamily,
  updateFamily,
  deleteFamily,
  addFamilyMember,
  updateFamilyMember,
  removeFamilyMember,
  createInvitation,
  updateInvitation,
  deleteInvitation,
  shareNote,
  updateSharedNote,
  deleteSharedNote,
  grantPermission,
  updatePermission,
  revokePermission,
}

/// Represents an offline operation to be synced later
class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? userId;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
        'userId': userId,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> json) => OfflineOperation(
        id: json['id'],
        type: OfflineOperationType.values.firstWhere(
          (e) => e.toString() == json['type'],
        ),
        data: json['data'],
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retryCount'] ?? 0,
        userId: json['userId'],
      );
}

/// Service for managing offline operations and synchronization
class OfflineQueueService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 30);

  final Box<OfflineOperation> _operationsBox;
  final Connectivity _connectivity;

  // Stream controllers
  final BehaviorSubject<List<OfflineOperation>> _pendingOperationsController =
      BehaviorSubject<List<OfflineOperation>>.seeded([]);
  final BehaviorSubject<bool> _isOnlineController = BehaviorSubject<bool>.seeded(true);
  final BehaviorSubject<bool> _isSyncingController = BehaviorSubject<bool>.seeded(false);

  // Sync timers
  Timer? _syncTimer;
  Timer? _retryTimer;

  OfflineQueueService(this._operationsBox, this._connectivity) {
    _initializeConnectivityListener();
    _loadPendingOperations();
  }

  // Public streams
  Stream<List<OfflineOperation>> get pendingOperations => _pendingOperationsController.stream;
  Stream<bool> get isOnline => _isOnlineController.stream;
  Stream<bool> get isSyncing => _isSyncingController.stream;

  /// Initialize connectivity listener
  void _initializeConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final connectivityResult = result as ConnectivityResult;
      final isOnline = connectivityResult != ConnectivityResult.none;
      _isOnlineController.add(isOnline);

      if (isOnline) {
        debugPrint('🌐 Connection restored, starting sync...');
        _startSyncTimer();
      } else {
        debugPrint('📴 Connection lost, queuing operations...');
        _syncTimer?.cancel();
      }
    });
  }

  /// Load pending operations from storage
  void _loadPendingOperations() {
    try {
      final operations = _operationsBox.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _pendingOperationsController.add(operations);
      debugPrint('📋 Loaded ${operations.length} pending operations');
    } catch (e) {
      debugPrint('❌ Failed to load pending operations: $e');
    }
  }

  /// Add operation to offline queue
  Future<void> queueOperation(
    OfflineOperationType type,
    Map<String, dynamic> data, {
    String? userId,
  }) async {
    try {
      final operation = OfflineOperation(
        id: _generateOperationId(),
        type: type,
        data: data,
        timestamp: DateTime.now(),
        userId: userId,
      );

      await _operationsBox.put(operation.id, operation);

      final currentOperations = List<OfflineOperation>.from(_pendingOperationsController.value);
      currentOperations.add(operation);
      _pendingOperationsController.add(currentOperations);

      debugPrint('📝 Queued operation: ${type.toString().split('.').last}');

      // Start sync if online
      if (_isOnlineController.value) {
        _startSyncTimer();
      }
    } catch (e) {
      debugPrint('❌ Failed to queue operation: $e');
      rethrow;
    }
  }

  /// Start sync timer for processing operations
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 5), _processPendingOperations);
  }

  /// Process all pending operations
  Future<void> _processPendingOperations() async {
    if (!_isOnlineController.value || _isSyncingController.value) {
      return;
    }

    _isSyncingController.add(true);

    try {
      final operations = List<OfflineOperation>.from(_pendingOperationsController.value);
      final operationsToRemove = <String>[];

      for (final operation in operations) {
        if (operation.retryCount >= _maxRetries) {
          debugPrint('⏰ Max retries reached for operation: ${operation.id}');
          continue;
        }

        try {
          await _executeOperation(operation);
          operationsToRemove.add(operation.id);
          debugPrint('✅ Synced operation: ${operation.type.toString().split('.').last}');
        } catch (e) {
          debugPrint('❌ Failed to sync operation ${operation.id}: $e');
          await _incrementRetryCount(operation);
        }
      }

      // Remove successfully synced operations
      for (final id in operationsToRemove) {
        await _operationsBox.delete(id);
      }

      // Update pending operations list
      final remainingOperations = operations
          .where((op) => !operationsToRemove.contains(op.id))
          .toList();
      _pendingOperationsController.add(remainingOperations);

      debugPrint('🔄 Sync completed. Remaining operations: ${remainingOperations.length}');
    } catch (e) {
      debugPrint('❌ Sync process failed: $e');
    } finally {
      _isSyncingController.add(false);
    }
  }

  /// Execute a specific operation
  Future<void> _executeOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case OfflineOperationType.createFamily:
        await _executeCreateFamily(operation.data);
        break;
      case OfflineOperationType.updateFamily:
        await _executeUpdateFamily(operation.data);
        break;
      case OfflineOperationType.deleteFamily:
        await _executeDeleteFamily(operation.data);
        break;
      case OfflineOperationType.addFamilyMember:
        await _executeAddFamilyMember(operation.data);
        break;
      case OfflineOperationType.updateFamilyMember:
        await _executeUpdateFamilyMember(operation.data);
        break;
      case OfflineOperationType.removeFamilyMember:
        await _executeRemoveFamilyMember(operation.data);
        break;
      case OfflineOperationType.createInvitation:
        await _executeCreateInvitation(operation.data);
        break;
      case OfflineOperationType.updateInvitation:
        await _executeUpdateInvitation(operation.data);
        break;
      case OfflineOperationType.deleteInvitation:
        await _executeDeleteInvitation(operation.data);
        break;
      case OfflineOperationType.shareNote:
        await _executeShareNote(operation.data);
        break;
      case OfflineOperationType.updateSharedNote:
        await _executeUpdateSharedNote(operation.data);
        break;
      case OfflineOperationType.deleteSharedNote:
        await _executeDeleteSharedNote(operation.data);
        break;
      case OfflineOperationType.grantPermission:
        await _executeGrantPermission(operation.data);
        break;
      case OfflineOperationType.updatePermission:
        await _executeUpdatePermission(operation.data);
        break;
      case OfflineOperationType.revokePermission:
        await _executeRevokePermission(operation.data);
        break;
    }
  }

  /// Execute create family operation
  Future<void> _executeCreateFamily(Map<String, dynamic> data) async {
    // Implementation would call FamilyService.createFamily
    // This is a placeholder - actual implementation would depend on your service architecture
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network call
  }

  /// Execute update family operation
  Future<void> _executeUpdateFamily(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute delete family operation
  Future<void> _executeDeleteFamily(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute add family member operation
  Future<void> _executeAddFamilyMember(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute update family member operation
  Future<void> _executeUpdateFamilyMember(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute remove family member operation
  Future<void> _executeRemoveFamilyMember(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute create invitation operation
  Future<void> _executeCreateInvitation(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute update invitation operation
  Future<void> _executeUpdateInvitation(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute delete invitation operation
  Future<void> _executeDeleteInvitation(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute share note operation
  Future<void> _executeShareNote(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute update shared note operation
  Future<void> _executeUpdateSharedNote(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute delete shared note operation
  Future<void> _executeDeleteSharedNote(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute grant permission operation
  Future<void> _executeGrantPermission(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute update permission operation
  Future<void> _executeUpdatePermission(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Execute revoke permission operation
  Future<void> _executeRevokePermission(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Increment retry count for failed operation
  Future<void> _incrementRetryCount(OfflineOperation operation) async {
    final updatedOperation = OfflineOperation(
      id: operation.id,
      type: operation.type,
      data: operation.data,
      timestamp: operation.timestamp,
      retryCount: operation.retryCount + 1,
      userId: operation.userId,
    );

    await _operationsBox.put(operation.id, updatedOperation);

    // Schedule retry if under max retries
    if (updatedOperation.retryCount < _maxRetries) {
      _scheduleRetry();
    }
  }

  /// Schedule retry for failed operations
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (_isOnlineController.value) {
        _processPendingOperations();
      }
    });
  }

  /// Generate unique operation ID
  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_${_getRandomString(8)}';
  }

  /// Get random string for ID generation
  String _getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = StringBuffer();
    for (var i = 0; i < length; i++) {
      random.write(chars[DateTime.now().microsecondsSinceEpoch % chars.length]);
    }
    return random.toString();
  }

  /// Get current pending operations count
  int get pendingOperationsCount => _pendingOperationsController.value.length;

  /// Clear all pending operations (use with caution)
  Future<void> clearAllOperations() async {
    await _operationsBox.clear();
    _pendingOperationsController.add([]);
    debugPrint('🧹 Cleared all pending operations');
  }

  /// Force immediate sync
  Future<void> forceSync() async {
    if (_isOnlineController.value) {
      debugPrint('🔄 Forcing immediate sync...');
      await _processPendingOperations();
    } else {
      debugPrint('📴 Cannot force sync - offline');
    }
  }

  /// Get operations by type
  List<OfflineOperation> getOperationsByType(OfflineOperationType type) {
    return _pendingOperationsController.value
        .where((op) => op.type == type)
        .toList();
  }

  /// Remove specific operation
  Future<void> removeOperation(String operationId) async {
    await _operationsBox.delete(operationId);

    final currentOperations = List<OfflineOperation>.from(_pendingOperationsController.value);
    currentOperations.removeWhere((op) => op.id == operationId);
    _pendingOperationsController.add(currentOperations);

    debugPrint('🗑️ Removed operation: $operationId');
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _retryTimer?.cancel();

    await _pendingOperationsController.close();
    await _isOnlineController.close();
    await _isSyncingController.close();

    debugPrint('🗑️ Disposed OfflineQueueService');
  }
}

/// Hive adapter for OfflineOperation
class OfflineOperationAdapter extends TypeAdapter<OfflineOperation> {
  @override
  final int typeId = 100;

  @override
  OfflineOperation read(BinaryReader reader) {
    final json = jsonDecode(reader.readString());
    return OfflineOperation.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, OfflineOperation obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
