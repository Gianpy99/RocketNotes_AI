# Data Model: Family Management

**Date**: 2025-09-07
**Feature**: Family Management
**Source**: Feature specification requirements

## Overview
This document defines the data entities required for family management functionality in RocketNotes AI. All models extend the existing architecture while maintaining compatibility with current Firebase and Hive implementations.

## Core Entities

### Family
Represents a family group that can share notes and collaborate.

```dart
class Family {
  final String id;
  final String name;
  final String adminUserId;
  final DateTime createdAt;
  final List<String> memberIds;
  final FamilySettings settings;
  final DateTime updatedAt;

  Family({
    required this.id,
    required this.name,
    required this.adminUserId,
    required this.createdAt,
    required this.memberIds,
    required this.settings,
    required this.updatedAt,
  });
}
```

**Fields**:
- `id`: Unique identifier (UUID)
- `name`: Display name for the family
- `adminUserId`: User ID of the family administrator
- `createdAt`: When the family was created
- `memberIds`: List of all member user IDs
- `settings`: Family-wide settings and preferences
- `updatedAt`: Last modification timestamp

**Relationships**:
- One-to-many with FamilyMember
- One-to-many with SharedNote
- One-to-one with FamilySettings

### FamilyMember
Represents an individual user within a family with specific permissions.

```dart
class FamilyMember {
  final String userId;
  final String familyId;
  final FamilyRole role;
  final MemberPermissions permissions;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final bool isActive;

  FamilyMember({
    required this.userId,
    required this.familyId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    this.lastActiveAt,
    this.isActive = true,
  });
}
```

**Fields**:
- `userId`: Reference to the user account
- `familyId`: Reference to the family
- `role`: Owner, Admin, Editor, Viewer, Limited
- `permissions`: Granular permission flags
- `joinedAt`: When the user joined the family
- `lastActiveAt`: Last activity timestamp
- `isActive`: Whether membership is active

### SharedNote
Represents a note that has been shared with family members.

```dart
class SharedNote {
  final String noteId;
  final String familyId;
  final String sharedByUserId;
  final NotePermissions permissions;
  final DateTime sharedAt;
  final DateTime? expiresAt;
  final List<String> allowedMemberIds;
  final Map<String, NoteComment> comments;

  SharedNote({
    required this.noteId,
    required this.familyId,
    required this.sharedByUserId,
    required this.permissions,
    required this.sharedAt,
    this.expiresAt,
    required this.allowedMemberIds,
    required this.comments,
  });
}
```

**Fields**:
- `noteId`: Reference to the original note
- `familyId`: Family this note is shared with
- `sharedByUserId`: User who shared the note
- `permissions`: What actions are allowed on this shared note
- `sharedAt`: When the note was shared
- `expiresAt`: Optional expiration date
- `allowedMemberIds`: Specific members who can access (empty = all family)
- `comments`: Comments from family members

### FamilyInvitation
Represents a pending invitation for a user to join a family.

```dart
class FamilyInvitation {
  final String id;
  final String familyId;
  final String invitedEmail;
  final String inviterUserId;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.invitedEmail,
    required this.inviterUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
  });
}
```

## Supporting Types

### FamilyRole
Enumeration of possible roles within a family.

```dart
enum FamilyRole {
  owner,    // Full control, can delete family
  admin,    // Can manage members and permissions
  editor,   // Can share notes and edit shared content
  viewer,   // Read-only access to shared notes
  limited   // Access only to specific shared notes
}
```

### MemberPermissions
Granular permissions for family members.

```dart
class MemberPermissions {
  final bool canInviteMembers;
  final bool canRemoveMembers;
  final bool canShareNotes;
  final bool canEditSharedNotes;
  final bool canDeleteSharedNotes;
  final bool canManagePermissions;

  MemberPermissions({
    required this.canInviteMembers,
    required this.canRemoveMembers,
    required this.canShareNotes,
    required this.canEditSharedNotes,
    required this.canDeleteSharedNotes,
    required this.canManagePermissions,
  });
}
```

### NotePermissions
Permissions for shared notes.

```dart
class NotePermissions {
  final bool canRead;
  final bool canEdit;
  final bool canComment;
  final bool canShare;
  final bool canDelete;

  NotePermissions({
    required this.canRead,
    required this.canEdit,
    required this.canComment,
    required this.canShare,
    required this.canDelete,
  });
}
```

### FamilySettings
Family-wide configuration settings.

```dart
class FamilySettings {
  final bool allowPublicSharing;
  final bool requireApprovalForSharing;
  final int maxMembers;
  final Duration defaultNoteExpiration;
  final bool enableRealTimeSync;
  final NotificationPreferences notifications;

  FamilySettings({
    required this.allowPublicSharing,
    required this.requireApprovalForSharing,
    required this.maxMembers,
    required this.defaultNoteExpiration,
    required this.enableRealTimeSync,
    required this.notifications,
  });
}
```

### NoteComment
Comments on shared notes.

```dart
class NoteComment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final List<String> mentionedUserIds;

  NoteComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.editedAt,
    required this.mentionedUserIds,
  });
}
```

## Data Relationships

### Entity Relationship Diagram
```
Family (1) ──── (many) FamilyMember
   │
   ├── (many) SharedNote
   │       │
   │       └── (many) NoteComment
   │
   └── (many) FamilyInvitation
```

### Key Relationships
1. **Family → FamilyMember**: One family has multiple members
2. **Family → SharedNote**: One family can have multiple shared notes
3. **SharedNote → NoteComment**: One shared note can have multiple comments
4. **Family → FamilyInvitation**: One family can have multiple pending invitations
5. **User → FamilyMember**: One user can be member of multiple families (future feature)

## Storage Strategy

### Firebase Firestore Collections
```
/families/{familyId}
  - Family document

/families/{familyId}/members/{userId}
  - FamilyMember document

/families/{familyId}/shared-notes/{noteId}
  - SharedNote document

/families/{familyId}/invitations/{invitationId}
  - FamilyInvitation document

/families/{familyId}/comments/{commentId}
  - NoteComment document
```

### Local Storage (Hive)
- Family data cached locally for offline access
- Shared notes stored locally when accessed
- Sync status tracked for conflict resolution
- User permissions cached for fast access checks

## Validation Rules

### Family Validation
- Name: 1-50 characters, alphanumeric + spaces
- Max members: 1-10 (configurable)
- Admin must be an active member
- Cannot delete family with active members

### Member Validation
- User must exist and be active
- Cannot have duplicate members in same family
- Role must be valid enum value
- Permissions must be consistent with role

### Shared Note Validation
- Note must exist and be owned by sharer
- At least one permission must be granted
- Expiration date must be in future (if set)
- Allowed members must exist in family

## Migration Strategy

### From Single-User to Family Model
1. Create default family for existing users
2. Migrate existing notes to personal family notes
3. Update user profiles with family membership
4. Maintain backward compatibility for single-user features

### Data Migration Steps
1. Backup all existing user data
2. Create family records for existing users
3. Update note ownership to family context
4. Migrate user permissions to family roles
5. Update Firebase security rules

## Performance Considerations

### Indexing Strategy
- Index on familyId for member queries
- Composite index on (familyId, sharedAt) for note listings
- Index on userId for cross-family membership queries

### Query Optimization
- Use pagination for large family member lists
- Implement caching for frequently accessed family data
- Optimize real-time listeners for shared note updates

### Storage Limits
- Max 10 members per family (enforced at application level)
- Max 1000 shared notes per family (soft limit)
- Max 100 comments per shared note (soft limit)
- Automatic cleanup of expired shared notes
