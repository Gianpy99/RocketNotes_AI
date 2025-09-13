# Data Model: Complete TODO Implementation & Remove Mockups

**Date**: 2025-09-13  
**Feature**: 003-implement-all-todo  

## Overview

This document outlines the data models and entities required to complete all TODO implementations in the RocketNotes AI application. The models extend and complete the existing data structures while maintaining backward compatibility.

## Core Entities

### Family
**Purpose**: Central entity for family group management
**Current State**: Basic structure exists, needs completion
**Extensions Needed**: Invitation tracking, activity logging, real-time sync metadata

```dart
class Family {
  final String id;
  final String name;
  final String? description;
  final List<String> memberIds;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FamilySettings settings;
  final Map<String, dynamic> metadata;
  
  // New fields for TODO completion
  final List<String> pendingInvitationIds;
  final ActivityLog activityLog;
  final ConflictResolutionSettings conflictSettings;
}

class FamilySettings {
  final bool allowMemberInvites;
  final bool requireApprovalForSharing;
  final NotificationPreferences notifications;
  final BackupSettings backup;
  final SecuritySettings security;
}
```

**Validation Rules**:
- Family name: 1-50 characters, required
- Member limit: 2-10 family members
- Owner cannot be removed from family
- At least one admin required at all times

**State Transitions**:
- Created → Active (when first member joins)
- Active → Suspended (on security violations)
- Active → Archived (when all members leave)

### Family Member
**Purpose**: Individual user within a family context
**Current State**: Basic permissions exist, needs role management
**Extensions Needed**: Activity tracking, preference management, device management

```dart
class FamilyMember {
  final String id;
  final String userId;
  final String familyId;
  final String name;
  final String email;
  final String relationship;
  final FamilyRole role;
  final FamilyPermissions permissions;
  final DateTime joinedAt;
  final DateTime lastActiveAt;
  
  // New fields for TODO completion
  final List<String> deviceTokens;
  final MemberPreferences preferences;
  final List<String> assignedNotebooks;
  final ActivityTracker activity;
}

class FamilyRole {
  final String name; // owner, admin, editor, viewer, limited
  final List<String> capabilities;
  final bool isCustom;
}

class FamilyPermissions {
  final bool canInviteMembers;
  final bool canRemoveMembers;
  final bool canShareNotes;
  final bool canCreateNotebooks;
  final bool canManagePermissions;
  final bool canViewActivity;
  final bool canExportData;
  final bool canManageBackup;
}
```

**Validation Rules**:
- Unique email per family
- Role capabilities must be subset of role definition
- Custom roles require admin permission to create
- Device tokens managed automatically

### Shared Note
**Purpose**: Notes accessible by multiple family members with permissions
**Current State**: Basic sharing exists, needs real-time collaboration
**Extensions Needed**: Version control, collaboration metadata, conflict resolution

```dart
class SharedNote {
  final String id;
  final String noteId;
  final String familyId;
  final String sharedBy;
  final String title;
  final String content;
  final DateTime sharedAt;
  final DateTime lastModified;
  final Map<String, Permission> memberPermissions;
  
  // New fields for TODO completion
  final List<NoteVersion> versions;
  final CollaborationMetadata collaboration;
  final List<String> activeEditors;
  final ConflictResolution conflicts;
  final ExportSettings export;
}

class NoteVersion {
  final String id;
  final String content;
  final String modifiedBy;
  final DateTime timestamp;
  final String changeDescription;
  final Map<String, dynamic> diff;
}

class CollaborationMetadata {
  final Map<String, DateTime> lastSeenBy;
  final Map<String, CursorPosition> activeCursors;
  final List<String> currentlyEditing;
  final RealtimeSync syncStatus;
}
```

**Validation Rules**:
- Note content size limit: 1MB
- Version history limit: 50 versions per note
- Maximum 5 concurrent editors
- Auto-save every 30 seconds during editing

### Notification
**Purpose**: System and user notifications with delivery tracking
**Current State**: Basic local notifications, needs push notification integration
**Extensions Needed**: Delivery status, batching, preferences, history

```dart
class Notification {
  final String id;
  final String recipientId;
  final String familyId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  
  // New fields for TODO completion
  final NotificationPriority priority;
  final DeliveryStatus delivery;
  final List<String> channels; // push, email, in-app
  final DateTime? scheduledFor;
  final String? batchId;
  final NotificationActions actions;
}

class DeliveryStatus {
  final bool sent;
  final bool delivered;
  final bool read;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<String> failedChannels;
  final String? errorMessage;
}

enum NotificationType {
  familyInvitation,
  invitationAccepted,
  noteShared,
  noteCommented,
  noteUpdated,
  memberJoined,
  memberLeft,
  permissionChanged,
  systemAlert,
  backupCompleted
}

enum NotificationPriority {
  emergency, // Family safety alerts
  high,      // Invitations, urgent updates
  normal,    // Regular activity
  low        // Background sync notifications
}
```

**Validation Rules**:
- Title: 1-100 characters
- Body: 1-500 characters
- Payload size limit: 4KB
- Retention period: 30 days for normal, 90 days for emergency
- Batch size limit: 100 notifications

### Invitation
**Purpose**: Family member invitation management
**Current State**: Basic invitation structure, needs delivery and tracking
**Extensions Needed**: Expiration handling, resend capability, analytics

