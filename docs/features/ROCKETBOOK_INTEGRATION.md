# Rocketbook Fusion Plus Integration

## Overview

This feature integrates complete Rocketbook Fusion Plus template recognition and automation into RocketNotes AI. Users can scan any page from their physical Rocketbook Fusion Plus notebook, and the app will:

1. **Auto-detect** which of 11 template types was scanned
2. **Extract structured data** specific to that template (meetings, tasks, calendar events, etc.)
3. **Execute automated actions** based on marked symbols (email, cloud sync, topic assignment, reminders)
4. **Create intelligent notes** with proper formatting and metadata

## Rocketbook Fusion Plus Specifications

### Physical Notebook
- **Total Pages**: 60 reusable pages
- **Template Types**: 11 unique layouts
- **Symbols**: 7 configurable action symbols at bottom of each page
- **Technology**: Erasable with FriXion pen, wipe clean to reuse

### Template Distribution

| Template Type | Pages | Description |
|--------------|-------|-------------|
| Monthly Dashboard | 1 | Goals, metrics, habit trackers |
| List Pages | 2 | Checklists with completion tracking |
| Monthly Calendar | 2 | Full month calendar (1 two-page spread) |
| Weekly Planner | 12 | Weekly schedules with time slots (6 two-page spreads) |
| Custom Table | 1 | Blank table for data entry |
| Project Management | 4 | Task lists, deadlines, milestones |
| Meeting Notes | 8 | Attendees, discussion, action items |
| Lined | 18 | Standard ruled pages |
| Dot Grid | 4 | Dot grid for sketching/diagrams |
| Graph | 4 | Graph paper for charts |
| Blank | 4 | Blank pages for freeform |

### Symbol System

7 symbols at bottom of each page for configurable actions:

| Symbol | Icon | Default Action |
|--------|------|----------------|
| Bell | 🔔 | Create Reminder |
| Diamond | 💎 | Archive Note |
| Star | ⭐ | Mark as Favorite |
| Clover | ☘️ | Assign to Personal Topic |
| Horseshoe | 🧲 | Assign to Work Topic |
| Rocket | 🚀 | Send via Email |
| Apple | 🍎 | Assign to Health Topic |

## Architecture

### Core Components

```
lib/features/rocketbook/
├── models/
│   └── rocketbook_template.dart       # Type definitions
├── services/
│   ├── template_recognition_service.dart  # CV-based detection
│   ├── template_data_extractor.dart      # Structured data extraction
│   └── symbol_action_service.dart        # Symbol action execution
└── presentation/
    └── rocketbook_settings_screen.dart   # Configuration UI
```

### Data Flow

```
1. User scans Rocketbook page with camera
                ↓
2. TemplateRecognitionService analyzes image
   - Decodes image bytes
   - Extracts visual features (grid, calendar, checkboxes, etc.)
   - Classifies template type (1 of 11)
   - Detects marked symbols (bottom 5% of image)
                ↓
3. TemplateDataExtractor processes OCR text
   - Uses template-specific patterns
   - Extracts structured data (dates, tasks, attendees, etc.)
   - Returns ExtractedData with title, content, metadata
                ↓
4. SymbolActionService executes marked actions
   - Reads user configurations
   - Performs actions (email, cloud, topic, reminder, etc.)
   - Returns SymbolActionResult with success/failure
                ↓
5. Note created with:
   - Template type metadata
   - Extracted structured data
   - Topic assignment (from symbol)
   - Reminder (from symbol)
   - Favorite/Archive status (from symbols)
```

## Template Recognition

### Computer Vision Algorithm

Uses `image` package for analysis without ML model:

1. **Image Decoding**: Convert Uint8List to img.Image
2. **Feature Extraction**:
   - Header detection (top 10% of image)
   - Grid pattern detection (vertical/horizontal lines)
   - Calendar structure (7-column pattern)
   - Checkbox detection (square patterns)
   - Time slot detection (left column patterns)
   - Line patterns (horizontal, vertical, dots, graph)
3. **Classification**: Decision tree matching features to template
4. **Symbol Detection**: Analyze bottom 5%, divide into 7 regions, detect dark pixels (>15% threshold)

