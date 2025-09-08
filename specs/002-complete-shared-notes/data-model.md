# Data Model: Complete Shared Notes Implementation

**Date**: 8 settembre 2025
**Scope**: Data models and relationships for shared notes system

## Overview

The shared notes system requires a comprehensive data model that supports family collaboration, permission-based access control, threaded comments, and real-time synchronization. This document defines the complete data structure needed to implement all TODO items.

## Core Entities

### 1. User (Authentication Context)
```dart
class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;

  // Relationships
  final List<String> familyIds; // Families this user belongs to
}
```

### 2. Family (Collaboration Group)
```dart
class Family {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Settings
  final FamilySettings settings;
  final NotificationPreferences notifications;
  final ActivityDigestFrequency activityFrequency;

  // Relationships
  final List<String> memberIds;
  final List<String> adminIds;
}
```

### 3. FamilyMember (User Role in Family)
```dart
class FamilyMember {
  final String id;
  final String familyId;
  final String userId;
  final FamilyRole role;
  final DateTime joinedAt;
  final MemberPermissions permissions;

  // Display information
  final String displayName;
  final String? avatarUrl;
}
```

### 4. SharedNote (Core Collaboration Object)
```dart
class SharedNote {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Sharing context
  final String familyId;
  final List<String> sharedWith; // Family member IDs
  final List<NotePermission> permissions;

  // Metadata
  final NoteMetadata metadata;
  final List<String> tags;
  final bool isArchived;
}
```

### 5. NotePermission (Access Control)
```dart
class NotePermission {
  final String id;
  final String noteId;
  final String userId;
  final String familyMemberId;
  final PermissionLevel level; // read, write, admin
  final DateTime grantedAt;
  final String grantedBy;
  final DateTime? expiresAt;
}
```

### 6. SharedNoteComment (Discussion Thread)
```dart
class SharedNoteComment {
  final String id;
  final String noteId;
  final String userId;
  final String familyMemberId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Threading support
  final String? parentCommentId; // For replies
  final List<String> replyIds;
  final int depth; // Nesting level

  // Engagement
  final List<String> likedBy;
  final int likeCount;

  // Moderation
  final bool isEdited;
  final bool isDeleted;
  final String? deletedBy;
}
```

### 7. CommentReply (Reply Structure)
```dart
class CommentReply {
  final String id;
  final String commentId;
  final String userId;
  final String familyMemberId;
  final String content;
  final DateTime createdAt;

  // Engagement
  final List<String> likedBy;
  final int likeCount;
}
```

## Supporting Entities

### 8. FamilySettings
```dart
class FamilySettings {
  final bool allowPublicSharing;
  final bool requireApproval;
  final int maxMembers;
  final StorageLimit storageLimit;
}
```

### 9. NotificationPreferences
```dart
class NotificationPreferences {
  final bool newNotes;
  final bool newComments;
  final bool mentions;
  final bool activityDigest;
  final List<String> mutedUsers;
}
```

### 10. MemberPermissions
```dart
class MemberPermissions {
  final bool canShareNotes;
  final bool canInviteMembers;
  final bool canManageSettings;
  final bool canModerateComments;
}
```

### 11. NoteMetadata
```dart
class NoteMetadata {
  final int wordCount;
  final int characterCount;
  final List<String> mentionedUsers;
  final DateTime lastEditedAt;
  final String lastEditedBy;
}
```

## Data Relationships

### Entity Relationship Diagram
```
User (1) ──── (M) FamilyMember (M) ──── (1) Family
  │                                        │
  │                                        │
  └── (M) SharedNote (1) ──── (M) NotePermission
           │                           │
           │                           │
           └── (M) SharedNoteComment ──┘
                    │
                    │
                    └── (M) CommentReply
```

### Key Relationships
1. **User ↔ FamilyMember**: Many-to-many through family membership
2. **Family ↔ SharedNote**: One-to-many (family contains notes)
3. **SharedNote ↔ NotePermission**: One-to-many (note has permissions)
4. **SharedNote ↔ SharedNoteComment**: One-to-many (note has comments)
5. **SharedNoteComment ↔ CommentReply**: One-to-many (comment has replies)
6. **SharedNoteComment ↔ SharedNoteComment**: Self-referencing for threading

## Data Flow Patterns

