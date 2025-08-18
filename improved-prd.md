# Product Requirements Document (PRD) v2.0
**Project Name:** RocketNotes AI — Smart NFC-Enabled Note Management  
**Version:** 2.0  
**Date:** 2025-08-18  
**Status:** MVP Development

---

## Executive Summary
RocketNotes AI bridges physical note-taking with digital organization through NFC technology and AI-powered insights. Users can instantly categorize and digitize their Rocketbook notes by tapping NFC tags, creating a seamless workflow between analog writing and digital productivity.

---

## 1. Problem Statement
Users of reusable notebooks (like Rocketbook) lack an efficient way to:
- Quickly categorize notes between work and personal contexts
- Trigger context-aware digital actions from physical notebooks
- Maintain consistency between physical and digital note organization
- Extract actionable insights from handwritten notes

---

## 2. Solution Overview
A mobile-first application that:
- Uses NFC tags to instantly launch context-specific note modes
- Automatically categorizes and stores notes based on physical triggers
- Provides AI-powered suggestions and insights (Phase 2)
- Maintains offline-first functionality with optional cloud sync

---

## 3. User Personas

### Primary: Digital Professional
- **Age:** 25-45
- **Tech Savvy:** High
- **Pain Points:** Managing work/personal boundaries, note organization
- **Goal:** Seamless transition from physical to digital notes

### Secondary: Student/Academic
- **Age:** 18-30
- **Tech Savvy:** Medium-High
- **Pain Points:** Study organization, quick note retrieval
- **Goal:** Efficient study material management

---

## 4. Feature Specification

### MVP (Week 1-2)
| Feature | Description | Priority |
|---------|-------------|----------|
| NFC Tag Reading | Detect and parse NTAG213 tags with custom URIs | P0 |
| Deep Link Handling | Process `rocketnotes://work` and `rocketnotes://personal` | P0 |
| Mode Switching | Visual indication and state management for work/personal modes | P0 |
| Quick Note Creation | Simple text input with automatic mode-based categorization | P0 |
| Local Storage | Offline-first data persistence using Hive | P0 |
| Note List View | Browse notes filtered by mode/date | P1 |

### Phase 2 (Week 3-4)
| Feature | Description | Priority |
|---------|-------------|----------|
| Image Capture | Photograph Rocketbook pages | P0 |
| OCR Integration | Extract text from photographed pages | P1 |
| Basic AI Suggestions | Tag recommendations, summary generation | P1 |
| Search Functionality | Full-text search across notes | P1 |
| Export Options | PDF, Markdown, Plain text | P2 |

### Phase 3 (Week 5-6)
| Feature | Description | Priority |
|---------|-------------|----------|
| Cloud Sync | Optional encrypted backup | P1 |
| Advanced AI Features | Smart reminders, task extraction, insights | P1 |
| Calendar Integration | Sync tasks with Google/Apple Calendar | P2 |
| Collaboration | Share notes/tasks via deep links | P2 |
| Analytics Dashboard | Productivity insights and patterns | P3 |

---

## 5. Technical Architecture

### Mobile App
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod 2.0
- **Local Storage:** Hive (NoSQL, encrypted)
- **NFC:** flutter_nfc_kit
- **Deep Linking:** app_links package
- **Navigation:** go_router

### Backend (Phase 2+)
- **API:** Firebase Functions or Supabase Edge Functions
- **Database:** Firestore or PostgreSQL
- **Authentication:** Firebase Auth or Supabase Auth
- **AI Services:** OpenAI API or Google Gemini
- **Storage:** Firebase Storage or Supabase Storage

### AI Pipeline (Phase 2+)
- **OCR:** Google ML Kit or Tesseract
- **NLP:** OpenAI GPT-4 or Google Gemini
- **On-device:** TensorFlow Lite for basic classification

---

## 6. User Flow

