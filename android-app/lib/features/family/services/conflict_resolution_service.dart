import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Keep the most recent change
  latestWins,

  /// Merge changes when possible
  merge,

  /// Show conflict dialog to user
  manual,

  /// Keep the server version
  serverWins,
}

/// Represents a conflict between concurrent edits
class EditConflict {
  final String documentId;
  final String field;
  final dynamic localValue;
  final dynamic serverValue;
  final DateTime localTimestamp;
  final DateTime serverTimestamp;
  final String userId;
  final String userDisplayName;

  const EditConflict({
    required this.documentId,
    required this.field,
    required this.localValue,
    required this.serverValue,
    required this.localTimestamp,
    required this.serverTimestamp,
    required this.userId,
    required this.userDisplayName,
  });

  /// Check if this is a real conflict (values are different)
  bool get isRealConflict => localValue != serverValue;

  /// Get the time difference between edits
  Duration get timeDifference => localTimestamp.difference(serverTimestamp).abs();
}

/// Conflict resolution service for concurrent edits
class ConflictResolutionService {
  final FirebaseFirestore _firestore;

  ConflictResolutionService(this._firestore);

  /// Detect conflicts when saving changes
  Future<List<EditConflict>> detectConflicts({
    required String collection,
    required String documentId,
    required Map<String, dynamic> localChanges,
    required DateTime lastSyncTimestamp,
  }) async {
    final conflicts = <EditConflict>[];

    try {
      // Get the current server version
      final docSnapshot = await _firestore.collection(collection).doc(documentId).get();

      if (!docSnapshot.exists) {
        return conflicts; // Document doesn't exist on server
      }

      final serverData = docSnapshot.data()!;
      final serverTimestamp = (serverData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Only check for conflicts if server was updated after our last sync
      if (serverTimestamp.isAfter(lastSyncTimestamp)) {
        for (final entry in localChanges.entries) {
          final field = entry.key;
          final localValue = entry.value;
          final serverValue = serverData[field];

          // Skip system fields
          if (_isSystemField(field)) continue;

          // Check if values are different
          if (!_areValuesEqual(localValue, serverValue)) {
            conflicts.add(EditConflict(
              documentId: documentId,
              field: field,
              localValue: localValue,
              serverValue: serverValue,
              localTimestamp: DateTime.now(),
              serverTimestamp: serverTimestamp,
              userId: 'current_user', // TODO: Get from auth
              userDisplayName: 'Current User', // TODO: Get from auth
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error detecting conflicts: $e');
    }

    return conflicts;
  }

  /// Resolve conflicts using the specified strategy
  Future<Map<String, dynamic>> resolveConflicts({
    required List<EditConflict> conflicts,
    required ConflictResolutionStrategy strategy,
    required Map<String, dynamic> localChanges,
  }) async {
    final resolvedChanges = Map<String, dynamic>.from(localChanges);

    for (final conflict in conflicts) {
      switch (strategy) {
        case ConflictResolutionStrategy.latestWins:
          resolvedChanges[conflict.field] = _resolveLatestWins(conflict);
          break;

        case ConflictResolutionStrategy.merge:
          final merged = _resolveMerge(conflict);
          if (merged != null) {
            resolvedChanges[conflict.field] = merged;
          } else {
            // Fall back to latest wins if merge fails
            resolvedChanges[conflict.field] = _resolveLatestWins(conflict);
          }
          break;

        case ConflictResolutionStrategy.serverWins:
          resolvedChanges[conflict.field] = conflict.serverValue;
          break;

        case ConflictResolutionStrategy.manual:
          // This should be handled by UI dialog
          resolvedChanges[conflict.field] = conflict.localValue;
          break;
      }
    }

    return resolvedChanges;
  }

  /// Resolve conflict by keeping the latest change
  dynamic _resolveLatestWins(EditConflict conflict) {
    return conflict.localTimestamp.isAfter(conflict.serverTimestamp)
        ? conflict.localValue
        : conflict.serverValue;
  }

  /// Attempt to merge conflicting changes
  dynamic _resolveMerge(EditConflict conflict) {
    final localValue = conflict.localValue;
    final serverValue = conflict.serverValue;

    // Try to merge text fields by concatenating
    if (localValue is String && serverValue is String) {
      // Simple merge strategy: keep both changes separated
      if (conflict.localTimestamp.isAfter(conflict.serverTimestamp)) {
        return '$serverValue\n\n[Edited by ${conflict.userDisplayName}]\n$localValue';
      } else {
        return '$localValue\n\n[Edited by another user]\n$serverValue';
      }
    }

    // Try to merge lists by combining unique items
    if (localValue is List && serverValue is List) {
      final combined = <dynamic>[...serverValue];
      for (final item in localValue) {
        if (!combined.contains(item)) {
          combined.add(item);
        }
      }
      return combined;
    }

    // For other types, can't merge
    return null;
  }

  /// Check if a field is a system field that shouldn't be conflicted
  bool _isSystemField(String field) {
    const systemFields = [
      'id',
      'createdAt',
      'updatedAt',
      'createdBy',
      'updatedBy',
      'version',
      'lastSyncAt',
    ];
    return systemFields.contains(field);
  }

  /// Check if two values are equal (with some tolerance for floating point)
  bool _areValuesEqual(dynamic value1, dynamic value2) {
    if (value1 == value2) return true;

    // Handle null values
    if (value1 == null || value2 == null) return false;

    // Handle lists
    if (value1 is List && value2 is List) {
      if (value1.length != value2.length) return false;
      for (int i = 0; i < value1.length; i++) {
        if (!_areValuesEqual(value1[i], value2[i])) return false;
      }
      return true;
    }

    // Handle maps
    if (value1 is Map && value2 is Map) {
      if (value1.length != value2.length) return false;
      for (final key in value1.keys) {
        if (!value2.containsKey(key)) return false;
        if (!_areValuesEqual(value1[key], value2[key])) return false;
      }
      return true;
    }

    // Handle timestamps
    if (value1 is Timestamp && value2 is Timestamp) {
      return value1.seconds == value2.seconds && value1.nanoseconds == value2.nanoseconds;
    }

    return false;
  }

  /// Save changes with conflict resolution
  Future<void> saveWithConflictResolution({
    required String collection,
    required String documentId,
    required Map<String, dynamic> changes,
    required DateTime lastSyncTimestamp,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.manual,
  }) async {
    // Detect conflicts
    final conflicts = await detectConflicts(
      collection: collection,
      documentId: documentId,
      localChanges: changes,
      lastSyncTimestamp: lastSyncTimestamp,
    );

    if (conflicts.isEmpty) {
      // No conflicts, save directly
      await _firestore.collection(collection).doc(documentId).update({
        ...changes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Resolve conflicts
    final resolvedChanges = await resolveConflicts(
      conflicts: conflicts,
      strategy: strategy,
      localChanges: changes,
    );

    // Save resolved changes
    await _firestore.collection(collection).doc(documentId).update({
      ...resolvedChanges,
      'updatedAt': FieldValue.serverTimestamp(),
      'conflictResolved': true,
      'conflictCount': FieldValue.increment(conflicts.length),
    });
  }
}

/// Provider for conflict resolution service
final conflictResolutionServiceProvider = Provider<ConflictResolutionService>((ref) {
  return ConflictResolutionService(FirebaseFirestore.instance);
});

/// Provider for conflict resolution strategy preference
final conflictResolutionStrategyProvider = StateProvider<ConflictResolutionStrategy>(
  (ref) => ConflictResolutionStrategy.manual,
);

/// Conflict resolution dialog widget
class ConflictResolutionDialog extends StatefulWidget {
  final List<EditConflict> conflicts;
  final VoidCallback onResolved;
  final VoidCallback? onCancelled;

  const ConflictResolutionDialog({
    super.key,
    required this.conflicts,
    required this.onResolved,
    this.onCancelled,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictResolutionStrategy _selectedStrategy = ConflictResolutionStrategy.manual;
  final Map<String, dynamic> _resolutions = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve Edit Conflicts'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.conflicts.length} conflict${widget.conflicts.length == 1 ? '' : 's'} detected',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Strategy selector
            const Text('Resolution Strategy:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButton<ConflictResolutionStrategy>(
              value: _selectedStrategy,
              isExpanded: true,
              items: ConflictResolutionStrategy.values.map((strategy) {
                return DropdownMenuItem(
                  value: strategy,
                  child: Text(_getStrategyDisplayName(strategy)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStrategy = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Conflict details
            if (_selectedStrategy == ConflictResolutionStrategy.manual) ...[
              const Text('Manual Resolution:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ...widget.conflicts.map((conflict) => _buildConflictItem(conflict)),
            ] else ...[
              Text(
                'Using ${_getStrategyDisplayName(_selectedStrategy)} strategy',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancelled?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _resolveConflicts,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Resolve'),
        ),
      ],
    );
  }

  Widget _buildConflictItem(EditConflict conflict) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Field: ${conflict.field}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Your change
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your change (${_formatDate(conflict.localTimestamp)}):',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatValue(conflict.localValue),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Server change
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server change (${_formatDate(conflict.serverTimestamp)}):',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatValue(conflict.serverValue),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Resolution options
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _resolutions[conflict.field] = true),
                    child: Row(
                      children: [
                        Icon(
                          _resolutions[conflict.field] == true
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: _resolutions[conflict.field] == true
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Keep Yours', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _resolutions[conflict.field] = false),
                    child: Row(
                      children: [
                        Icon(
                          _resolutions[conflict.field] == false
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: _resolutions[conflict.field] == false
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Keep Server', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resolveConflicts() {
    // For manual resolution, ensure all conflicts have resolutions
    if (_selectedStrategy == ConflictResolutionStrategy.manual) {
      for (final conflict in widget.conflicts) {
        if (!_resolutions.containsKey(conflict.field)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please resolve all conflicts')),
          );
          return;
        }
      }
    }

    widget.onResolved();
    Navigator.of(context).pop();
  }

  String _getStrategyDisplayName(ConflictResolutionStrategy strategy) {
    switch (strategy) {
      case ConflictResolutionStrategy.latestWins:
        return 'Latest Wins';
      case ConflictResolutionStrategy.merge:
        return 'Merge Changes';
      case ConflictResolutionStrategy.manual:
        return 'Manual Resolution';
      case ConflictResolutionStrategy.serverWins:
        return 'Server Wins';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value.length > 100 ? '${value.substring(0, 100)}...' : value;
    return value.toString();
  }
}

/// Utility function to handle conflicts during save operations
Future<bool> handleSaveConflicts({
  required BuildContext context,
  required WidgetRef ref,
  required String collection,
  required String documentId,
  required Map<String, dynamic> changes,
  required DateTime lastSyncTimestamp,
}) async {
  final service = ref.read(conflictResolutionServiceProvider);

  // Detect conflicts
  final conflicts = await service.detectConflicts(
    collection: collection,
    documentId: documentId,
    localChanges: changes,
    lastSyncTimestamp: lastSyncTimestamp,
  );

  if (conflicts.isEmpty) {
    // No conflicts, save directly
    await service.saveWithConflictResolution(
      collection: collection,
      documentId: documentId,
      changes: changes,
      lastSyncTimestamp: lastSyncTimestamp,
      strategy: ConflictResolutionStrategy.manual,
    );
    return true;
  }

  // Show conflict resolution dialog
  final completer = Completer<bool>();

  if (!context.mounted) {
    return false;
  }

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ConflictResolutionDialog(
      conflicts: conflicts,
      onResolved: () async {
        try {
          final strategy = ref.read(conflictResolutionStrategyProvider);
          await service.saveWithConflictResolution(
            collection: collection,
            documentId: documentId,
            changes: changes,
            lastSyncTimestamp: lastSyncTimestamp,
            strategy: strategy,
          );
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
          completer.complete(true);
        } catch (e) {
          completer.complete(false);
        }
      },
      onCancelled: () {
        if (context.mounted) {
          Navigator.of(context).pop(false);
        }
        completer.complete(false);
      },
    ),
  );

  return completer.future;
}
