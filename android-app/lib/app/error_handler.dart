// ==========================================
// lib/app/error_handler.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/app_providers.dart';

class GlobalErrorHandler {
  static void initialize(ProviderContainer container) {
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _handleError(container, details.exception, details.stack);
    };
  }

  static void _handleError(ProviderContainer container, Object error, StackTrace? stack) {
    // Log error
    debugPrint('Global Error: $error');
    if (stack != null) {
      debugPrint('Stack Trace: $stack');
    }

    // Show error to user
    container.read(globalErrorProvider.notifier).state = error.toString();
    
    // Clear error after some time
    Future.delayed(const Duration(seconds: 5), () {
      container.read(globalErrorProvider.notifier).state = null;
    });
  }
}

// Error boundary widget
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return child; // In a real app, you'd wrap this with error handling
  }
}
