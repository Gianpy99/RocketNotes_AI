// lib/main.dart - CLEANED UP MAIN ENTRY POINT
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// App imports
import 'app/app_simple.dart';
import 'core/constants/app_constants.dart';
import 'core/config/firebase_config_new.dart';
import 'data/models/note_model.dart';
import 'data/models/app_settings_model.dart';
import 'data/models/family_member_model.dart';
import 'data/models/shared_notebook_model.dart';
import 'data/models/usage_monitoring_model.dart';
import 'data/models/topic.dart';
import 'data/services/cost_monitoring_service.dart';
import 'data/services/note_sync_service.dart';
import 'data/services/cloud_backup_service.dart';
import 'features/rocketbook/ai_analysis/ai_service.dart';
import 'features/rocketbook/ocr/ocr_service_real.dart';
import 'features/rocketbook/models/scanned_content.dart';
import 'features/rocketbook/services/symbol_action_service.dart';
import 'core/services/family_service.dart';

// FAMILY_FEATURES implementate - Gestione membri famiglia completata
// - Create FamilyMember model and Hive adapter
// - Add family member authentication/selection
// - Initialize family member data during app startup
// - Add family member switching functionality

// BACKUP_SYSTEM implementato - Sistema backup comprensivo completato
// - Add backup service for notes and settings
// - Implement cloud sync (Google Drive, iCloud)
// - Add automatic backup scheduling
// - Create backup/restore UI in settings

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async work
  WidgetsFlutterBinding.ensureInitialized();

  // ----------------------------------
  // Initialize Firebase
  // ----------------------------------
  await FirebaseConfig.initialize();
  debugPrint('✅ Firebase initialized successfully');

  // ----------------------------------
  // Initialize anonymous authentication for testing (DISABLED - now using login screen)
  // ----------------------------------
  // try {
  //   final userCredential = await FirebaseAuth.instance.signInAnonymously();
  //   final user = userCredential.user;
  //   
  //   if (user != null) {
  //     // Create user document in Firestore for anonymous user
  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'email': null,
  //       'displayName': 'Anonymous User',
  //       'isAnonymous': true,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'lastLoginAt': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //     
  //     debugPrint('✅ Anonymous authentication successful for user: ${user.uid}');
  //   }
  // } catch (e) {
  //   debugPrint('⚠️ Anonymous authentication failed: $e');
  // }

  // ----------------------------------
  // Initialize Hive for local storage
  // ----------------------------------
  try {
    await Hive.initFlutter();
    debugPrint('📦 Hive initialized at path');

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(NoteModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppSettingsModelAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(UsageMonitoringModelAdapter());
    // OCR/AI adapters
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(ScannedContentAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(TableDataAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(DiagramDataAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(OCRMetadataAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(AIAnalysisAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(ActionItemAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(BoundingBoxAdapter());
    if (!Hive.isAdapterRegistered(17)) Hive.registerAdapter(ProcessingStatusAdapter());
    if (!Hive.isAdapterRegistered(18)) Hive.registerAdapter(ContentTypeAdapter());
    if (!Hive.isAdapterRegistered(19)) Hive.registerAdapter(FamilyMemberAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(PriorityAdapter());
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(SharedNotebookAdapter());
    if (!Hive.isAdapterRegistered(23)) Hive.registerAdapter(TopicAdapter());
    
    debugPrint('✅ Hive adapters registered');

    // Open Hive boxes with error handling
    try {
      await Hive.openBox<NoteModel>(AppConstants.notesBox);
      debugPrint('✅ Notes box opened');
    } catch (e) {
      debugPrint('❌ Error opening notes box: $e');
      // Try to delete corrupted box and reopen
      await Hive.deleteBoxFromDisk(AppConstants.notesBox);
      await Hive.openBox<NoteModel>(AppConstants.notesBox);
      debugPrint('✅ Notes box recreated');
    }

    try {
      await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);
      debugPrint('✅ Settings box opened');
    } catch (e) {
      debugPrint('❌ Error opening settings box: $e');
      await Hive.deleteBoxFromDisk(AppConstants.settingsBox);
      await Hive.openBox<AppSettingsModel>(AppConstants.settingsBox);
      debugPrint('✅ Settings box recreated');
    }

    await Hive.openBox<UsageMonitoringModel>('usage_monitoring');
    await Hive.openBox<ScannedContent>(AppConstants.scansBox);
    await Hive.openBox<FamilyMember>('familyMembers');
    await Hive.openBox<Map>('rocketbook_symbol_config');
    await Hive.openBox<Topic>('topics');

    debugPrint('✅ All Hive boxes opened successfully');

    // ----------------------------------
    // Initialize AI Service
    // ----------------------------------
    await AIService.instance.initialize();
    debugPrint('✅ AI Service initialized successfully');

    // ----------------------------------
    // Initialize OCR Service
    // ----------------------------------
    await OCRService.instance.initialize();
    debugPrint('✅ OCR Service initialized successfully');

    // ----------------------------------
    // Initialize Cost Monitoring Service
    // ----------------------------------
    await CostMonitoringService().initialize();
    debugPrint('✅ Cost Monitoring Service initialized successfully');

    // ----------------------------------
    // Initialize Family Service
    // ----------------------------------
    await FamilyService.instance.initialize();
    debugPrint('✅ Family backend: ${AppConstants.familyBackend} (local storage)');
    debugPrint('✅ Family Service initialized successfully');

    // ----------------------------------
    // Initialize Note Sync Service
    // ----------------------------------
    await NoteSyncService.instance.initialize();
    debugPrint('✅ Note Sync Service initialized - auto-sync every 30s');

    // ----------------------------------
    // Initialize Rocketbook Symbol Actions
    // ----------------------------------
    await SymbolActionService.instance.initialize();
    debugPrint('✅ Rocketbook Symbol Actions initialized');

    // ----------------------------------
    // Initialize Cloud Backup Service
    // ----------------------------------
    await CloudBackupService.instance.initialize();
    debugPrint('✅ Cloud Backup Service initialized');

  } catch (e, stackTrace) {
    // Critical error - show it clearly
    debugPrint('❌ CRITICAL ERROR during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Don't continue if Hive fails
    rethrow;
  }

  // ----------------------------------
  // Run the application
  // ----------------------------------
  runApp(
    const ProviderScope(
      child: RocketNotesApp(),
    ),
  );
}