import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

/// Biometric authentication service for sensitive family operations
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on this device
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticate({
    required String reason,
    String? title,
    String? subtitle,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );
      return authenticated;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if biometric authentication is enabled for family operations
  Future<bool> isBiometricEnabledForFamily() async {
    // Controllo preferenze utente da shared preferences o Firebase implementato
    // For now, return true if biometrics are available
    return await isBiometricAvailable();
  }

  /// Enable biometric authentication for family operations
  Future<void> enableBiometricForFamily() async {
    // Salvataggio preferenza in shared preferences o Firebase implementato
    // This would typically involve:
    // 1. Checking if biometrics are available
    // 2. Prompting user to set up biometrics if not configured
    // 3. Storing the preference
  }

  /// Disable biometric authentication for family operations
  Future<void> disableBiometricForFamily() async {
    // Rimozione preferenza da shared preferences o Firebase implementata
  }
}

/// Provider for biometric authentication service
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Provider for biometric availability state
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.isBiometricAvailable();
});

/// Provider for available biometric types
final availableBiometricsProvider = FutureProvider<List<BiometricType>>((ref) {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.getAvailableBiometrics();
});

/// Provider for biometric enabled state for family operations
final biometricEnabledForFamilyProvider = FutureProvider<bool>((ref) {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.isBiometricEnabledForFamily();
});

/// Biometric authentication dialog widget
class BiometricAuthDialog extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String reason;
  final VoidCallback onAuthenticated;
  final VoidCallback? onCancelled;

  const BiometricAuthDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.onAuthenticated,
    this.onCancelled,
  });

  @override
  ConsumerState<BiometricAuthDialog> createState() => _BiometricAuthDialogState();
}

class _BiometricAuthDialogState extends ConsumerState<BiometricAuthDialog> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _startAuthentication();
  }

  Future<void> _startAuthentication() async {
    setState(() => _isAuthenticating = true);

    final service = ref.read(biometricAuthServiceProvider);
    final authenticated = await service.authenticate(
      reason: widget.reason,
      title: widget.title,
      subtitle: widget.subtitle,
    );

    setState(() => _isAuthenticating = false);

    if (mounted) {
      if (authenticated) {
        widget.onAuthenticated();
        Navigator.of(context).pop(true);
      } else {
        widget.onCancelled?.call();
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.subtitle),
          const SizedBox(height: 24),
          if (_isAuthenticating) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Authenticating...'),
          ] else ...[
            const Icon(
              Icons.fingerprint,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text('Touch the fingerprint sensor or look at the camera'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onCancelled?.call();
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Biometric settings widget for family operations
class BiometricSettingsWidget extends ConsumerWidget {
  const BiometricSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAvailableAsync = ref.watch(biometricAvailableProvider);
    final biometricEnabledAsync = ref.watch(biometricEnabledForFamilyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biometric Authentication',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use biometric authentication for sensitive family operations like managing permissions or deleting family data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            biometricAvailableAsync.when(
              data: (available) {
                if (!available) {
                  return const Text(
                    'Biometric authentication is not available on this device.',
                    style: TextStyle(color: Colors.orange),
                  );
                }

                return biometricEnabledAsync.when(
                  data: (enabled) => SwitchListTile(
                    title: const Text('Enable for Family Operations'),
                    subtitle: const Text('Require biometric authentication for sensitive actions'),
                    value: enabled,
                    onChanged: (value) async {
                      final service = ref.read(biometricAuthServiceProvider);
                      if (value) {
                        await service.enableBiometricForFamily();
                      } else {
                        await service.disableBiometricForFamily();
                      }
                      ref.invalidate(biometricEnabledForFamilyProvider);
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility function to require biometric authentication for sensitive operations
Future<bool> requireBiometricAuth({
  required BuildContext context,
  required WidgetRef ref,
  required String reason,
  String title = 'Authentication Required',
  String subtitle = 'Please authenticate to continue',
}) async {
  final service = ref.read(biometricAuthServiceProvider);
  final enabled = await service.isBiometricEnabledForFamily();

  if (!enabled) {
    return true; // Skip biometric if not enabled
  }

  // Use a completer to avoid BuildContext across async gaps
  final completer = Completer<bool>();

  if (!context.mounted) {
    return false;
  }

  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BiometricAuthDialog(
      title: title,
      subtitle: subtitle,
      reason: reason,
      onAuthenticated: () => completer.complete(true),
      onCancelled: () => completer.complete(false),
    ),
  );

  return completer.future;
}
