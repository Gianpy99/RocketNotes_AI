# Contract Test: Share Note

**Test File**: `test_share_note.dart`
**API Endpoint**: `POST /api/shared-notes`
**Purpose**: Verify note sharing contract with member selection UI

## Test Scenarios

### Scenario 1: Successful Note Sharing with Member Selection
**Given** user has a note and selects family members via UI
**When** POST request is made to `/api/shared-notes` with selected members
**Then** note should be shared with specified permissions

#### UI Features Implemented (T007-T010)
- [x] **T007**: Member selection UI with checkboxes ✅ COMPLETED
- [x] **T008**: Display actual member names instead of user IDs ✅ COMPLETED
- [x] **T009**: Member search/filter functionality ✅ COMPLETED
- [x] **T010**: Handle empty family state gracefully ✅ COMPLETED

#### Request
```http
POST /api/shared-notes
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "noteId": "note_123",
  "familyId": "family_789",
  "sharedWith": ["user_456", "user_789"],
  "permissions": [
    {
      "userId": "user_456",
      "userDisplayName": "John Doe",
      "level": "write"
    },
    {
      "userId": "user_789",
      "userDisplayName": "Jane Smith",
      "level": "read"
    }
  ]
}
```

#### Expected Response (201 Created)
```json
{
  "success": true,
  "data": {
    "sharedNoteId": "shared_note_123",
    "noteId": "note_123",
    "sharedAt": "2025-09-08T10:00:00Z",
    "permissions": [
      {
        "id": "perm_456",
        "userId": "user_456",
        "userDisplayName": "John Doe",
        "level": "write",
        "grantedAt": "2025-09-08T10:00:00Z"
      }
    ]
  }
}
```

### Scenario 2: Invalid Permissions
**Given** user tries to share with invalid permissions
**When** POST request is made with invalid data
**Then** response should be validation error

#### Expected Response (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid permission level",
    "details": {
      "field": "permissions[0].level",
      "value": "invalid",
      "allowed": ["read", "write", "admin"]
    }
  }
}
```

### Scenario 3: Unauthorized Sharing
**Given** user tries to share note they don't own
**When** POST request is made
**Then** response should be forbidden

#### Expected Response (403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Cannot share note you don't own"
  }
}
```

## Contract Validation Rules

### Request Validation
- [ ] noteId must exist and be accessible by user
- [ ] familyId must be valid and user must be member
- [ ] sharedWith array must contain valid user IDs
- [ ] permissions array must match sharedWith users
- [ ] permission levels must be valid enum values

### Response Validation
- [ ] Success returns shared note ID and permissions
- [ ] Error responses include specific error codes
- [ ] Timestamps in correct format
- [ ] Permission objects properly structured

### Business Rules
- [ ] Users can only share their own notes
- [ ] Users can only share with family members
- [ ] Permission levels must be valid
- [ ] Duplicate permissions not allowed
