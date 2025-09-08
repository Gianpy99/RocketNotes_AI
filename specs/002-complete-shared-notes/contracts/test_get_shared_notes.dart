# Contract Test: Get Shared Notes

**Test File**: `test_get_shared_notes.dart`
**API Endpoint**: `GET /api/shared-notes`
**Purpose**: Verify shared notes retrieval contract

## Test Scenarios

### Scenario 1: Successful Retrieval
**Given** user is authenticated and has shared notes
**When** GET request is made to `/api/shared-notes`
**Then** response should contain user's shared notes

#### Request
```http
GET /api/shared-notes
Authorization: Bearer {user_token}
Content-Type: application/json
```

#### Expected Response (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": "note_123",
      "title": "Family Recipe",
      "content": "Secret family pasta recipe...",
      "createdBy": "user_456",
      "createdByDisplayName": "John Doe",
      "createdAt": "2025-09-08T10:00:00Z",
      "updatedAt": "2025-09-08T10:00:00Z",
      "familyId": "family_789",
      "sharedWith": ["user_456", "user_789"],
      "permissions": [
        {
          "userId": "user_456",
          "userDisplayName": "John Doe",
          "level": "write",
          "grantedAt": "2025-09-08T10:00:00Z"
        }
      ],
      "metadata": {
        "wordCount": 150,
        "lastEditedBy": "user_456"
      },
      "tags": ["recipe", "italian"],
      "isArchived": false
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "hasMore": false
  }
}
```

### Scenario 2: Empty Results
**Given** user is authenticated but has no shared notes
**When** GET request is made to `/api/shared-notes`
**Then** response should contain empty array

#### Expected Response (200 OK)
```json
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 0,
    "hasMore": false
  }
}
```

### Scenario 3: Unauthorized Access
**Given** request has invalid or missing token
**When** GET request is made to `/api/shared-notes`
**Then** response should be unauthorized

#### Expected Response (401 Unauthorized)
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

### Scenario 4: Filtering by Family
**Given** user belongs to multiple families
**When** GET request includes family filter
**Then** response should contain only notes from specified family

#### Request
```http
GET /api/shared-notes?familyId=family_789
Authorization: Bearer {user_token}
```

#### Expected Response (200 OK)
```json
{
  "success": true,
  "data": [
    // Only notes from family_789
  ]
}
```

## Contract Validation Rules

### Request Validation
- [ ] Authorization header required
- [ ] Valid Bearer token format
- [ ] Optional query parameters: `familyId`, `page`, `limit`
- [ ] Query parameters properly validated

### Response Validation
- [ ] Success responses include `success: true`
- [ ] Error responses include `success: false` and error details
- [ ] Data array contains properly formatted note objects
- [ ] Pagination object includes all fields
- [ ] Timestamps in ISO 8601 format
- [ ] User IDs resolve to actual user objects

### Data Structure Validation
- [ ] Note objects match SharedNote schema
- [ ] Permission objects match NotePermission schema
- [ ] Metadata includes fields
- [ ] Tags array contains valid strings
- [ ] Boolean fields have correct types

### Performance Requirements
- [ ] Response time < 500ms for typical requests
- [ ] Proper database indexing for queries
- [ ] Efficient pagination implementation
- [ ] Caching strategy for frequently accessed data
