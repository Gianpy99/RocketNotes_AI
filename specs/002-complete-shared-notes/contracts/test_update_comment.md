# Contract Test: Update Comment

**Test File**: `test_update_comment.dart`
**API Endpoint**: `PUT /api/comments/{commentId}`
**Purpose**: Verify comment update contract

## Test Scenarios

### Scenario 1: Successful Comment Update
**Given** user owns the comment
**When** PUT request is made to update comment
**Then** comment should be updated with edit tracking

#### Request
```http
PUT /api/comments/comment_456
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "content": "This is an updated comment with corrections."
}
```

#### Expected Response (200 OK)
```json
{
  "success": true,
  "data": {
    "id": "comment_456",
    "content": "This is an updated comment with corrections.",
    "isEdited": true,
    "updatedAt": "2025-09-08T11:00:00Z",
    "lastEditedAt": "2025-09-08T11:00:00Z",
    "lastEditedBy": "user_789"
  }
}
```

## Contract Validation Rules
- [ ] Authorization header required
- [ ] Valid Bearer token format
- [ ] Comment and user IDs must exist
- [ ] Content must be non-empty
- [ ] Success response includes updated comment data
- [ ] Error response for invalid input
