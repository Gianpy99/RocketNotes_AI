import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

/// Types of error that can occur in family operations
enum FamilyErrorType {
  network,
  authentication,
  permission,
  validation,
  server,
  unknown,
}

/// Error information for family operations
class FamilyError {
  final FamilyErrorType type;
  final String message;
  final String? userMessage;
  final String? actionLabel;
  final VoidCallback? action;

  const FamilyError({
    required this.type,
    required this.message,
    this.userMessage,
    this.actionLabel,
    this.action,
  });

  /// Create error from exception
  factory FamilyError.fromException(dynamic exception) {
    if (exception is FamilyError) return exception;

    String message = exception.toString();
    FamilyErrorType type = FamilyErrorType.unknown;
    String? userMessage;
    String? actionLabel;
    VoidCallback? action;

    // Network errors
    if (message.contains('SocketException') || message.contains('Network')) {
      type = FamilyErrorType.network;
      userMessage = 'Connection problem. Please check your internet connection.';
      actionLabel = 'Retry';
    }
    // Authentication errors
    else if (message.contains('unauthorized') || message.contains('forbidden')) {
      type = FamilyErrorType.authentication;
      userMessage = 'You don\'t have permission to perform this action.';
      actionLabel = 'Sign In';
    }
    // Permission errors
    else if (message.contains('permission') || message.contains('access denied')) {
      type = FamilyErrorType.permission;
      userMessage = 'You don\'t have the required permissions.';
      actionLabel = 'Request Access';
    }
    // Validation errors
    else if (message.contains('validation') || message.contains('invalid')) {
      type = FamilyErrorType.validation;
      userMessage = 'Please check your input and try again.';
    }
    // Server errors
    else if (message.contains('500') || message.contains('server error')) {
      type = FamilyErrorType.server;
      userMessage = 'Server is temporarily unavailable. Please try again later.';
      actionLabel = 'Retry';
    }

    return FamilyError(
      type: type,
      message: message,
      userMessage: userMessage ?? 'An unexpected error occurred.',
      actionLabel: actionLabel,
      action: action,
    );
  }
}

/// Service for handling errors and user feedback in family operations
class FamilyErrorHandler {
  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    FamilyError error, {
    String? title,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? _getErrorTitle(error.type)),
        content: Text(error.userMessage ?? error.message),
        actions: [
          if (error.actionLabel != null && error.action != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                error.action!();
              },
              child: Text(error.actionLabel!),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    FamilyError error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userMessage ?? error.message),
        backgroundColor: _getErrorColor(error.type),
        duration: duration,
        action: error.actionLabel != null && error.action != null
            ? SnackBarAction(
                label: error.actionLabel!,
                onPressed: error.action!,
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }

  /// Show success feedback
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show loading dialog
  static Future<T?> showLoadingDialog<T>(
    BuildContext context,
    Future<T> future,
    String message,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );

    try {
      final result = await future;
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        final error = FamilyError.fromException(e);
        showErrorDialog(context, error);
      }
      return null;
    }
  }

  /// Handle async operation with error handling
  static Future<T?> handleAsyncOperation<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showLoadingDialog = false,
  }) async {
    try {
      if (showLoadingDialog && loadingMessage != null) {
        return await _showLoadingDialog(
          context,
          operation(),
          loadingMessage,
        );
      }

      final result = await operation();

      if (successMessage != null && context.mounted) {
        showSuccessSnackBar(context, successMessage);
      }

      return result;
    } catch (e) {
      if (context.mounted) {
        final error = FamilyError.fromException(e);
        showErrorSnackBar(context, error);
      }
      return null;
    }
  }

  /// Show loading dialog (static helper)
  static Future<T?> _showLoadingDialog<T>(
    BuildContext context,
    Future<T> future,
    String message,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );

    try {
      final result = await future;
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        final error = FamilyError.fromException(e);
        showErrorDialog(context, error);
      }
      return null;
    }
  }

  /// Get error title based on type
  static String _getErrorTitle(FamilyErrorType type) {
    switch (type) {
      case FamilyErrorType.network:
        return 'Connection Error';
      case FamilyErrorType.authentication:
        return 'Authentication Required';
      case FamilyErrorType.permission:
        return 'Permission Denied';
      case FamilyErrorType.validation:
        return 'Invalid Input';
      case FamilyErrorType.server:
        return 'Server Error';
      case FamilyErrorType.unknown:
        return 'Error';
    }
  }

  /// Get error color based on type
  static Color _getErrorColor(FamilyErrorType type) {
    switch (type) {
      case FamilyErrorType.network:
        return Colors.orange;
      case FamilyErrorType.authentication:
        return Colors.red;
      case FamilyErrorType.permission:
        return Colors.red;
      case FamilyErrorType.validation:
        return Colors.amber;
      case FamilyErrorType.server:
        return Colors.red;
      case FamilyErrorType.unknown:
        return Colors.red;
    }
  }
}

/// Error boundary widget for family screens
class FamilyErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, FamilyError)? errorBuilder;
  final VoidCallback? onError;

  const FamilyErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<FamilyErrorBoundary> createState() => _FamilyErrorBoundaryState();
}

class _FamilyErrorBoundaryState extends State<FamilyErrorBoundary> {
  FamilyError? _error;

  @override
  void initState() {
    super.initState();
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
    };
  }

  void _handleError(dynamic error, StackTrace? stackTrace) {
    final familyError = FamilyError.fromException(error);
    setState(() => _error = familyError);
    widget.onError?.call();

    // Log error for debugging
    debugPrint('Family Error Boundary caught error: ${familyError.message}');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!);
      }

      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: _getErrorColor(_error!.type),
                ),
                const SizedBox(height: 16),
                Text(
                  _error!.userMessage ?? _error!.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  Color _getErrorColor(FamilyErrorType type) {
    switch (type) {
      case FamilyErrorType.network:
        return Colors.orange;
      case FamilyErrorType.authentication:
        return Colors.red;
      case FamilyErrorType.permission:
        return Colors.red;
      case FamilyErrorType.validation:
        return Colors.amber;
      case FamilyErrorType.server:
        return Colors.red;
      case FamilyErrorType.unknown:
        return Colors.grey;
    }
  }
}

/// Provider for error handler
final familyErrorHandlerProvider = Provider<FamilyErrorHandler>((ref) {
  return FamilyErrorHandler();
});
