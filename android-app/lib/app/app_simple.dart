// Simplified app entry point
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/themes/app_theme.dart';
import '../presentation/providers/app_providers_simple.dart';
import '../features/security/screens/app_lock_screen.dart';
import '../features/security/providers/biometric_lock_provider.dart';
import 'routes_simple.dart';

class RocketNotesApp extends ConsumerWidget {
  const RocketNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Pensieve',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Aggiungi il wrapper per il blocco biometrico
        return BiometricLockWrapper(child: child ?? const SizedBox());
      },
    );
  }
}

/// Wrapper che gestisce il blocco biometrico dell'app
class BiometricLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricLockWrapper({super.key, required this.child});

  @override
  ConsumerState<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends ConsumerState<BiometricLockWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    debugPrint('🔐 [BIOMETRIC] BiometricLockWrapper initialized');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Blocca l'app quando va in background se biometria è abilitata
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final biometricEnabled = ref.read(biometricLockEnabledProvider);
      if (biometricEnabled) {
        ref.read(appLockedProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockedProvider);
    final biometricEnabled = ref.watch(biometricLockEnabledProvider);

    debugPrint('🔐 [BIOMETRIC] Build - isLocked: $isLocked, biometricEnabled: $biometricEnabled');

    // Se la biometria è abilitata E l'app è bloccata, mostra la schermata di blocco
    if (biometricEnabled && isLocked) {
      debugPrint('🔐 [BIOMETRIC] Showing lock screen');
      return AppLockScreen(
        onUnlocked: () {
          debugPrint('🔐 [BIOMETRIC] App unlocked');
          // Sblocca l'app
          ref.read(appLockedProvider.notifier).state = false;
        },
      );
    }

    debugPrint('🔐 [BIOMETRIC] Showing normal app');
    return widget.child;
  }
}
