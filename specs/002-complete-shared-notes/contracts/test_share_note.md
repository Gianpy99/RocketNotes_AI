# Contract Test: Share Note

**Test File**: `test_share_note.dart`
**API Endpoint**: `POST /api/shared-notes`
**Purpose**: Verify note sharing contract with member selection UI

## Test Scenarios

### Scenario 1: Successful Note Sharing with Member Selection
**Given** user has a note and selects family members via UI
**When** POST request is made to `/api/shared-notes` with selected members
**Then** note should be shared with specified permissions

#### UI Features Implemented (T007-T010, T011-T015)
- [x] **T007**: Member selection UI with checkboxes ✅ COMPLETED
- [x] **T008**: Display actual member names instead of user IDs ✅ COMPLETED
- [x] **T009**: Member search/filter functionality ✅ COMPLETED
- [x] **T010**: Handle empty family state gracefully ✅ COMPLETED
- [x] **T011**: Current user ID retrieval in note_sharing_screen ✅ COMPLETED
- [x] **T012**: Current user ID retrieval in shared_note_viewer ✅ COMPLETED
- [x] **T013**: Member ID resolution for permission creation ✅ COMPLETED
- [x] **T014**: User authentication state validation ✅ COMPLETED
- [x] **T015**: Handle user session expiration gracefully ✅ COMPLETED

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
    }
  ]
}
```

#### Expected Response (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "note_123",
    "sharedWith": ["user_456", "user_789"],
    "permissions": [
      {
        "userId": "user_456",
        "userDisplayName": "John Doe",
        "level": "write"
      }
    ]
  }
}
```

## Contract Validation Rules
- [ ] Authorization header required
- [ ] Valid Bearer token format
- [ ] Note and family IDs must exist
- [ ] Permissions array must match schema
- [ ] Success response includes shared note data
- [ ] Error response for invalid input
