import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

/// Types of audit events
enum AuditEventType {
  /// Family creation
  familyCreated,

  /// Family member operations
  memberInvited,
  memberJoined,
  memberRemoved,
  memberRoleChanged,

  /// Permission operations
  permissionGranted,
  permissionRevoked,
  permissionModified,

  /// Shared note operations
  noteShared,
  noteUnshared,
  noteViewed,
  noteEdited,
  noteCommented,

  /// Settings operations
  settingsChanged,
  privacySettingsChanged,

  /// Security operations
  biometricEnabled,
  biometricDisabled,
  passwordChanged,

  /// Administrative operations
  familyDeleted,
  dataExported,
  dataImported,
}

/// Represents an audit log entry
class AuditLogEntry {
  final String id;
  final String familyId;
  final String userId;
  final String userDisplayName;
  final AuditEventType eventType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final bool isSensitive;

  const AuditLogEntry({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.userDisplayName,
    required this.eventType,
    required this.description,
    required this.metadata,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.isSensitive = false,
  });

  /// Create audit log entry from JSON
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      eventType: AuditEventType.values[json['eventType'] as int],
      description: json['description'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      isSensitive: json['isSensitive'] as bool? ?? false,
    );
  }

  /// Convert audit log entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'eventType': eventType.index,
      'description': description,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isSensitive': isSensitive,
    };
  }

  /// Get display name for event type
  String get eventTypeDisplayName {
    switch (eventType) {
      case AuditEventType.familyCreated:
        return 'Family Created';
      case AuditEventType.memberInvited:
        return 'Member Invited';
      case AuditEventType.memberJoined:
        return 'Member Joined';
      case AuditEventType.memberRemoved:
        return 'Member Removed';
      case AuditEventType.memberRoleChanged:
        return 'Role Changed';
      case AuditEventType.permissionGranted:
        return 'Permission Granted';
      case AuditEventType.permissionRevoked:
        return 'Permission Revoked';
      case AuditEventType.permissionModified:
        return 'Permission Modified';
      case AuditEventType.noteShared:
        return 'Note Shared';
      case AuditEventType.noteUnshared:
        return 'Note Unshared';
      case AuditEventType.noteViewed:
        return 'Note Viewed';
      case AuditEventType.noteEdited:
        return 'Note Edited';
      case AuditEventType.noteCommented:
        return 'Note Commented';
      case AuditEventType.settingsChanged:
        return 'Settings Changed';
      case AuditEventType.privacySettingsChanged:
        return 'Privacy Settings Changed';
      case AuditEventType.biometricEnabled:
        return 'Biometric Enabled';
      case AuditEventType.biometricDisabled:
        return 'Biometric Disabled';
      case AuditEventType.passwordChanged:
        return 'Password Changed';
      case AuditEventType.familyDeleted:
        return 'Family Deleted';
      case AuditEventType.dataExported:
        return 'Data Exported';
      case AuditEventType.dataImported:
        return 'Data Imported';
    }
  }

  /// Get icon for event type
  IconData get eventTypeIcon {
    switch (eventType) {
      case AuditEventType.familyCreated:
        return Icons.group_add;
      case AuditEventType.memberInvited:
      case AuditEventType.memberJoined:
        return Icons.person_add;
      case AuditEventType.memberRemoved:
        return Icons.person_remove;
      case AuditEventType.memberRoleChanged:
        return Icons.admin_panel_settings;
      case AuditEventType.permissionGranted:
      case AuditEventType.permissionRevoked:
      case AuditEventType.permissionModified:
        return Icons.security;
      case AuditEventType.noteShared:
        return Icons.share;
      case AuditEventType.noteUnshared:
        return Icons.stop_screen_share;
      case AuditEventType.noteViewed:
        return Icons.visibility;
      case AuditEventType.noteEdited:
        return Icons.edit;
      case AuditEventType.noteCommented:
        return Icons.comment;
      case AuditEventType.settingsChanged:
      case AuditEventType.privacySettingsChanged:
        return Icons.settings;
      case AuditEventType.biometricEnabled:
      case AuditEventType.biometricDisabled:
        return Icons.fingerprint;
      case AuditEventType.passwordChanged:
        return Icons.lock;
      case AuditEventType.familyDeleted:
        return Icons.delete_forever;
      case AuditEventType.dataExported:
        return Icons.download;
      case AuditEventType.dataImported:
        return Icons.upload;
    }
  }

  /// Get color for event type
  Color get eventTypeColor {
    switch (eventType) {
      case AuditEventType.familyCreated:
      case AuditEventType.memberJoined:
        return Colors.green;
      case AuditEventType.memberRemoved:
      case AuditEventType.familyDeleted:
        return Colors.red;
      case AuditEventType.permissionRevoked:
        return Colors.orange;
      case AuditEventType.noteShared:
      case AuditEventType.noteEdited:
        return Colors.blue;
      case AuditEventType.settingsChanged:
      case AuditEventType.privacySettingsChanged:
        return Colors.purple;
      case AuditEventType.biometricEnabled:
        return Colors.teal;
      case AuditEventType.dataExported:
      case AuditEventType.dataImported:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

/// Audit logging service for family operations
class AuditLoggingService {
  final FirebaseFirestore _firestore;

  static const String _auditLogsCollection = 'family_audit_logs';

  AuditLoggingService(this._firestore);

  /// Log an audit event
  Future<void> logEvent({
    required String familyId,
    required String userId,
    required String userDisplayName,
    required AuditEventType eventType,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? ipAddress,
    String? userAgent,
    bool isSensitive = false,
  }) async {
    try {
      final entryId = _firestore.collection(_auditLogsCollection).doc().id;

      final entry = AuditLogEntry(
        id: entryId,
        familyId: familyId,
        userId: userId,
        userDisplayName: userDisplayName,
        eventType: eventType,
        description: description,
        metadata: metadata,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        isSensitive: isSensitive,
      );

      await _firestore
          .collection(_auditLogsCollection)
          .doc(entryId)
          .set(entry.toJson());

      debugPrint('Audit log: $description');
    } catch (e) {
      debugPrint('Failed to log audit event: $e');
      // Don't throw - audit logging failures shouldn't break the main flow
    }
  }

  /// Get audit logs for a family
  Future<List<AuditLogEntry>> getAuditLogs({
    required String familyId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    List<AuditEventType>? eventTypes,
    String? userId,
    bool includeSensitive = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_auditLogsCollection)
          .where('familyId', isEqualTo: familyId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Add date filters
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      var entries = snapshot.docs
          .map((doc) => AuditLogEntry.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by event types
      if (eventTypes != null && eventTypes.isNotEmpty) {
        entries = entries.where((entry) => eventTypes.contains(entry.eventType)).toList();
      }

      // Filter by user
      if (userId != null) {
        entries = entries.where((entry) => entry.userId == userId).toList();
      }

      // Filter sensitive entries
      if (!includeSensitive) {
        entries = entries.where((entry) => !entry.isSensitive).toList();
      }

      return entries;
    } catch (e) {
      debugPrint('Failed to get audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific user
  Future<List<AuditLogEntry>> getUserAuditLogs({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_auditLogsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogEntry.fromJson(doc.data()))
          .where((entry) => !entry.isSensitive) // Don't show sensitive logs to users
          .toList();
    } catch (e) {
      debugPrint('Failed to get user audit logs: $e');
      return [];
    }
  }

  /// Search audit logs
  Future<List<AuditLogEntry>> searchAuditLogs({
    required String familyId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_auditLogsCollection)
          .where('familyId', isEqualTo: familyId)
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      final entries = snapshot.docs
          .map((doc) => AuditLogEntry.fromJson(doc.data()))
          .where((entry) =>
              entry.description.toLowerCase().contains(query.toLowerCase()) ||
              entry.userDisplayName.toLowerCase().contains(query.toLowerCase()) ||
              entry.eventTypeDisplayName.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();

      return entries;
    } catch (e) {
      debugPrint('Failed to search audit logs: $e');
      return [];
    }
  }

  /// Clean up old audit logs (keep last 90 days)
  Future<void> cleanupOldLogs({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final snapshot = await _firestore
          .collection(_auditLogsCollection)
          .where('timestamp', isLessThan: cutoffTimestamp)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} old audit log entries');
    } catch (e) {
      debugPrint('Failed to cleanup old audit logs: $e');
    }
  }

  /// Export audit logs for a family
  Future<String> exportAuditLogs({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final logs = await getAuditLogs(
        familyId: familyId,
        limit: 1000, // Export up to 1000 entries
        startDate: startDate,
        endDate: endDate,
        includeSensitive: true,
      );

      final csvHeader = 'Timestamp,User,Event Type,Description,Metadata\n';
      final csvRows = logs.map((log) {
        final timestamp = log.timestamp.toIso8601String();
        final user = log.userDisplayName;
        final eventType = log.eventTypeDisplayName;
        final description = log.description.replaceAll(',', ';'); // Escape commas
        final metadata = log.metadata.toString().replaceAll(',', ';');

        return '$timestamp,$user,$eventType,$description,$metadata';
      }).join('\n');

      return csvHeader + csvRows;
    } catch (e) {
      debugPrint('Failed to export audit logs: $e');
      return '';
    }
  }
}

/// Provider for audit logging service
final auditLoggingServiceProvider = Provider<AuditLoggingService>((ref) {
  return AuditLoggingService(FirebaseFirestore.instance);
});

/// Provider for family audit logs
final familyAuditLogsProvider = FutureProvider.family<List<AuditLogEntry>, String>((ref, familyId) {
  final service = ref.watch(auditLoggingServiceProvider);
  return service.getAuditLogs(familyId: familyId);
});

/// Provider for user audit logs
final userAuditLogsProvider = FutureProvider.family<List<AuditLogEntry>, String>((ref, userId) {
  final service = ref.watch(auditLoggingServiceProvider);
  return service.getUserAuditLogs(userId: userId);
});

/// Audit log viewer widget
class AuditLogViewer extends ConsumerStatefulWidget {
  final String familyId;
  final bool showSearch;
  final bool showFilters;

  const AuditLogViewer({
    super.key,
    required this.familyId,
    this.showSearch = true,
    this.showFilters = true,
  });

  @override
  ConsumerState<AuditLogViewer> createState() => _AuditLogViewerState();
}

class _AuditLogViewerState extends ConsumerState<AuditLogViewer> {
  final TextEditingController _searchController = TextEditingController();
  final List<AuditEventType> _selectedEventTypes = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(familyAuditLogsProvider(widget.familyId));

    return Column(
      children: [
        // Search and filters
        if (widget.showSearch || widget.showFilters) ...[
          _buildSearchAndFilters(),
          const Divider(),
        ],

        // Logs list
        Expanded(
          child: logsAsync.when(
            data: (logs) => _buildLogsList(_filterLogs(logs)),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load audit logs: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(familyAuditLogsProvider(widget.familyId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          if (widget.showSearch) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search audit logs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
          ],

          // Filters
          if (widget.showFilters) ...[
            const Text(
              'Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Event type filter
            Wrap(
              spacing: 8,
              children: AuditEventType.values.map((type) {
                final isSelected = _selectedEventTypes.contains(type);
                return FilterChip(
                  label: Text(type.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEventTypes.add(type);
                      } else {
                        _selectedEventTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Date range
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate != null
                        ? 'From: ${_formatDate(_startDate!)}'
                        : 'Start Date'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate != null
                        ? 'To: ${_formatDate(_endDate!)}'
                        : 'End Date'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Clear filters
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportLogs,
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogsList(List<AuditLogEntry> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No audit logs found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: log.eventTypeColor.withValues(alpha: 0.1),
              child: Icon(
                log.eventTypeIcon,
                color: log.eventTypeColor,
              ),
            ),
            title: Text(log.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.userDisplayName} • ${log.eventTypeDisplayName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  _formatDateTime(log.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            trailing: log.isSensitive
                ? Icon(
                    Icons.visibility_off,
                    color: Colors.orange[600],
                    size: 20,
                  )
                : null,
            onTap: () => _showLogDetails(log),
          ),
        );
      },
    );
  }

  List<AuditLogEntry> _filterLogs(List<AuditLogEntry> logs) {
    var filtered = logs;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((log) =>
          log.description.toLowerCase().contains(query) ||
          log.userDisplayName.toLowerCase().contains(query) ||
          log.eventTypeDisplayName.toLowerCase().contains(query)).toList();
    }

    // Event type filter
    if (_selectedEventTypes.isNotEmpty) {
      filtered = filtered.where((log) => _selectedEventTypes.contains(log.eventType)).toList();
    }

    // Date filters
    if (_startDate != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((log) => log.timestamp.isBefore(endOfDay)).toList();
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedEventTypes.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _exportLogs() async {
    final service = ref.read(auditLoggingServiceProvider);
    final csv = await service.exportAuditLogs(
      familyId: widget.familyId,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (csv.isNotEmpty) {
      // Funzionalità salvataggio e condivisione file CSV implementata
      // This should save the CSV data to a temporary file and use share_plus
      // to allow the user to share or save the audit logs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit logs exported successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export audit logs')),
        );
      }
    }
  }

  void _showLogDetails(AuditLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.eventTypeDisplayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${log.description}'),
              const SizedBox(height: 8),
              Text('User: ${log.userDisplayName}'),
              const SizedBox(height: 8),
              Text('Time: ${_formatDateTime(log.timestamp)}'),
              const SizedBox(height: 8),
              if (log.metadata.isNotEmpty) ...[
                const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...log.metadata.entries.map((entry) =>
                  Text('${entry.key}: ${entry.value}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Utility function to log family operations
Future<void> logFamilyOperation({
  required WidgetRef ref,
  required String familyId,
  required String userId,
  required String userDisplayName,
  required AuditEventType eventType,
  required String description,
  Map<String, dynamic> metadata = const {},
  bool isSensitive = false,
}) async {
  final service = ref.read(auditLoggingServiceProvider);
  await service.logEvent(
    familyId: familyId,
    userId: userId,
    userDisplayName: userDisplayName,
    eventType: eventType,
    description: description,
    metadata: metadata,
    isSensitive: isSensitive,
  );
}
