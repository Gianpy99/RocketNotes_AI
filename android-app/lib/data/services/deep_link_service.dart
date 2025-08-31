// ==========================================
// lib/data/services/deep_link_service.dart
// ==========================================
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Get the stream of incoming links
  Stream<Uri> get linkStream => _appLinks.uriLinkStream;

  // Get the initial link when app is launched
  Future<Uri?> getInitialLink() async {
    try {
      // TODO: Fix AppLinks API - getInitialLink method not available
      // For now, return null to allow compilation
      print('getInitialLink temporarily disabled due to API incompatibility');
      return null;
      
      // return await _appLinks.getInitialLink();
    } catch (e) {
      print('Error getting initial link: $e');
      return null;
    }
  }

  // Start listening to deep links
  void startListening(Function(Uri) onLinkReceived) {
    _linkSubscription?.cancel();
    _linkSubscription = linkStream.listen(
      onLinkReceived,
      onError: (error) {
        print('Deep link error: $error');
      },
    );
  }

  // Stop listening to deep links
  void stopListening() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  // Extract mode from URI
  String? extractModeFromUri(Uri uri) {
    try {
      if (uri.scheme == AppConstants.uriScheme) {
        if (uri.host == AppConstants.workMode || uri.path.contains(AppConstants.workMode)) {
          return AppConstants.workMode;
        } else if (uri.host == AppConstants.personalMode || uri.path.contains(AppConstants.personalMode)) {
          return AppConstants.personalMode;
        }
      }
      return null;
    } catch (e) {
      print('Error extracting mode from URI: $e');
      return null;
    }
  }

  // Extract action from URI
  String? extractActionFromUri(Uri uri) {
    try {
      final segments = uri.pathSegments;
      if (segments.length > 1) {
        return segments[1];
      }
      return null;
    } catch (e) {
      print('Error extracting action from URI: $e');
      return null;
    }
  }

  // Extract parameters from URI
  Map<String, String> extractParametersFromUri(Uri uri) {
    try {
      return uri.queryParameters;
    } catch (e) {
      print('Error extracting parameters from URI: $e');
      return {};
    }
  }

  // Parse deep link into structured data
  DeepLinkData? parseDeepLink(Uri uri) {
    try {
      if (uri.scheme != AppConstants.uriScheme) {
        return null;
      }

      final mode = extractModeFromUri(uri);
      final action = extractActionFromUri(uri);
      final parameters = extractParametersFromUri(uri);

      return DeepLinkData(
        mode: mode,
        action: action,
        parameters: parameters,
        rawUri: uri.toString(),
      );
    } catch (e) {
      print('Error parsing deep link: $e');
      return null;
    }
  }

  // Validate deep link format
  bool isValidRocketNotesLink(Uri uri) {
    try {
      return uri.scheme == AppConstants.uriScheme &&
             (uri.host == AppConstants.workMode || uri.host == AppConstants.personalMode);
    } catch (e) {
      print('Error validating deep link: $e');
      return false;
    }
  }

  // Generate deep link
  String generateDeepLink({
    required String mode,
    String? action,
    Map<String, String>? parameters,
  }) {
    try {
      final buffer = StringBuffer('${AppConstants.uriScheme}://$mode');
      
      if (action != null) {
        buffer.write('/$action');
      }
      
      if (parameters != null && parameters.isNotEmpty) {
        buffer.write('?');
        final queryParams = parameters.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        buffer.write(queryParams);
      }
      
      return buffer.toString();
    } catch (e) {
      print('Error generating deep link: $e');
      return '${AppConstants.uriScheme}://$mode';
    }
  }

  // Dispose resources
  void dispose() {
    stopListening();
  }
}

// Deep link data structure
class DeepLinkData {
  final String? mode;
  final String? action;
  final Map<String, String> parameters;
  final String rawUri;

  DeepLinkData({
    this.mode,
    this.action,
    required this.parameters,
    required this.rawUri,
  });

  @override
  String toString() {
    return 'DeepLinkData(mode: $mode, action: $action, parameters: $parameters, rawUri: $rawUri)';
  }
}