### Primary Flow: NFC-Triggered Note Creation
1. User taps NFC tag on Rocketbook cover
2. Phone reads URI (e.g., `rocketnotes://work`)
3. App launches/switches to corresponding mode
4. User creates/views notes in that context
5. Notes auto-save with mode metadata

### Secondary Flow: Manual Note Management
1. User opens app directly
2. Selects mode manually or continues in last mode
3. Creates, edits, or searches notes
4. Optional: Triggers AI analysis or export

---

## 7. UI/UX Guidelines

### Design Principles
- **Minimal Taps:** Max 2 taps to create a note
- **Visual Context:** Clear color coding (blue=work, green=personal)
- **Speed First:** Sub-second NFC response time
- **Offline Ready:** Full functionality without internet

### Key Screens
1. **Home/Mode View:** Large mode indicator, quick note button
2. **Note Editor:** Minimal UI, focus on content
3. **Note List:** Filterable grid/list with search
4. **Settings:** NFC tag management, sync options

---

## 8. Data Model

### Note Entity
```json
{
  "id": "uuid",
  "content": "string",
  "mode": "work|personal",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "tags": ["string"],
  "ai_summary": "string",
  "attachments": ["uri"],
  "nfc_tag_id": "string"
}
```

### NFC Tag Entity
```json
{
  "id": "string",
  "uri": "rocketnotes://mode",
  "label": "string",
  "color": "hex",
  "created_at": "timestamp"
}
```

---

## 9. Success Metrics

### MVP Metrics
- **Activation Rate:** >80% users create first note within 5 minutes
- **NFC Success Rate:** >95% successful tag reads
- **Daily Active Usage:** >60% users open app daily
- **Mode Usage:** Both modes used by >40% of users

### Long-term Metrics
- **Retention:** 30-day retention >50%
- **AI Feature Adoption:** >60% users try AI suggestions
- **Note Volume:** Average 5+ notes/day per active user
- **Cross-device Sync:** >30% users enable sync

---

## 10. Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| NFC compatibility issues | High | Test on top 10 Android devices, provide QR code fallback |
| Privacy concerns | High | Local-first storage, transparent data practices, GDPR compliance |
| Low NFC adoption | Medium | Include NFC tags with app, video tutorials, manual mode switching |
| AI accuracy | Medium | User feedback loop, manual override options |
| Battery drain | Low | Optimize NFC polling, background task management |

---

## 11. Development Milestones

### Week 1: Foundation
- [ ] Flutter project setup with clean architecture
- [ ] NFC reading implementation
- [ ] Deep link handling
- [ ] Basic UI with mode switching

### Week 2: Core Features
- [ ] Note CRUD operations
- [ ] Local storage with Hive
- [ ] Note list and search
- [ ] Settings screen

### Week 3: Enhancement
- [ ] Image capture integration
- [ ] Basic OCR implementation
- [ ] Export functionality
- [ ] UI polish and animations

### Week 4: AI Integration
- [ ] AI service integration
- [ ] Smart suggestions
- [ ] Auto-tagging
- [ ] Performance optimization

---

## 12. Open Questions Resolved

1. **AI Processing:** Hybrid approach - basic on-device, advanced cloud-based
2. **NFC Tag Limit:** Start with 5 tags per user, expandable
3. **Sharing Features:** Phase 3, via shareable deep links
4. **Monetization:** Freemium model - basic free, AI features premium

---

## 13. Appendix

### NFC Tag Specifications
- Type: NTAG213
- Memory: 144 bytes usable
- Compatibility: ISO 14443 Type A
- Range: 1-4 cm typical
- Data: UTF-8 URI records

### Deep Link Schema
```
rocketnotes://[mode]/[action]?[parameters]

Examples:
rocketnotes://work
rocketnotes://personal
rocketnotes://work/new?title=Meeting%20Notes
rocketnotes://personal/view?id=uuid
```

### Color Palette
- Work Mode: #2196F3 (Blue)
- Personal Mode: #4CAF50 (Green)
- Background: #FAFAFA (Light) / #121212 (Dark)
- Accent: #FF5722 (Orange)