### Template Features

```dart
class TemplateFeatures {
  final bool hasHeader;          // Title section at top
  final bool hasGrid;            // Grid layout
  final bool hasTable;           // Table structure
  final bool hasCalendar;        // Calendar grid
  final bool hasCheckboxes;      // Checkbox items
  final bool hasTimeSlots;       // Time-based scheduling
  final String linePattern;      // horizontal/vertical/dots/graph/none
  final double confidence;       // 0.0 to 1.0
}
```

### Classification Logic

```dart
// Example decision tree
if (features.hasCalendar && features.hasTimeSlots) {
  return RocketbookTemplate.weekly;
} else if (features.hasCalendar) {
  return RocketbookTemplate.monthly;
} else if (features.hasHeader && features.hasCheckboxes) {
  return RocketbookTemplate.meetingNotes;
} else if (features.hasCheckboxes) {
  return RocketbookTemplate.listPage;
}
// ... more conditions
```

## Data Extraction

### Template-Specific Patterns

Each template uses regex and text analysis to extract structured data:

#### Meeting Notes
```dart
Extracts:
- Title (first line)
- Date (patterns: "Jan 15, 2024", "15/01/2024")
- Attendees (after "Attendees:" or "Participants:")
- Action items (checkbox lines: ☐, □, [ ])
- Notes (full text)
```

#### Project Management
```dart
Extracts:
- Project name (title)
- Tasks (checkbox items)
- Deadlines (date patterns)
- Milestones (after "Milestone:", "Phase:", "Sprint:")
```

#### Weekly Planner
```dart
Extracts:
- Week of (date range)
- Daily entries (Monday:, Tuesday:, etc.)
- Appointments (time patterns: "9:00 AM Meeting")
```

#### Monthly Calendar
```dart
Extracts:
- Month and year
- Events (date number + description)
```

#### Monthly Dashboard
```dart
Extracts:
- Goals (after "Goal:", "Objective:")
- Metrics (pattern: "Label: 123 units")
- Habits (checkbox items)
```

#### List Page
```dart
Extracts:
- Items (checkbox lines)
- Completed items (marked with ✓, ✗)
```

### Usage Example

```dart
final extractor = TemplateDataExtractor.instance;
final result = await extractor.extractData(
  template: RocketbookTemplate.meetingNotes,
  ocrText: scanResult.text,
);

// Access structured data
final attendees = result.structuredData?['attendees'];
final actionItems = result.structuredData?['actionItems'];
final date = result.structuredData?['date'];
```

## Symbol Actions

### Configuration Storage

Stored in Hive box `rocketbook_symbol_config`:

```dart
{
  'symbols': {
    'bell': {
      'symbol': 'bell',
      'actionType': 'createReminder',
      'destination': null,
      'enabled': true
    },
    'rocket': {
      'symbol': 'rocket',
      'actionType': 'email',
      'destination': 'boss@company.com',
      'enabled': true
    },
    // ... other symbols
  }
}
```

### Action Types

```dart
enum SymbolActionType {
  none,              // No action
  email,             // Send via email (destination = email address)
  googleDrive,       // Upload to Google Drive (destination = folder path)
  dropbox,           // Upload to Dropbox (destination = folder path)
  evernote,          // Send to Evernote
  slack,             // Post to Slack (destination = channel)
  icloud,            // Upload to iCloud
  onedrive,          // Upload to OneDrive
  assignToTopic,     // Assign to topic (destination = topic ID)
  createReminder,    // Create reminder (destination = time)
  markFavorite,      // Mark note as favorite
  archive,           // Archive note
  custom,            // Custom action
}
```

### Execution Flow

```dart
// Initialize service
await SymbolActionService.instance.initialize();

// Execute actions for marked symbols
final result = await SymbolActionService.instance.executeActions(
  markedSymbols: [RocketbookSymbol.star, RocketbookSymbol.rocket],
  note: scannedNote,
);

// Check results
if (result.allSuccess) {
  print('All actions completed: ${result.summary}');
} else {
  print('Some failed: ${result.errors}');
}
```

### Implemented Actions

