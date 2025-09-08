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

### Scenario 2: Unauthorized Update
**Given** user tries to edit someone else's comment
**When** PUT request is made
**Then** forbidden error should be returned

#### Expected Response (403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Cannot edit comment you don't own"
  }
}
```

### Scenario 3: Comment Not Found
**Given** comment ID doesn't exist
**When** PUT request is made
**Then** not found error should be returned

#### Expected Response (404 Not Found)
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Comment not found"
  }
}
```

## Contract Validation Rules

### Request Validation
- [ ] Comment must exist and not be deleted
- [ ] User must be the comment author
- [ ] Content must meet validation requirements
- [ ] Comment must belong to accessible note

### Response Validation
- [ ] Success returns updated comment data
- [ ] isEdited flag set to true
- [ ] Timestamps updated correctly
- [ ] Edit tracking information included

### Business Rules
- [ ] Only comment authors can edit
- [ ] Edit history should be preserved
- [ ] Real-time updates should notify all viewers
- [ ] Edit status should be visible in UI
