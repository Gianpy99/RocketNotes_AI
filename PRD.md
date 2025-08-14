# Product Requirements Document (PRD)
**Project Name:** RocketNotes AI — App personalizzata con NFC e deep linking  
**Owner:** Solo build (you)  
**Date:** 2025-08-14  

---

## 1) Problem Statement
People often take notes, reminders, or tasks across multiple devices, but context-specific actions are hard to trigger automatically. NFC tags and deep links are underutilized for personal productivity. There is a need for an app that bridges physical triggers (NFC) with digital actions (deep links) to create context-aware, personalized note-taking and automation.

---

## 2) Goals & Objectives
- **Enable physical triggers** via NFC tags to launch notes, reminders, or tasks.  
- **Support deep linking** to apps, documents, or URLs for instant context actions.  
- **Provide AI-driven suggestions** for notes, reminders, or task organization.  
- **Keep the app lightweight and intuitive** for daily personal productivity.  
- **Secure user data** with privacy-focused storage and local-first processing.

---

## 3) Target Users
- Professionals, students, or hobbyists using NFC-enabled devices.  
- Users who want context-aware automation for personal productivity.  
- Anyone looking for a simple, AI-augmented note/task system integrated with physical triggers.

---

## 4) Core Features

### MVP
1. **NFC Tag Recognition:** Tap an NFC tag to open a note or trigger a task.  
2. **Deep Linking Support:** Launch apps, documents, or URLs from NFC interactions.  
3. **Note & Task Creation:** Simple editor for text, images, and links.  
4. **Basic AI Suggestions:** Auto-suggest tags, categories, or reminders.  
5. **Local Data Storage:** Secure, offline-first note storage.

### Phase 2
6. **AI-Powered Organization:** Auto-categorization, smart reminders, and task prioritization.  
7. **Tag Management:** Easily assign and manage NFC tags.  
8. **Cross-Device Sync:** Sync notes and tasks across mobile and web.  

### Phase 3
9. **Advanced Automation:** Trigger sequences of actions from a single NFC tap.  
10. **Integration with Calendars & Productivity Apps:** Deep linking into popular platforms.  
11. **Analytics & Insights:** Track usage patterns and productivity trends.

---

## 5) Non-Functional Requirements
- **Performance:** NFC interactions should trigger actions within 1 second.  
- **Security:** Local-first storage; optional encrypted cloud sync.  
- **Reliability:** Offline-first functionality; minimal app crashes.  
- **Accessibility:** Mobile-first design; simple UI/UX for all ages.

---

## 6) Constraints
- Limited by NFC hardware capabilities (range, read speed).  
- Deep linking depends on other apps’ support for URLs/URI schemes.  
- AI suggestions should not require heavy cloud processing unless opted-in.

---

## 7) Tech Stack Suggestion
- **Frontend:** React Native or Flutter for cross-platform mobile.  
- **Backend:** Optional Firebase for cloud sync and user authentication.  
- **Database:** SQLite for local storage, optionally Firestore for cloud.  
- **AI:** Lightweight on-device NLP (e.g., TensorFlow Lite) for note suggestions.  
- **NFC Integration:** Native modules for Android and iOS NFC handling.  

---

## 8) Success Metrics
- ≥70% of users create or interact with ≥3 NFC-triggered notes/tasks per day.  
- ≥50% usage of AI suggestions for task organization.  
- High user satisfaction with app speed and simplicity (>4/5).  
- Minimal app crashes or NFC read failures (<1% of interactions).  

---

## 9) Roadmap

| Phase     | Duration  | Key Deliverables |
|-----------|-----------|------------------|
| **MVP**   | 4 weeks   | NFC recognition, deep linking, note/task creation, AI suggestions, local storage |
| **Phase 2** | +4 weeks | AI organization, tag management, cross-device sync |
| **Phase 3** | +6 weeks | Advanced automation, calendar integration, analytics |

---

## 10) Risks & Mitigation
- **NFC compatibility issues:** Limit MVP to common NFC standards and devices.  
- **Privacy concerns:** Emphasize local-first storage; optional cloud features.  
- **Low adoption:** Provide pre-configured NFC tag examples for easy onboarding.

---

## 11) Open Questions
- Should AI suggestions run fully offline or cloud-assisted?  
- How many NFC tags should be supported per user at launch?  
- Should the app allow **sharing NFC-triggered tasks** with other users?  

---