✅ **Assign to Topic**: Updates note.topicId, increments topic.noteCount  
✅ **Mark Favorite**: Sets note.isFavorite = true  
✅ **Archive**: Sets note.isArchived = true  
✅ **Create Reminder**: Sets note.reminderDate (default: tomorrow 9am)  
🚧 **Email**: Logged (TODO: SMTP/API integration)  
🚧 **Cloud Services**: Logged (TODO: API integrations)  

## User Interface

### Rocketbook Settings Screen

Navigate to configure all 7 symbols:

**Features**:
- Visual symbol cards with icons
- Current action displayed
- Enable/disable toggle per symbol
- Tap to edit configuration
- Reset to defaults button

**Configuration Sheet**:
- Action type dropdown (13 options)
- Destination field (context-aware):
  - Email: text input for email address
  - Topic: dropdown of existing topics with icons/colors
  - Cloud: text input for folder path
- Enable toggle
- Save/Cancel buttons

**Access**:
```dart
Navigator.pushNamed(context, '/rocketbook-settings');
```

## Integration Guide

### 1. Initialize Services

In `main.dart`:

```dart
Future<void> main() async {
  // ... existing initialization
  
  // Open Rocketbook config box
  await Hive.openBox<Map>('rocketbook_symbol_config');
  
  // Initialize symbol action service
  await SymbolActionService.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. Add Route

In your router configuration:

```dart
GoRoute(
  path: '/rocketbook-settings',
  name: 'rocketbook-settings',
  builder: (context, state) => const RocketbookSettingsScreen(),
),
```

### 3. Modify Camera Scan Flow

In your camera/scan service:

```dart
Future<void> processScannedImage(Uint8List imageBytes) async {
  // 1. Recognize template
  final recognition = await TemplateRecognitionService.instance
    .recognizeTemplate(imageBytes);
  
  debugPrint('Detected: ${recognition.template.displayName}');
  debugPrint('Confidence: ${recognition.confidence}');
  debugPrint('Symbols: ${recognition.markedSymbols.length}');
  
  // 2. Run OCR
  final ocrText = await runOCR(imageBytes);
  
  // 3. Extract structured data
  final extractedData = await TemplateDataExtractor.instance
    .extractData(
      template: recognition.template,
      ocrText: ocrText,
    );
  
  // 4. Create note
  final note = NoteModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    userId: currentUserId,
    title: extractedData.title,
    content: extractedData.content,
    // Add metadata
    metadata: {
      'rocketbookTemplate': recognition.template.name,
      'templateConfidence': recognition.confidence,
      'structuredData': extractedData.structuredData,
    },
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // 5. Execute symbol actions
  if (recognition.markedSymbols.isNotEmpty) {
    final actionResult = await SymbolActionService.instance
      .executeActions(
        markedSymbols: recognition.markedSymbols,
        note: note,
      );
    
    debugPrint('Actions: ${actionResult.summary}');
  }
  
  // 6. Save note
  await NoteRepository().saveNote(note);
}
```

### 4. Add Settings Menu Item

In settings screen or app drawer:

```dart
ListTile(
  leading: const Icon(Icons.rocket_launch),
  title: const Text('Rocketbook Symbols'),
  subtitle: const Text('Configure page symbol actions'),
  onTap: () => Navigator.pushNamed(context, '/rocketbook-settings'),
),
```

## Testing

### Test Template Recognition

```dart
// Load test image
final ByteData data = await rootBundle.load('assets/test_rocketbook_page.png');
final Uint8List bytes = data.buffer.asUint8List();

// Recognize
final result = await TemplateRecognitionService.instance.recognizeTemplate(bytes);

print('Template: ${result.template.displayName}');
print('Confidence: ${result.confidence}');
print('Marked symbols: ${result.markedSymbols.map((s) => s.displayName)}');
```

### Test Data Extraction

```dart
const ocrText = '''
Meeting Notes
Date: January 15, 2024
Attendees: John, Sarah, Mike

Discussion:
- Q1 planning review
- Budget allocation
- Timeline adjustments

Action Items:
☐ John to update project plan
☐ Sarah to schedule follow-up
☐ Mike to review budget
''';

final extracted = await TemplateDataExtractor.instance.extractData(
  template: RocketbookTemplate.meetingNotes,
  ocrText: ocrText,
);

