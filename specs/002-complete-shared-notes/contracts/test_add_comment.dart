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
    "familyMemberId": "member_101",
    "content": "This is a great recipe! Thanks for sharing.",
    "parentCommentId": null,
    "replies": [],
    "depth": 0,
    "likedBy": [],
    "likeCount": 0,
    "isEdited": false,
    "isDeleted": false,
    "createdAt": "2025-09-08T10:30:00Z",
    "updatedAt": "2025-09-08T10:30:00Z"
  }
}
```

### Scenario 2: Reply to Comment
**Given** user wants to reply to existing comment
**When** POST request includes parentCommentId
**Then** reply should be created with proper threading

#### Request
```http
POST /api/shared-notes/note_123/comments
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "content": "I agree, it's delicious!",
  "parentCommentId": "comment_456"
}
```

#### Expected Response (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "reply_789",
    "noteId": "note_123",
    "userId": "user_999",
    "content": "I agree, it's delicious!",
    "parentCommentId": "comment_456",
    "depth": 1,
    "createdAt": "2025-09-08T10:35:00Z"
  }
}
```

### Scenario 3: Invalid Content
**Given** comment content is empty or too long
**When** POST request is made
**Then** validation error should be returned

#### Expected Response (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Comment content is required",
    "details": {
      "field": "content",
      "minLength": 1,
      "maxLength": 1000
    }
  }
}
```

## Contract Validation Rules

### Request Validation
- [ ] Content must be 1-1000 characters
- [ ] parentCommentId must be valid if provided
- [ ] User must have read access to the note
- [ ] Note must exist and not be deleted

### Response Validation
- [ ] Success returns complete comment object
- [ ] Reply objects have correct depth and parent references
- [ ] Timestamps are current and in correct format
- [ ] User information is properly resolved

### Real-time Updates
- [ ] Comment creation triggers real-time updates
- [ ] All users viewing the note receive the new comment
- [ ] Comment count updates in note metadata
