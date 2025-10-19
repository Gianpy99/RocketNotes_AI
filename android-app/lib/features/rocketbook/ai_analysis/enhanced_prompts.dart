/// Enhanced AI prompts for RocketNotes analysis
/// 
/// This file contains ROCK SOLID prompts optimized for:
/// - Maximum context extraction
/// - Vision API integration (image + text)
/// - Rocketbook-specific features
/// - Structured, parseable responses

/// Rocketbook template types
enum RocketbookTemplate {
  meeting,      // Meeting Notes template
  todo,         // To-Do List template
  weekly,       // Weekly Planner template
  goals,        // Goal Setting template
  brainstorm,   // Brainstorm/Mind Map template
  blank,        // Blank/Generic template
  unknown,      // Not a recognized template
}

class EnhancedPrompts {
  
  /// System prompt for vision-enabled models (GPT-4 Vision, Gemini Pro Vision, Claude 3)
  /// This is used when sending BOTH image and OCR text
  static String getVisionSystemPrompt() {
    return '''
You are an expert AI assistant specialized in analyzing handwritten and printed notes from Rocketbook smart notebooks and similar note-taking systems.

You have access to BOTH:
1. The ORIGINAL IMAGE of the page (visual analysis)
2. OCR-extracted text (may contain errors)

Your analysis should leverage BOTH sources to provide the most accurate and comprehensive understanding.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 YOUR MISSION:
Extract ALL actionable information, insights, and context from this scanned page to help the user organize, search, and act on their notes effectively.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 REQUIRED OUTPUT FORMAT:
You MUST respond using this EXACT structure (parseable format):

```
TITLE: [Create a clear, descriptive title that captures the main subject]

SHORT_DESCRIPTION: [2-3 sentences summarizing what this page is about and its purpose]

PAGE_TYPE: [Choose ONE: meeting|todo|brainstorm|lecture|technical|planning|personal|recipe|research|mixed]

CORRECTED_TEXT: [The complete text content with OCR errors fixed based on visual inspection of the image. Preserve formatting, bullets, numbering.]

SUMMARY: [Comprehensive 3-5 sentence summary covering all key points, decisions, ideas, and context]

TASKS: [Extract ALL actionable items. Format as bullet list:
- Task description (with any context)
- Another task
- etc.]

DEADLINES: [Extract ALL dates, deadlines, time-sensitive items. Format:
- YYYY-MM-DD: Description
- "Next week": Description
- etc.]

PEOPLE_MENTIONED: [List ALL names found in text or signatures, comma-separated]

ORGANIZATIONS: [Companies, institutions, projects mentioned, comma-separated]

LOCATIONS: [Places, addresses, meeting rooms mentioned, comma-separated]

KEY_TOPICS: [Main subjects, themes, concepts covered - comma-separated tags for searchability]

TECHNICAL_TERMS: [Domain-specific jargon, acronyms, technical concepts - comma-separated]

VISUAL_ELEMENTS: [Describe any diagrams, sketches, charts, tables, drawings, symbols seen in the IMAGE]

ROCKETBOOK_SYMBOLS: [If visible in image, list which symbols are marked: star|rocket|clover|diamond|cloud|email|folder]

HANDWRITING_QUALITY: [excellent|good|fair|poor - affects confidence in OCR corrections]

PRIORITY_LEVEL: [low|medium|high|urgent - based on content urgency, deadlines, language used]

SENTIMENT: [positive|neutral|negative|mixed - overall emotional tone]

CONFIDENCE_SCORE: [0-100 integer - your confidence in this analysis accuracy]

NEXT_ACTIONS: [Suggested follow-up actions the user should take, bullet list:
- Action suggestion
- etc.]

SEARCH_KEYWORDS: [Additional keywords for search optimization, comma-separated]

NOTES: [Any additional observations, warnings, or context that doesn't fit above categories]
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 ANALYSIS GUIDELINES:

VISUAL INSPECTION:
- Carefully examine the IMAGE for layout, structure, emphasis (underlines, stars, circles)
- Identify diagrams, flowcharts, sketches - describe them in VISUAL_ELEMENTS
- Look for Rocketbook symbols at bottom of page (7 icons for different destinations)
- Notice handwriting variations that might indicate importance or different authors
- Check for color coding, highlighting, margin notes

OCR ERROR CORRECTION:
- Common OCR mistakes: l↔1, O↔0, S↔5, I↔l, rn↔m
- Use visual context from image to fix garbled text
- Preserve original formatting: bullets, numbering, indentation, spacing
- If text is illegible even in image, mark with [illegible] rather than guessing

TASK EXTRACTION:
- Look for: checkboxes (☐ □ ☑ ☒), bullets with verbs, "TODO", "Action items", numbered lists
- Extract implicit tasks: "Need to...", "Should...", "Remember to...", "Follow up..."
- Include context with each task: WHO should do it, WHAT, WHY if mentioned

DATE DETECTION:
- Formats: MM/DD/YYYY, DD/MM/YYYY, "Jan 15", "next Tuesday", "Q2 2024"
- Relative dates: "tomorrow", "next week", "in 2 days"
- Extract meeting times, event dates, project deadlines

PEOPLE & ENTITIES:
- Names: Check for signatures, "@mentions", email addresses, phone numbers
- Organizations: Company names, departments, project names
- Proper nouns: Capitalize correctly in CORRECTED_TEXT

CONTEXT ENRICHMENT:
- Infer page purpose from structure (meeting has date+attendees, todo has checkboxes)
- Identify domain: business, academic, personal, technical
- Note relationships between items (dependencies, hierarchies)

ROCKETBOOK SYMBOLS (bottom icons on Rocketbook pages):
★ Star → Favorites/Important
🚀 Rocket → Email to self
🍀 Clover → Cloud storage (Dropbox/Google Drive)
💎 Diamond → Email to team
☁️ Cloud → Cloud backup
✉️ Email → Send to specific email
📁 Folder → File to specific folder

If you see these marked, extract in ROCKETBOOK_SYMBOLS section.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ CRITICAL REQUIREMENTS:
1. ALWAYS use the exact field names and format shown above
2. If a field has no relevant content, write "None" or "N/A" - do NOT omit fields
3. CORRECTED_TEXT is MANDATORY - fix OCR errors by comparing with image
4. Be thorough - extract EVERYTHING actionable and searchable
5. Maintain professional, objective tone
6. Your response will be parsed programmatically - follow format exactly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// System prompt for text-only models (GPT-3.5, GPT-4 without vision)
  /// This is used when we only have OCR text
  static String getTextOnlySystemPrompt() {
    return '''
You are an expert AI assistant specialized in analyzing handwritten and printed notes from Rocketbook smart notebooks and similar note-taking systems.

You are analyzing OCR-extracted text which may contain errors. Do your best to infer correct content from context.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 YOUR MISSION:
Extract ALL actionable information, insights, and context from this scanned text to help the user organize, search, and act on their notes effectively.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 REQUIRED OUTPUT FORMAT:
You MUST respond using this EXACT structure (parseable format):

```
TITLE: [Create a clear, descriptive title that captures the main subject]

SHORT_DESCRIPTION: [2-3 sentences summarizing what this page is about and its purpose]

PAGE_TYPE: [Choose ONE: meeting|todo|brainstorm|lecture|technical|planning|personal|recipe|research|mixed]

CORRECTED_TEXT: [The complete text content with likely OCR errors fixed based on context. Preserve formatting, bullets, numbering.]

SUMMARY: [Comprehensive 3-5 sentence summary covering all key points, decisions, ideas, and context]

TASKS: [Extract ALL actionable items. Format as bullet list:
- Task description (with any context)
- Another task
- etc.]

DEADLINES: [Extract ALL dates, deadlines, time-sensitive items. Format:
- YYYY-MM-DD: Description
- "Next week": Description
- etc.]

PEOPLE_MENTIONED: [List ALL names found in text, comma-separated]

ORGANIZATIONS: [Companies, institutions, projects mentioned, comma-separated]

LOCATIONS: [Places, addresses, meeting rooms mentioned, comma-separated]

KEY_TOPICS: [Main subjects, themes, concepts covered - comma-separated tags for searchability]

TECHNICAL_TERMS: [Domain-specific jargon, acronyms, technical concepts - comma-separated]

PRIORITY_LEVEL: [low|medium|high|urgent - based on content urgency, deadlines, language used]

SENTIMENT: [positive|neutral|negative|mixed - overall emotional tone]

CONFIDENCE_SCORE: [0-100 integer - your confidence in this analysis accuracy]

NEXT_ACTIONS: [Suggested follow-up actions the user should take, bullet list:
- Action suggestion
- etc.]

SEARCH_KEYWORDS: [Additional keywords for search optimization, comma-separated]

NOTES: [Any additional observations, warnings, or context that doesn't fit above categories]
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 ANALYSIS GUIDELINES:

OCR ERROR CORRECTION:
- Common OCR mistakes: l↔1, O↔0, S↔5, I↔l, rn↔m, cl↔d
- Use context to infer correct words
- Fix obvious typos and garbled text
- Preserve formatting: bullets, numbering, spacing

TASK EXTRACTION:
- Look for: checkboxes (☐ □ ☑ ☒), bullets with verbs, "TODO", "Action items"
- Extract implicit tasks: "Need to...", "Should...", "Remember to...", "Follow up..."
- Include context with each task

DATE DETECTION:
- Recognize various formats: MM/DD/YYYY, "Jan 15", "next Tuesday", "Q2 2024"
- Extract relative dates: "tomorrow", "next week"
- Include meeting times, deadlines

PEOPLE & ENTITIES:
- Extract names, email addresses, phone numbers
- Identify companies, organizations, project names
- Capitalize proper nouns correctly

CONTEXT ENRICHMENT:
- Infer page purpose from structure
- Identify domain: business, academic, personal, technical
- Note relationships between items

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ CRITICAL REQUIREMENTS:
1. ALWAYS use the exact field names and format shown above
2. If a field has no relevant content, write "None" or "N/A" - do NOT omit fields
3. CORRECTED_TEXT is MANDATORY - fix OCR errors using context
4. Be thorough - extract EVERYTHING actionable and searchable
5. Your response will be parsed programmatically - follow format exactly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }

  /// Build user prompt with rich context (vision-enabled)
  static String buildVisionUserPrompt({
    required String ocrText,
    required double ocrConfidence,
    required String? ocrEngine,
    required List<String> detectedLanguages,
    required bool isRocketbookPage,
    required int processingTimeMs,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 SCANNED PAGE ANALYSIS REQUEST');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    // Page type indicator
    if (isRocketbookPage) {
      buffer.writeln('📓 **PAGE TYPE:** Rocketbook Smart Notebook Page');
      buffer.writeln('   (Look for 7 destination symbols at bottom of page)');
    } else {
      buffer.writeln('📝 **PAGE TYPE:** General Handwritten/Printed Notes');
    }
    buffer.writeln();
    
    // OCR metadata for context
    buffer.writeln('🔍 **OCR EXTRACTION METADATA:**');
    buffer.writeln('   • Engine: ${ocrEngine ?? 'Unknown'}');
    buffer.writeln('   • Confidence: ${(ocrConfidence * 100).toStringAsFixed(1)}%');
    buffer.writeln('   • Languages Detected: ${detectedLanguages.isEmpty ? 'Unknown' : detectedLanguages.join(', ')}');
    buffer.writeln('   • Processing Time: ${processingTimeMs}ms');
    buffer.writeln();
    
    if (ocrConfidence < 0.7) {
      buffer.writeln('⚠️ **WARNING:** Low OCR confidence - rely more on visual image analysis');
      buffer.writeln();
    }
    
    // The OCR text
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📝 **OCR-EXTRACTED TEXT** (may contain errors - verify against image):');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    if (ocrText.trim().isEmpty) {
      buffer.writeln('[NO TEXT EXTRACTED - Analyze visual elements from image]');
      buffer.writeln();
      buffer.writeln('Possible reasons:');
      buffer.writeln('• Page contains only diagrams/drawings');
      buffer.writeln('• Handwriting not recognized by OCR');
      buffer.writeln('• Image quality too low');
      buffer.writeln('• Non-text content (charts, sketches)');
      buffer.writeln();
      buffer.writeln('**Focus on visual analysis of the image to extract meaning.**');
    } else {
      buffer.writeln(ocrText);
    }
    
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🎯 **YOUR TASK:**');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('1. Examine the IMAGE carefully - look at layout, visual elements, formatting');
    buffer.writeln('2. Compare image with OCR text - fix any extraction errors');
    buffer.writeln('3. Extract ALL actionable items, dates, people, topics');
    buffer.writeln('4. Describe visual elements (diagrams, symbols, emphasis)');
    buffer.writeln('5. Provide comprehensive analysis using the required format');
    buffer.writeln();
    buffer.writeln('**Provide your analysis now following the exact format specified in the system prompt.**');
    
    return buffer.toString();
  }

  /// Build user prompt for text-only analysis
  static String buildTextOnlyUserPrompt({
    required String ocrText,
    required double ocrConfidence,
    required String? ocrEngine,
    required List<String> detectedLanguages,
    required bool isRocketbookPage,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📄 TEXT ANALYSIS REQUEST');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    // Page type
    if (isRocketbookPage) {
      buffer.writeln('📓 **SOURCE:** Rocketbook Smart Notebook Page');
    } else {
      buffer.writeln('📝 **SOURCE:** General Handwritten/Printed Notes');
    }
    buffer.writeln();
    
    // OCR metadata
    buffer.writeln('🔍 **OCR METADATA:**');
    buffer.writeln('   • Engine: ${ocrEngine ?? 'Unknown'}');
    buffer.writeln('   • Confidence: ${(ocrConfidence * 100).toStringAsFixed(1)}%');
    buffer.writeln('   • Languages: ${detectedLanguages.isEmpty ? 'Unknown' : detectedLanguages.join(', ')}');
    buffer.writeln();
    
    if (ocrConfidence < 0.7) {
      buffer.writeln('⚠️ **NOTE:** Low OCR confidence - text may contain more errors');
      buffer.writeln();
    }
    
    // The text
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📝 **EXTRACTED TEXT:**');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    if (ocrText.trim().isEmpty) {
      buffer.writeln('[NO TEXT EXTRACTED]');
      buffer.writeln();
      buffer.writeln('Cannot perform analysis without text content.');
      buffer.writeln('Please rescan or use a vision-enabled model.');
    } else {
      buffer.writeln(ocrText);
    }
    
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🎯 **YOUR TASK:**');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('Analyze this text and provide comprehensive structured output.');
    buffer.writeln('Fix OCR errors using context. Extract all actionable information.');
    buffer.writeln();
    buffer.writeln('**Provide your analysis now following the exact format specified in the system prompt.**');
    
    return buffer.toString();
  }

  /// Detect if text suggests this is a Rocketbook page
  static bool detectRocketbookPage(String text) {
    final indicators = [
      // Rocketbook branding
      RegExp(r'rocket\s?book', caseSensitive: false),
      RegExp(r'reusable', caseSensitive: false),
      RegExp(r'erasable', caseSensitive: false),
      
      // Common instructions
      RegExp(r'scan\s+to', caseSensitive: false),
      RegExp(r'send\s+to', caseSensitive: false),
      
      // Symbol markers (text versions)
      RegExp(r'\b(star|rocket|clover|diamond|cloud|email|folder)\b', caseSensitive: false),
      
      // Unicode symbols sometimes OCR'd
      RegExp(r'[★☆🚀🍀💎☁✉📁]'),
      
      // Checkbox patterns common in Rocketbook templates
      RegExp(r'☐|□|☑|☒'),
    ];
    
    return indicators.any((pattern) => pattern.hasMatch(text));
  }

  /// Example showing how to use these prompts
  static String getUsageExample() {
    return '''
// USAGE EXAMPLE:

// 1. Determine if model supports vision
final bool supportsVision = modelSupportsVision(selectedModel);

// 2. Select appropriate system prompt
final systemPrompt = supportsVision 
    ? EnhancedPrompts.getVisionSystemPrompt()
    : EnhancedPrompts.getTextOnlySystemPrompt();

// 3. Build user prompt with context
final userPrompt = supportsVision
    ? EnhancedPrompts.buildVisionUserPrompt(
        ocrText: scannedContent.rawText,
        ocrConfidence: scannedContent.ocrMetadata.overallConfidence,
        ocrEngine: scannedContent.ocrMetadata.engine,
        detectedLanguages: scannedContent.ocrMetadata.detectedLanguages,
        isRocketbookPage: EnhancedPrompts.detectRocketbookPage(scannedContent.rawText),
        processingTimeMs: scannedContent.ocrMetadata.processingTimeMs,
      )
    : EnhancedPrompts.buildTextOnlyUserPrompt(
        ocrText: scannedContent.rawText,
        ocrConfidence: scannedContent.ocrMetadata.overallConfidence,
        ocrEngine: scannedContent.ocrMetadata.engine,
        detectedLanguages: scannedContent.ocrMetadata.detectedLanguages,
        isRocketbookPage: EnhancedPrompts.detectRocketbookPage(scannedContent.rawText),
      );

// 4. Send to AI with image (if vision-enabled)
if (supportsVision && scannedContent.imagePath.isNotEmpty) {
  final imageBytes = await File(scannedContent.imagePath).readAsBytes();
  final base64Image = base64Encode(imageBytes);
  
  // For OpenAI GPT-4 Vision:
  messages = [
    {
      'role': 'system',
      'content': systemPrompt,
    },
    {
      'role': 'user',
      'content': [
        {'type': 'text', 'text': userPrompt},
        {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,\$base64Image'}},
      ],
    },
  ];
  
  // For Google Gemini Vision:
  contents = [
    {
      'parts': [
        {'text': systemPrompt + '\\n\\n' + userPrompt},
        {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}},
      ]
    }
  ];
}
''';
  }
  
  // ═══════════════════════════════════════════════════════════════════════════════════
  // ROCKETBOOK TEMPLATE-SPECIFIC PROMPTS
  // ═══════════════════════════════════════════════════════════════════════════════════
  
  /// Detect Rocketbook template from visual cues and text
  static RocketbookTemplate detectTemplate(String ocrText) {
    final lowerText = ocrText.toLowerCase();
    
    // Meeting Notes template
    if (lowerText.contains('meeting notes') ||
        lowerText.contains('meeting:') ||
        (lowerText.contains('date:') && lowerText.contains('attendees:')) ||
        (lowerText.contains('action items') && lowerText.contains('notes:'))) {
      return RocketbookTemplate.meeting;
    }
    
    // To-Do List template
    if (lowerText.contains('to-do') ||
        lowerText.contains('todo') ||
        lowerText.contains('task list') ||
        (RegExp(r'☐|□|☑|☒').hasMatch(ocrText) && ocrText.split('\n').length > 5)) {
      return RocketbookTemplate.todo;
    }
    
    // Weekly Planner template
    if ((lowerText.contains('monday') && lowerText.contains('tuesday') && lowerText.contains('wednesday')) ||
        lowerText.contains('week of') ||
        lowerText.contains('weekly planner')) {
      return RocketbookTemplate.weekly;
    }
    
    // Goal Setting template
    if (lowerText.contains('goals') ||
        lowerText.contains('objectives') ||
        (lowerText.contains('goal:') && lowerText.contains('target:')) ||
        lowerText.contains('milestones')) {
      return RocketbookTemplate.goals;
    }
    
    // Brainstorm template
    if (lowerText.contains('brainstorm') ||
        lowerText.contains('ideas:') ||
        (lowerText.contains('topic:') && lowerText.contains('concepts:'))) {
      return RocketbookTemplate.brainstorm;
    }
    
    // Check if it's a Rocketbook page (has symbols) but no specific template
    if (detectRocketbookPage(ocrText)) {
      return RocketbookTemplate.blank;
    }
    
    return RocketbookTemplate.unknown;
  }
  
  /// Get template-specific system prompt enhancement
  static String getTemplateSpecificInstructions(RocketbookTemplate template) {
    switch (template) {
      case RocketbookTemplate.meeting:
        return _getMeetingNotesInstructions();
      case RocketbookTemplate.todo:
        return _getTodoListInstructions();
      case RocketbookTemplate.weekly:
        return _getWeeklyPlannerInstructions();
      case RocketbookTemplate.goals:
        return _getGoalSettingInstructions();
      case RocketbookTemplate.brainstorm:
        return _getBrainstormInstructions();
      case RocketbookTemplate.blank:
      case RocketbookTemplate.unknown:
        return '';
    }
  }
  
  /// Meeting Notes template instructions
  static String _getMeetingNotesInstructions() {
    return '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 ROCKETBOOK MEETING NOTES TEMPLATE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is a structured MEETING NOTES page. Focus on:

**REQUIRED EXTRACTIONS:**
1. **Meeting Title/Subject** → Use as TITLE
2. **Date & Time** → Extract to DEADLINES with format "YYYY-MM-DD HH:MM: Meeting held"
3. **Attendees/Participants** → Extract ALL names to PEOPLE_MENTIONED
4. **Action Items Section** → Extract ALL tasks with owner if mentioned
   - Look for checkboxes (☐ □ ☑ ☒)
   - Format: "- [Owner if mentioned] Task description"
5. **Decisions Made** → Include in SUMMARY with "DECISION:" prefix
6. **Follow-up Items** → Add to NEXT_ACTIONS
7. **Key Discussion Points** → Summarize in SUMMARY

**MEETING-SPECIFIC FIELDS:**
- PAGE_TYPE: Must be "meeting"
- Extract meeting organizer/host if mentioned
- Note if meeting is recurring (weekly, monthly, etc.)
- Extract any deadlines mentioned for deliverables
- Identify owners/assignees for action items

**VISUAL CUES TO CHECK:**
- Pre-printed "Date:", "Time:", "Attendees:" fields
- Action Items checkbox section
- Notes section with ruled lines
- Rocketbook symbols at bottom

**EXAMPLE OUTPUT ENHANCEMENT:**
```
TITLE: Q1 Marketing Strategy Meeting

DEADLINES:
- 2025-01-15 14:00: Meeting held
- 2025-01-22: Marketing plan draft due (Sarah)
- 2025-02-01: Campaign launch

PEOPLE_MENTIONED: Sarah Johnson, Mike Chen, Lisa Park, Tom Wilson

TASKS:
- [Sarah] Draft Q1 marketing plan by Jan 22
- [Mike] Analyze competitor campaigns this week
- [Lisa] Prepare budget proposal for next meeting
- [Tom] Review social media metrics

SUMMARY: Marketing team met to plan Q1 strategy. DECISION: Focus on digital channels with 30% budget increase. DECISION: Launch new campaign Feb 1st. Team will reconvene next week to review Sarah's draft plan and finalize budget allocation.
```

**PRIORITY RULES:**
- If "urgent" or "ASAP" mentioned → PRIORITY_LEVEL: urgent
- If multiple deadlines within 1 week → PRIORITY_LEVEL: high
- Regular status meeting → PRIORITY_LEVEL: medium
''';
  }
  
  /// To-Do List template instructions
  static String _getTodoListInstructions() {
    return '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ROCKETBOOK TO-DO LIST TEMPLATE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is a TO-DO LIST page. Focus on:

**REQUIRED EXTRACTIONS:**
1. **List Title** (if present) → Use as TITLE, else "To-Do List"
2. **ALL Checkbox Items** → Extract to TASKS
   - ☐ □ = Not started
   - ☑ ☒ = Completed (note this in parentheses)
   - Format: "- Task description [DONE if checked]"
3. **Priority Markers** → Look for stars (★), exclamation marks (!), underlines
4. **Due Dates** → Extract any dates next to tasks
5. **Categories/Sections** → If tasks grouped, note in SUMMARY

**TODO-SPECIFIC ANALYSIS:**
- PAGE_TYPE: Must be "todo"
- Count total tasks vs completed tasks
- Note in SUMMARY: "X of Y tasks completed"
- Identify high-priority tasks (marked with ★, !!, underlined)
- Extract any recurring tasks (daily, weekly mentions)

**VISUAL CUES TO CHECK:**
- Pre-printed checkbox column
- Numbered or bulleted lines
- Priority markers (stars, highlights)
- Date column if present
- Category sections

**EXAMPLE OUTPUT ENHANCEMENT:**
```
TITLE: Weekly Work Tasks

SHORT_DESCRIPTION: Work-related to-do list with 8 tasks across multiple projects. 3 of 8 tasks completed.

PAGE_TYPE: todo

TASKS:
- Complete project proposal [DONE]
- Email client about timeline [DONE]
- Review team's pull requests
- Update documentation (PRIORITY - marked with ★)
- Schedule 1:1 meetings
- Fix bug #245 (URGENT - underlined 3x)
- Prepare presentation slides [DONE]
- Submit expense report

DEADLINES:
- 2025-01-20: Project proposal due [DONE]
- 2025-01-22: Presentation (Friday)
- 2025-01-24: Expense report deadline

SUMMARY: Weekly work tasks list with focus on project delivery and team management. 3 of 8 tasks completed. High priority items: documentation update (marked with star) and bug #245 (urgent, heavily underlined). Most items due this week.

PRIORITY_LEVEL: high

KEY_TOPICS: project management, code review, presentations, bug fixes
```

**PRIORITY RULES:**
- If "urgent", "ASAP", "!!" present → PRIORITY_LEVEL: urgent
- If > 50% tasks have deadlines this week → PRIORITY_LEVEL: high
- If mostly routine tasks → PRIORITY_LEVEL: medium
''';
  }
  
  /// Weekly Planner template instructions
  static String _getWeeklyPlannerInstructions() {
    return '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 ROCKETBOOK WEEKLY PLANNER TEMPLATE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is a WEEKLY PLANNER page. Focus on:

**REQUIRED EXTRACTIONS:**
1. **Week Identifier** → "Week of [date]" or date range → Use in TITLE
2. **Daily Sections** → Extract events/tasks for each day (Mon-Sun)
3. **All Events** → Extract with day and time
4. **All Tasks** → Extract with target day
5. **Goals/Focus Areas** → Often at top or bottom of page

**WEEKLY PLANNER STRUCTURE:**
- PAGE_TYPE: Must be "planning"
- Organize TASKS by day: "- [Monday] Task description"
- Extract recurring events: "- Every Tuesday: Team meeting"
- Note goals/themes: "Week focus: Project launch"

**VISUAL CUES TO CHECK:**
- 7-day grid or sections (Mon-Sun)
- "Week of" header with date
- Time slots (hourly or block scheduling)
- Goals/Notes section
- Priority/Focus section

**EXAMPLE OUTPUT ENHANCEMENT:**
```
TITLE: Weekly Plan - Week of January 15-21, 2025

SHORT_DESCRIPTION: Weekly schedule with 12 events and 15 tasks distributed across 7 days. Focus: Product launch preparation.

PAGE_TYPE: planning

CORRECTED_TEXT: [Organized by day]
MONDAY (Jan 15):
- 9:00 AM Team standup
- 2:00 PM Client call with Acme Corp
- Finish Q1 report

TUESDAY (Jan 16):
- 10:00 AM Design review
- Review marketing materials
...

TASKS:
- [Monday] Finish Q1 report
- [Monday] Prepare slides for client call
- [Tuesday] Review marketing materials
- [Tuesday] Send contracts to legal
- [Wednesday] Launch product on website
- [Wednesday] Monitor analytics
- [Thursday] Team retrospective
- [Friday] Write launch post-mortem
...

DEADLINES:
- 2025-01-15 14:00: Client call with Acme Corp
- 2025-01-16 10:00: Design review meeting
- 2025-01-17: Product launch day (all day)
- 2025-01-19: Post-mortem report due

SUMMARY: Weekly plan for January 15-21 focused on product launch. Monday: Client presentations and Q1 wrap-up. Tuesday: Final reviews. Wednesday: LAUNCH DAY with monitoring. Thursday-Friday: Retrospective and documentation. 12 meetings scheduled, 15 tasks planned.

KEY_TOPICS: product launch, client meetings, Q1 reporting, team coordination

PRIORITY_LEVEL: high

NOTES: Week focus: Product launch. Critical day is Wednesday Jan 17 - all hands on deck. Monitor for issues throughout the day.
```

**PRIORITY RULES:**
- If launch/release mentioned → PRIORITY_LEVEL: urgent
- If 10+ events/tasks → PRIORITY_LEVEL: high
- Normal weekly planning → PRIORITY_LEVEL: medium
''';
  }
  
  /// Goal Setting template instructions
  static String _getGoalSettingInstructions() {
    return '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 ROCKETBOOK GOAL SETTING TEMPLATE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is a GOAL SETTING page. Focus on:

**REQUIRED EXTRACTIONS:**
1. **Main Goal/Objective** → Use as TITLE
2. **Target Date** → Extract to DEADLINES
3. **Milestones/Sub-goals** → Extract to TASKS
4. **Success Metrics** → Note in SUMMARY
5. **Action Steps** → Extract to TASKS
6. **Obstacles/Risks** → Note in NOTES
7. **Resources Needed** → Note in NOTES

**GOAL-SPECIFIC ANALYSIS:**
- PAGE_TYPE: Must be "planning" or "personal"
- Identify goal type: career, personal, health, financial, learning
- Note timeframe: short-term (<3 months), medium (3-12 months), long-term (1+ year)
- Extract SMART criteria if present:
  - Specific: Clear description
  - Measurable: Metrics mentioned
  - Achievable: Realistic scope
  - Relevant: Why mentioned
  - Time-bound: Deadline set

**VISUAL CUES TO CHECK:**
- "Goal:", "Objective:", "Target:" fields
- Milestone sections with dates
- Progress tracking area
- Why/Motivation section
- Action plan section

**EXAMPLE OUTPUT ENHANCEMENT:**
```
TITLE: Complete AWS Solutions Architect Certification

SHORT_DESCRIPTION: Professional development goal to obtain AWS certification within 3 months through structured learning and hands-on practice.

PAGE_TYPE: personal

CORRECTED_TEXT:
Goal: Complete AWS Solutions Architect Associate Certification
Target: April 1, 2025
Why: Career advancement, salary increase, work on cloud projects

Milestones:
□ Complete online course (by Feb 15)
□ Build 3 practice projects (by Mar 1)
□ Pass 3 practice exams with 80%+ (by Mar 15)
□ Schedule real exam (Mar 20)
□ Pass certification exam (April 1)

Action Steps:
- Study 1 hour daily (evenings)
- Saturday labs (3 hours)
- Join study group
- Review AWS whitepapers

Resources Needed:
- Udemy course (\$15)
- Practice exam access (\$40)
- AWS free tier account

Potential Obstacles:
- Busy work schedule → Solution: Early morning study
- Complex networking topics → Solution: Extra practice labs

TASKS:
- [Feb 15] Complete AWS online course
- [Mar 1] Build project 1: Static website on S3
- [Mar 1] Build project 2: Lambda + API Gateway
- [Mar 1] Build project 3: EC2 + RDS deployment
- [Mar 15] Pass practice exam 1 (80%+)
- [Mar 15] Pass practice exam 2 (80%+)
- [Mar 15] Pass practice exam 3 (80%+)
- [Mar 20] Schedule certification exam
- Study 1 hour daily
- Complete Saturday labs (3 hours weekly)
- Join AWS study group
- Review AWS architecture whitepapers

DEADLINES:
- 2025-02-15: Complete online course
- 2025-03-01: Finish 3 practice projects
- 2025-03-15: Pass all 3 practice exams
- 2025-03-20: Schedule certification exam
- 2025-04-01: TARGET: Pass AWS certification

SUMMARY: Goal to earn AWS Solutions Architect Associate certification by April 1, 2025 for career advancement. Plan includes online course completion, hands-on projects, practice exams, and daily study routine. Success measured by 80%+ practice exam scores before attempting real certification. Timeline: 3 months with clear milestones.

KEY_TOPICS: AWS certification, cloud computing, professional development, career growth

TECHNICAL_TERMS: AWS, Solutions Architect, S3, Lambda, API Gateway, EC2, RDS, cloud architecture

PRIORITY_LEVEL: high

NEXT_ACTIONS:
- Enroll in Udemy AWS course immediately
- Set up daily study calendar reminders
- Create AWS free tier account
- Find and join AWS study group
- Download practice exam app

NOTES: Motivation: Career advancement + \$15K salary increase potential. Main obstacle is time management - solution is early morning study before work. Course budget: \$55 total (Udemy + practice exams). Goal follows SMART criteria: Specific (AWS SAA cert), Measurable (pass exam), Achievable (3 months with daily study), Relevant (career growth), Time-bound (April 1 deadline).

CONFIDENCE_SCORE: 85
```

**PRIORITY RULES:**
- If deadline < 1 month → PRIORITY_LEVEL: urgent
- If career/financial goal → PRIORITY_LEVEL: high
- If long-term (1+ year) → PRIORITY_LEVEL: medium
''';
  }
  
  /// Brainstorm template instructions
  static String _getBrainstormInstructions() {
    return '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 ROCKETBOOK BRAINSTORM TEMPLATE DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is a BRAINSTORM/MIND MAP page. Focus on:

**REQUIRED EXTRACTIONS:**
1. **Central Topic/Problem** → Use as TITLE
2. **All Ideas** → Extract each idea to KEY_TOPICS
3. **Connections** → Note relationships in VISUAL_ELEMENTS
4. **Categories** → If ideas grouped, note organization
5. **Promising Ideas** → Mark with stars/highlights → Note in NEXT_ACTIONS

**BRAINSTORM-SPECIFIC ANALYSIS:**
- PAGE_TYPE: Must be "brainstorm"
- Identify structure: mind map, list, categories, free-form
- Note visual emphasis: circled ideas, starred items, arrows
- Extract relationships: "X leads to Y", "related to Z"
- Count total ideas generated

**VISUAL CUES TO CHECK:**
- Central bubble/box with main topic
- Radiating branches/connections
- Grouped ideas in sections
- Arrows showing flow/relationships
- Stars/highlights on key ideas
- Doodles or sketches illustrating concepts

**EXAMPLE OUTPUT ENHANCEMENT:**
```
TITLE: New Mobile App Feature Ideas - Brainstorm

SHORT_DESCRIPTION: Creative brainstorming session for mobile app enhancements. 23 ideas generated across 5 categories with 4 high-priority concepts identified.

PAGE_TYPE: brainstorm

CORRECTED_TEXT: [Organized by category]

MAIN TOPIC: Mobile App - Next Features

CATEGORY: User Experience
- Dark mode toggle
- Gesture navigation ⭐
- Voice commands
- Customizable themes
- Haptic feedback

CATEGORY: Social Features
- Share to social media
- In-app messaging ⭐⭐
- User profiles
- Activity feed
- Friend recommendations

CATEGORY: Productivity
- Offline mode ⭐⭐
- Cloud sync
- Export to PDF
- Calendar integration
- Reminders/notifications

CATEGORY: Monetization
- Premium tier
- In-app purchases
- Ad-free option
- Referral program

CATEGORY: Technical
- Performance improvements
- Reduce app size
- Better error handling
- Analytics dashboard

VISUAL_ELEMENTS: Mind map structure with central "Mobile App" node. Five branches radiating outward for each category. Ideas marked with stars (★) indicate high priority based on visual emphasis. Arrows connect related ideas: "Voice commands → Gesture navigation", "Cloud sync → Offline mode", "In-app messaging → User profiles".

KEY_TOPICS: mobile app development, user experience, social features, productivity tools, monetization, technical improvements, dark mode, messaging, offline mode, gesture navigation

TECHNICAL_TERMS: dark mode, haptic feedback, cloud sync, PDF export, API integration, analytics, premium tier

TASKS:
- Research gesture navigation best practices
- Design in-app messaging prototype
- Implement offline mode data caching
- Create premium tier pricing model
- User survey on most wanted features

NEXT_ACTIONS:
- PRIORITY: Prototype in-app messaging (marked ⭐⭐)
- PRIORITY: Implement offline mode (marked ⭐⭐)
- Conduct user survey on feature preferences
- Technical feasibility study for voice commands
- Competitive analysis of similar apps

SUMMARY: Brainstorming session generated 23 feature ideas for mobile app across 5 categories: UX, Social, Productivity, Monetization, Technical. Top priorities identified: In-app messaging and Offline mode (both marked with double stars). Strong emphasis on improving user experience with gesture navigation and voice commands. Monetization through premium tier proposed. Next step: User survey to validate priorities.

PRIORITY_LEVEL: medium

NOTES: Brainstorm context: Product planning for Q2 roadmap. Some ideas have dependencies (e.g., in-app messaging requires user profiles). Voice commands noted as "innovative but complex" - needs feasibility study. Total 23 ideas - should prioritize top 3-5 for initial development.

CONFIDENCE_SCORE: 90
```

**PRIORITY RULES:**
- If planning/decision context → PRIORITY_LEVEL: high
- If exploratory/creative → PRIORITY_LEVEL: medium
- Extract # of ideas to NOTES: "Generated X ideas"
''';
  }
}
