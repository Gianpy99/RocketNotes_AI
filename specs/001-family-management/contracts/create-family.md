# API Contract: Create Family

**Endpoint**: `POST /api/families`
**Description**: Create a new family group
**Authentication**: Required (Firebase Auth token)

## Request

### Headers
```
Content-Type: application/json
Authorization: Bearer <firebase_token>
```

### Body
```json
{
  "name": "Smith Family",
  "settings": {
    "allowPublicSharing": false,
    "requireApprovalForSharing": true,
    "maxMembers": 10,
    "defaultNoteExpiration": "P30D",
    "enableRealTimeSync": true,
    "notifications": {
      "emailInvitations": true,
      "pushNotifications": true,
      "activityDigest": "weekly"
    }
  }
}
```

### Schema Validation
```json
{
  "type": "object",
  "required": ["name"],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 50,
      "pattern": "^[a-zA-Z0-9\\s]+$"
    },
    "settings": {
      "type": "object",
      "properties": {
        "allowPublicSharing": {"type": "boolean"},
        "requireApprovalForSharing": {"type": "boolean"},
        "maxMembers": {"type": "integer", "minimum": 1, "maximum": 20},
        "defaultNoteExpiration": {"type": "string", "format": "duration"},
        "enableRealTimeSync": {"type": "boolean"},
        "notifications": {
          "type": "object",
          "properties": {
            "emailInvitations": {"type": "boolean"},
            "pushNotifications": {"type": "boolean"},
            "activityDigest": {"type": "string", "enum": ["never", "daily", "weekly"]}
          }
        }
      }
    }
  }
}
```

## Response

### Success (201 Created)
```json
{
  "family": {
    "id": "family_123456",
    "name": "Smith Family",
    "adminUserId": "user_789",
    "createdAt": "2025-09-07T10:30:00Z",
    "memberIds": ["user_789"],
    "settings": {
      "allowPublicSharing": false,
      "requireApprovalForSharing": true,
      "maxMembers": 10,
      "defaultNoteExpiration": "P30D",
      "enableRealTimeSync": true,
      "notifications": {
        "emailInvitations": true,
        "pushNotifications": true,
        "activityDigest": "weekly"
      }
    },
    "updatedAt": "2025-09-07T10:30:00Z"
  },
  "member": {
    "userId": "user_789",
    "familyId": "family_123456",
    "role": "owner",
    "permissions": {
      "canInviteMembers": true,
      "canRemoveMembers": true,
      "canShareNotes": true,
      "canEditSharedNotes": true,
      "canDeleteSharedNotes": true,
      "canManagePermissions": true
    },
    "joinedAt": "2025-09-07T10:30:00Z",
    "isActive": true
  }
}
```

### Error Responses

#### 400 Bad Request - Invalid Data
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Family name contains invalid characters",
  "details": {
    "field": "name",
    "value": "Smith@Family!",
    "reason": "Only alphanumeric characters and spaces allowed"
  }
}
```

#### 401 Unauthorized - Invalid Token
```json
{
  "error": "UNAUTHORIZED",
  "message": "Invalid or expired authentication token"
}
```

#### 409 Conflict - User Already in Family
```json
{
  "error": "CONFLICT",
  "message": "User is already a member of another family",
  "details": {
    "currentFamilyId": "family_999",
    "currentFamilyName": "Previous Family"
  }
}
```

## Business Rules

### Pre-conditions
- User must be authenticated
- User must not already be a member of another family
- Family name must be unique for the user (optional)

### Post-conditions
- Family record created in database
- User becomes family owner with full permissions
- Family settings initialized with defaults
- Audit log entry created

### Side Effects
- Firebase custom claims updated with family membership
- Welcome notification sent to user
- Family creation event logged for analytics

## Performance Requirements
- Response time: <500ms (95th percentile)
- Database transactions: Atomic family + member creation
- Rollback on failure: Complete cleanup of partial data

## Security Considerations
- Input validation and sanitization
- Rate limiting: Max 1 family creation per user per day
- Audit logging for compliance
- Data encryption at rest and in transit
