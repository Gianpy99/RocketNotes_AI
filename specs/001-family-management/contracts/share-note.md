# API Contract: Share Note with Family

**Endpoint**: `PUT /api/notes/{noteId}/share`
**Description**: Share an existing note with family members
**Authentication**: Required (Firebase Auth token + note ownership)

## Request

### URL Parameters
- `noteId`: UUID of the note to share (string)

### Headers
```
Content-Type: application/json
Authorization: Bearer <firebase_token>
```

### Body
```json
{
  "familyId": "family_123456",
  "permissions": {
    "canRead": true,
    "canEdit": true,
    "canComment": true,
    "canShare": false,
    "canDelete": false
  },
  "allowedMemberIds": ["user_111", "user_222"],
  "expiresAt": "2025-10-07T10:30:00Z",
  "message": "Check out this shopping list for the party!"
}
```

### Schema Validation
```json
{
  "type": "object",
  "required": ["familyId", "permissions"],
  "properties": {
    "familyId": {
      "type": "string",
      "pattern": "^family_[a-f0-9]{6}$"
    },
    "permissions": {
      "type": "object",
      "required": ["canRead"],
      "properties": {
        "canRead": {"type": "boolean"},
        "canEdit": {"type": "boolean"},
        "canComment": {"type": "boolean"},
        "canShare": {"type": "boolean"},
        "canDelete": {"type": "boolean"}
      }
    },
    "allowedMemberIds": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^user_[a-f0-9]{3}$"
      },
      "maxItems": 50
    },
    "expiresAt": {
      "type": "string",
      "format": "date-time"
    },
    "message": {
      "type": "string",
      "maxLength": 200
    }
  }
}
```

## Response

### Success (200 OK)
```json
{
  "sharedNote": {
    "noteId": "note_789",
    "familyId": "family_123456",
    "sharedByUserId": "user_789",
    "permissions": {
      "canRead": true,
      "canEdit": true,
      "canComment": true,
      "canShare": false,
      "canDelete": false
    },
    "allowedMemberIds": ["user_111", "user_222"],
    "expiresAt": "2025-10-07T10:30:00Z",
    "message": "Check out this shopping list for the party!",
    "sharedAt": "2025-09-07T10:40:00Z",
    "comments": {}
  },
  "note": {
    "id": "note_789",
    "title": "Party Shopping List",
    "content": "Cake, drinks, decorations...",
    "updatedAt": "2025-09-07T10:40:00Z"
  },
  "family": {
    "id": "family_123456",
    "name": "Smith Family",
    "sharedNotesCount": 5
  }
}
```

### Error Responses

#### 400 Bad Request - Invalid Permissions
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Invalid permission combination",
  "details": {
    "reason": "canEdit requires canRead to be true",
    "provided": {"canRead": false, "canEdit": true}
  }
}
```

#### 403 Forbidden - Not Family Member
```json
{
  "error": "FORBIDDEN",
  "message": "User is not a member of the specified family",
  "details": {
    "familyId": "family_123456",
    "userId": "user_999"
  }
}
```

#### 404 Not Found - Note Not Found
```json
{
  "error": "NOT_FOUND",
  "message": "Note not found or access denied",
  "details": {
    "noteId": "note_789",
    "reason": "Note may not exist or user lacks ownership"
  }
}
```

#### 409 Conflict - Note Already Shared
```json
{
  "error": "CONFLICT",
  "message": "Note is already shared with this family",
  "details": {
    "existingShareId": "share_456",
    "sharedAt": "2025-09-05T14:20:00Z"
  }
}
```

## Business Rules

### Pre-conditions
- User must own the note or have edit permissions
- User must be active member of the target family
- Note must not already be shared with the family
- If allowedMemberIds specified, all must be family members
- Expiration date must be in future (if provided)

### Post-conditions
- SharedNote record created in database
- Note marked as shared in user's note list
- Family members notified of new shared note
- Audit log entry created for sharing action

### Side Effects
- Push notifications sent to allowed family members
- Family activity feed updated
- Note access permissions updated in security rules
- Real-time sync triggered for affected users

## Performance Requirements
- Response time: <400ms (95th percentile)
- Notification delivery: <3 seconds (asynchronous)
- Database: Atomic note sharing transaction
- Security rules update: <1 second

## Security Considerations
- Validate note ownership before sharing
- Ensure user has family membership
- Sanitize sharing message content
- Rate limiting: Max 50 shares per user per hour
- Audit all sharing activities for compliance
- Encrypt shared note content in transit
