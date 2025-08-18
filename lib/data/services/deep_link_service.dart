// lib/data/services/deep_link_service.dart
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Stream<Uri> get linkStream => _appLinks.uriLinkStream;

  Future<Uri?> getInitialLink() async {
    return await _appLinks.getInitialLink();
  }

  String? extractModeFromUri(Uri uri) {
    if (uri.scheme == 'rocketnotes') {
      if (uri.host == 'work' || uri.path.contains('work')) {
        return 'work';
      } else if (uri.host == 'personal' || uri.path.contains('personal')) {
        return 'personal';
      }
    }
    return null;
  }

  String? extractActionFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length > 1) {
      return segments[1];
    }
    return null;
  }

  Map<String, String> extractParametersFromUri(Uri uri) {
    return uri.queryParameters;
  }
}