### 1. Note Sharing Flow
```
User → Select Family Members → Create Permissions → Share Note
    ↓              ↓                    ↓            ↓
Validate → Generate IDs → Store Permissions → Update Note
Members    Permissions     in Firestore      Metadata
```

### 2. Comment Creation Flow
```
User → Write Comment → Validate Content → Store Comment → Update UI
    ↓         ↓              ↓                ↓            ↓
Check → Sanitize Input → Check Permissions → Save to DB → Real-time
Permissions  Content        User Access       Firestore    Update
```

### 3. Reply Threading Flow
```
Parent → Create Reply → Link to Parent → Update Thread → Refresh UI
Comment   Content       Comment ID       Hierarchy     Display
```

## Firebase Data Structure

### Firestore Collections
```
/families/{familyId}
  ├── members: [familyMemberId1, familyMemberId2, ...]
  ├── settings: FamilySettings
  └── metadata: {createdAt, updatedAt, ...}

/users/{userId}
  ├── profile: User
  └── families: [familyId1, familyId2, ...]

/sharedNotes/{noteId}
  ├── content: SharedNote
  ├── permissions: [permissionId1, permissionId2, ...]
  └── comments: [commentId1, commentId2, ...]

/permissions/{permissionId}
  └── data: NotePermission

/comments/{commentId}
  ├── content: SharedNoteComment
  └── replies: [replyId1, replyId2, ...]

/replies/{replyId}
  └── content: CommentReply
```

### Real-time Subscriptions
- **Family Updates**: Listen to `/families/{familyId}` for member changes
- **Note Permissions**: Listen to `/permissions` for access changes
- **Comments**: Listen to `/comments` for new comments and replies
- **User Status**: Listen to `/users/{userId}` for profile updates

## Data Validation Rules

### 1. User Validation
- Email format validation
- Display name length (2-50 characters)
- Unique email constraint
- Password strength requirements

### 2. Family Validation
- Name length (3-100 characters)
- Description length (0-500 characters)
- Max members limit (configurable)
- Admin privileges required for sensitive operations

### 3. Note Validation
- Title length (1-200 characters)
- Content size limits
- Permission validation (at least one valid member)
- Tag validation (alphanumeric, max 20 chars each)

### 4. Comment Validation
- Content length (1-1000 characters)
- User permission check
- Parent comment existence (for replies)
- Depth limit (max 5 levels for replies)

## Security Model

### Access Control Levels
1. **Public**: Anyone in family can access
2. **Restricted**: Only specific members can access
3. **Private**: Only creator can access
4. **Admin**: Full control including deletion

### Permission Inheritance
- Family admins have implicit access to all notes
- Note creators have admin rights on their notes
- Permissions can be granted/revoked by note admins
- Comment permissions follow note permissions

## Performance Considerations

### Indexing Strategy
- **User Queries**: Index on `email`, `familyIds`
- **Note Queries**: Index on `familyId`, `createdBy`, `updatedAt`
- **Comment Queries**: Index on `noteId`, `createdAt`, `parentCommentId`
- **Permission Queries**: Index on `userId`, `noteId`

### Caching Strategy
- **User Profiles**: Cache in Hive for offline access
- **Family Members**: Cache for member selection
- **Recent Notes**: Cache last 50 accessed notes
- **Comment Threads**: Cache active conversation threads

### Query Optimization
- Use compound queries for filtered results
- Implement pagination for large datasets
- Use real-time listeners sparingly
- Batch operations for bulk updates

## Migration Strategy

### Data Migration Path
1. **Phase 1**: Add new fields to existing documents
2. **Phase 2**: Migrate existing data to new structure
3. **Phase 3**: Update application code to use new fields
4. **Phase 4**: Remove deprecated fields

### Backward Compatibility
- Support old data format during transition
- Graceful handling of missing fields
- Version detection for data migration
- Rollback capability for critical issues

## Implementation Checklist

### Data Model Completeness
- [x] All entities defined with proper relationships
- [x] Firebase structure documented
- [x] Validation rules specified
- [x] Security model defined
- [x] Performance considerations addressed

### Integration Points
- [x] Authentication integration
- [x] Real-time synchronization
- [x] Offline caching strategy
- [x] Error handling patterns
- [x] Migration strategy

This data model provides a solid foundation for implementing all the TODO items in the shared notes system, ensuring proper data relationships, security, and performance.
