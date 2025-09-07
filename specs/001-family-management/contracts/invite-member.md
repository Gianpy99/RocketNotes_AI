# API Contract: Invite Family Member

**Endpoint**: `POST /api/families/{familyId}/invitations`
**Description**: Send an invitation for a user to join the family
**Authentication**: Required (Firebase Auth token + family membership)

## Request

### URL Parameters
- `familyId`: UUID of the family (string)

### Headers
```
Content-Type: application/json
Authorization: Bearer <firebase_token>
```

### Body
```json
{
  "email": "john.smith@example.com",
  "role": "editor",
  "customMessage": "Welcome to our family notes!",
  "permissions": {
    "canInviteMembers": false,
    "canRemoveMembers": false,
    "canShareNotes": true,
    "canEditSharedNotes": true,
    "canDeleteSharedNotes": false,
    "canManagePermissions": false
  }
}
```

### Schema Validation
```json
{
  "type": "object",
  "required": ["email", "role"],
  "properties": {
    "email": {
      "type": "string",
      "format": "email",
      "maxLength": 254
    },
    "role": {
      "type": "string",
      "enum": ["owner", "admin", "editor", "viewer", "limited"]
    },
    "customMessage": {
      "type": "string",
      "maxLength": 500
    },
    "permissions": {
      "type": "object",
      "properties": {
        "canInviteMembers": {"type": "boolean"},
        "canRemoveMembers": {"type": "boolean"},
        "canShareNotes": {"type": "boolean"},
        "canEditSharedNotes": {"type": "boolean"},
        "canDeleteSharedNotes": {"type": "boolean"},
        "canManagePermissions": {"type": "boolean"}
      }
    }
  }
}
```

## Response

### Success (201 Created)
```json
{
  "invitation": {
    "id": "inv_123456",
    "familyId": "family_123456",
    "invitedEmail": "john.smith@example.com",
    "inviterUserId": "user_789",
    "status": "pending",
    "role": "editor",
    "permissions": {
      "canInviteMembers": false,
      "canRemoveMembers": false,
      "canShareNotes": true,
      "canEditSharedNotes": true,
      "canDeleteSharedNotes": false,
      "canManagePermissions": false
    },
    "customMessage": "Welcome to our family notes!",
    "createdAt": "2025-09-07T10:35:00Z"
  },
  "family": {
    "id": "family_123456",
    "name": "Smith Family",
    "memberCount": 1,
    "pendingInvitations": 1
  }
}
```

### Error Responses

#### 400 Bad Request - Invalid Email
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Invalid email address format",
  "details": {
    "field": "email",
    "value": "invalid-email",
    "reason": "Must be valid email format"
  }
}
```

#### 403 Forbidden - Insufficient Permissions
```json
{
  "error": "FORBIDDEN",
  "message": "Insufficient permissions to invite members",
  "details": {
    "requiredPermission": "canInviteMembers",
    "userRole": "editor"
  }
}
```

#### 409 Conflict - User Already Invited
```json
{
  "error": "CONFLICT",
  "message": "User already has a pending invitation to this family",
  "details": {
    "existingInvitationId": "inv_999999",
    "invitedAt": "2025-09-06T15:20:00Z"
  }
}
```

#### 409 Conflict - User Already Member
```json
{
  "error": "CONFLICT",
  "message": "User is already a member of this family",
  "details": {
    "memberSince": "2025-08-01T09:00:00Z",
    "currentRole": "viewer"
  }
}
```

## Business Rules

### Pre-conditions
- User must be authenticated and family member
- User must have `canInviteMembers` permission
- Family must exist and user must be active member
- Invited email must not already be invited or member
- Family must not be at max capacity

### Post-conditions
- Invitation record created with pending status
- Email notification sent to invited user
- Family's pending invitations count updated
- Audit log entry created

### Side Effects
- Email sent with invitation link and custom message
- Push notification sent to inviter confirming invitation sent
- Family activity log updated

## Performance Requirements
- Response time: <300ms (95th percentile)
- Email delivery: <5 seconds (asynchronous)
- Database: Single transaction for invitation creation

## Security Considerations
- Email validation to prevent spam invitations
- Rate limiting: Max 10 invitations per user per hour
- Invitation tokens with expiration (24 hours)
- CSRF protection for web clients
- Input sanitization for custom messages
