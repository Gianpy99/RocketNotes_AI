// lib/data/services/widget_deep_link_service.dart
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class WidgetDeepLinkService {
  static const MethodChannel _channel = MethodChannel('com.example.rocket_notes_ai/deeplink');
  
  /// Ottiene il link iniziale dai widget Android
  static Future<String?> getInitialWidgetLink() async {
    try {
      final String? link = await _channel.invokeMethod('getInitialLink');
      debugPrint('📱 Widget initial link: $link');
      return link;
    } on PlatformException catch (e) {
      debugPrint('❌ Error getting initial widget link: ${e.message}');
      return null;
    }
  }
  
  /// Naviga alla route specificata dal deep link
  static void handleWidgetLink(BuildContext context, String? link) {
    if (link == null) return;
    
    debugPrint('🔗 Handling widget link: $link');
    
    // Usa GoRouter per navigare
    try {
      context.go(link);
      debugPrint('✅ Navigated to: $link');
    } catch (e) {
      debugPrint('❌ Error navigating to widget link: $e');
    }
  }
  
  /// Inizializza il servizio e gestisce il link iniziale
  static Future<void> initialize(BuildContext context) async {
    final initialLink = await getInitialWidgetLink();
    if (initialLink != null && context.mounted) {
      // Aspetta che il widget tree sia completamente costruito
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleWidgetLink(context, initialLink);
      });
    }
  }
}