```dart
class FamilyInvitation {
  final String id;
  final String familyId;
  final String familyName;
  final String invitedBy;
  final String email;
  final String role;
  final Map<String, bool> permissions;
  final DateTime createdAt;
  final DateTime expiresAt;
  
  // New fields for TODO completion
  final InvitationStatus status;
  final List<InvitationDelivery> deliveries;
  final String? customMessage;
  final InvitationMetadata metadata;
}

class InvitationDelivery {
  final String channel; // email, sms, push
  final DateTime sentAt;
  final bool delivered;
  final String? errorMessage;
  final int retryCount;
}

enum InvitationStatus {
  pending,
  sent,
  delivered,
  viewed,
  accepted,
  declined,
  expired,
  revoked
}

class InvitationMetadata {
  final String? inviterNote;
  final Map<String, dynamic> inviteeInfo;
  final List<String> requiredCapabilities;
  final bool requiresVerification;
}
```

**Validation Rules**:
- Email format validation required
- Expiration: 7 days default, 30 days maximum
- Maximum 3 pending invitations per family
- Retry limit: 3 attempts per channel

### Voice Session
**Purpose**: Voice input and processing session management
**Current State**: Mock implementation, needs real speech processing
**Extensions Needed**: Platform integration, processing status, history

```dart
class VoiceSession {
  final String id;
  final String userId;
  final String? noteId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final VoiceSessionStatus status;
  
  // New fields for TODO completion
  final AudioMetadata audio;
  final SpeechRecognitionResult recognition;
  final VoiceCommand? command;
  final ProcessingMetadata processing;
}

class AudioMetadata {
  final Duration recordingDuration;
  final String encoding;
  final int sampleRate;
  final double quality;
  final String? localFilePath;
}

class SpeechRecognitionResult {
  final String transcript;
  final double confidence;
  final List<String> alternatives;
  final List<TimedWord> words;
  final String language;
  final bool isComplete;
}

class VoiceCommand {
  final String action; // "add_note", "share_with", "set_reminder"
  final Map<String, dynamic> parameters;
  final double confidence;
  final String extractedText;
}

enum VoiceSessionStatus {
  recording,
  processing,
  completed,
  failed,
  cancelled
}
```

**Validation Rules**:
- Maximum recording duration: 5 minutes
- Supported formats: AAC, MP3
- Auto-cleanup recordings after 24 hours
- Processing timeout: 30 seconds

### Backup Archive
**Purpose**: Encrypted backup data management
**Current State**: Mock backup operations, needs real encryption and storage
**Extensions Needed**: Encryption metadata, restore capabilities, version management

```dart
class BackupArchive {
  final String id;
  final String userId;
  final String familyId;
  final DateTime createdAt;
  final BackupType type;
  final int size;
  final String checksum;
  
  // New fields for TODO completion
  final EncryptionMetadata encryption;
  final StorageLocation storage;
  final BackupManifest manifest;
  final RestoreMetadata? lastRestore;
}

class EncryptionMetadata {
  final String algorithm; // AES-256-GCM
  final String keyDerivation; // PBKDF2
  final String salt;
  final int iterations;
  final bool isEncrypted;
}

class StorageLocation {
  final String provider; // firebase, local, google_drive, icloud
  final String path;
  final String? externalId;
  final DateTime uploadedAt;
  final bool isAccessible;
}

class BackupManifest {
  final List<String> includedDataTypes;
  final Map<String, int> recordCounts;
  final String appVersion;
  final Map<String, dynamic> metadata;
}

enum BackupType {
  full,
  incremental,
  familyData,
  personalData,
  settings
}
```

**Validation Rules**:
- Maximum backup size: 100MB per archive
- Retention: 30 days for automatic, unlimited for manual
- Encryption required for cloud storage
- Manifest must match actual data

## Relationships

### Family ↔ Members
- One-to-many: Family has multiple FamilyMembers
- Cascade delete: Removing family removes all memberships
- Constraint: Family must have at least one owner

### Family ↔ Shared Notes
- One-to-many: Family can have multiple SharedNotes
- Cascade delete: Family deletion archives shared notes
- Constraint: Note sharing requires family membership

### Member ↔ Notifications
- One-to-many: Member receives multiple Notifications
- Cascade delete: Member removal deletes their notifications
- Constraint: Notifications require valid recipient

### Family ↔ Invitations
- One-to-many: Family can have multiple pending Invitations
- Auto-cleanup: Expired invitations are automatically removed
- Constraint: Cannot invite existing family members

### User ↔ Voice Sessions
- One-to-many: User can have multiple VoiceSessions
- Auto-cleanup: Sessions older than 7 days are purged
- Constraint: One active session per user

### Family ↔ Backup Archives
- One-to-many: Family data can have multiple BackupArchives
- Retention policy: Based on backup type and age
- Constraint: Backup requires family membership

## Data Migration Considerations

### Existing Data Compatibility
- All current family data structures remain valid
- New fields have default values or are optional
- Existing notes automatically become "legacy" shared notes
- Current permissions map to new permission system

### Migration Steps
1. Add new optional fields to existing models
2. Create migration scripts for data transformation
3. Update service interfaces to handle new fields
4. Implement backward compatibility layers
5. Gradual rollout with feature flags

### Performance Considerations
- Index on frequently queried fields (familyId, userId, createdAt)
- Implement pagination for large datasets
- Use compression for backup archives
- Optimize real-time listener queries
- Cache notification preferences

## Validation Summary

All data models include:
- Comprehensive input validation
- State transition rules
- Size and count limits
- Expiration and cleanup policies
- Security and privacy considerations
- Performance optimization guidelines

The models support the complete implementation of all TODO items while maintaining the existing architecture and ensuring data integrity for family collaboration scenarios.