print('Title: ${extracted.title}');
print('Date: ${extracted.structuredData?['date']}');
print('Attendees: ${extracted.structuredData?['attendees']}');
print('Action Items: ${extracted.structuredData?['actionItems']}');
```

### Test Symbol Actions

```dart
final testNote = NoteModel(/* ... */);

final result = await SymbolActionService.instance.executeActions(
  markedSymbols: [
    RocketbookSymbol.star,      // Favorite
    RocketbookSymbol.bell,      // Reminder
    RocketbookSymbol.clover,    // Personal topic
  ],
  note: testNote,
);

assert(result.successCount == 3);
assert(testNote.isFavorite == true);
assert(testNote.reminderDate != null);
assert(testNote.topicId != null);
```

## Future Enhancements

### Phase 1 (Current)
- ✅ Template type definitions
- ✅ Symbol action model
- ✅ Basic template recognition (feature extraction, classification)
- ✅ Symbol detection (pixel analysis)
- ✅ Data extraction patterns
- ✅ Symbol action execution (local actions)
- ✅ Configuration UI

### Phase 2 (Next)
- ⏳ Complete pattern detection methods (dots, graph, complex grids)
- ⏳ Improve OCR accuracy with template-aware preprocessing
- ⏳ Email integration (SMTP or email API)
- ⏳ Cloud service integrations (Google Drive, Dropbox APIs)
- ⏳ Custom action scripting/webhooks

### Phase 3 (Future)
- 📋 Template-specific UI views (calendar view for Monthly, kanban for Project)
- 📋 ML model training for improved template recognition
- 📋 Handwriting recognition for better text extraction
- 📋 Smart suggestions based on template patterns
- 📋 Template analytics (most used, time tracking)
- 📋 Multi-page scan (combine related pages)
- 📋 Template customization (create your own templates)

## Troubleshooting

### Template Not Recognized

**Symptoms**: Always returns `RocketbookTemplate.unknown`

**Solutions**:
- Ensure good lighting when scanning
- Hold camera parallel to page (avoid perspective distortion)
- Clean page before scanning (no smudges/marks)
- Check if template features are visible in scan
- Increase image resolution

### Symbol Not Detected

**Symptoms**: Marked symbols not in `markedSymbols` list

**Solutions**:
- Mark symbols clearly with dark pen
- Fill symbol completely (not just outline)
- Ensure bottom of page is visible in scan
- Check lighting on symbol area
- Adjust `_isSymbolMarked` threshold if needed (currently 15%)

### Action Not Executing

**Symptoms**: Symbol detected but action doesn't run

**Solutions**:
- Check symbol is enabled in settings
- Verify destination is configured (for email/topic/cloud actions)
- Check logs for error messages
- Ensure required services initialized (Topics, etc.)
- Test action manually from settings screen

### Poor Data Extraction

**Symptoms**: Structured data incomplete or incorrect

**Solutions**:
- Improve OCR quality (better lighting, resolution)
- Use clearer handwriting
- Follow template structure (e.g., "Attendees:" label for meeting notes)
- Add custom regex patterns for your writing style
- Review extracted data in note metadata

## API Reference

### TemplateRecognitionService

```dart
static TemplateRecognitionService get instance
Future<TemplateRecognitionResult> recognizeTemplate(Uint8List imageBytes)
```

### TemplateDataExtractor

```dart
static TemplateDataExtractor get instance
Future<ExtractedData> extractData({
  required RocketbookTemplate template,
  required String ocrText,
})
```

### SymbolActionService

```dart
static SymbolActionService get instance
Future<void> initialize()
SymbolAction? getConfiguration(RocketbookSymbol symbol)
List<SymbolAction> getAllConfigurations()
Future<void> updateConfiguration(SymbolAction action)
Future<void> saveConfigurations(List<SymbolAction> actions)
Future<SymbolActionResult> executeActions({
  required List<RocketbookSymbol> markedSymbols,
  required NoteModel note,
})
```

## License

This integration is part of RocketNotes AI. Rocketbook® and Rocketbook Fusion Plus™ are trademarks of Rocket Innovations, Inc.
