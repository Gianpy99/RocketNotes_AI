# Contract Test: Add Comment

**Test File**: `test_add_comment.dart`
**API Endpoint**: `POST /api/shared-notes/{noteId}/comments`
**Purpose**: Verify comment creation contract

## Test Scenarios

### Scenario 1: Successful Comment Creation
**Given** user has access to shared note
**When** POST request is made to add comment
**Then** comment should be created and returned

#### Request
```http
POST /api/shared-notes/note_123/comments
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "content": "This is a great recipe! Thanks for sharing.",
  "parentCommentId": null
}
```

#### Expected Response (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "comment_456",
    "noteId": "note_123",
    "userId": "user_789",
    "userDisplayName": "John Doe",
    "familyMemberId": "member_101",
    "content": "This is a great recipe! Thanks for sharing.",
    "parentCommentId": null,
    "replies": [],
    "depth": 0,
    "likedBy": []
  }
}
```

## Contract Validation Rules
- [ ] Authorization header required
- [ ] Valid Bearer token format
- [ ] Note and user IDs must exist
- [ ] Content must be non-empty
- [ ] Success response includes comment data
- [ ] Error response for invalid input
