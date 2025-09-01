// ==========================================
// lib/app/app_lifecycle.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/app_providers.dart';
import '../data/services/deep_link_service.dart';
import 'routes.dart';

class AppLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleInitialDeepLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Handle if needed
        break;
    }
  }

  void _handleInitialDeepLink() {
    // Check for deep links on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deepLinkState = ref.read(deepLinkStateProvider);
      if (deepLinkState.hasUnhandledLink && deepLinkState.lastDeepLink != null) {
        _processDeepLink(deepLinkState.lastDeepLink!);
      }
    });
  }

  void _handleAppResumed() {
    // Refresh data when app comes to foreground
    ref.read(notesProvider.notifier).loadNotes();
    
    // Check for new deep links
    final deepLinkState = ref.read(deepLinkStateProvider);
    if (deepLinkState.hasUnhandledLink && deepLinkState.lastDeepLink != null) {
      _processDeepLink(deepLinkState.lastDeepLink!);
    }
  }

  void _handleAppPaused() {
    // Save any pending data
    // This could trigger auto-backup if enabled
  }

  void _handleAppDetached() {
    // Cleanup resources
    ref.read(deepLinkStateProvider.notifier).dispose();
  }

  void _processDeepLink(DeepLinkData linkData) {
    // Process the deep link and navigate accordingly
    if (linkData.mode != null) {
      // Update current mode
      ref.read(appSettingsProvider.notifier).updateDefaultMode(linkData.mode!);
      
      // Navigate based on action
      switch (linkData.action) {
        case 'editor':
        case 'new':
          AppRouter.goToNoteEditor(mode: linkData.mode);
          break;
        case 'notes':
        case 'list':
          AppRouter.goToNotes(mode: linkData.mode);
          break;
        case 'search':
          final query = linkData.parameters['q'];
          AppRouter.goToSearch(query: query);
          break;
        default:
          AppRouter.goToHome(mode: linkData.mode, action: linkData.action);
      }
      
      // Mark link as handled
      ref.read(deepLinkStateProvider.notifier).markLinkAsHandled();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for deep link changes
    ref.listen<DeepLinkState>(deepLinkStateProvider, (previous, next) {
      if (next.hasUnhandledLink && next.lastDeepLink != null) {
        _processDeepLink(next.lastDeepLink!);
      }
    });
    
    // Listen for NFC reads
    ref.listen<NfcState>(nfcStateProvider, (previous, next) {
      if (next.lastReadData != null && next.lastReadMode != null) {
        // Handle NFC read result
        AppRouter.goToHome(mode: next.lastReadMode);
        ref.read(nfcStateProvider.notifier).clearLastRead();
      }
    });
    
    return widget.child;
  }
}
