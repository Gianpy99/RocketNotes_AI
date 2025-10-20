import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../family/services/biometric_auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/biometric_lock_provider.dart';
import '../../../presentation/providers/app_providers.dart';

/// Schermata di blocco app con autenticazione biometrica
class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final String title;
  final String subtitle;

  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.title = 'Sblocca Pensieve',
    this.subtitle = 'Usa la tua biometria per accedere',
  });

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Avvia autenticazione solo se l'app è in foreground
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('🔐 [APP_LOCK] App lifecycle changed: $state');
    
    // Quando l'app torna in foreground E non stiamo già autenticando, riprova
    if (state == AppLifecycleState.resumed && !_isAuthenticating && mounted) {
      debugPrint('🔐 [APP_LOCK] App resumed, starting authentication...');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _authenticate();
        }
      });
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('🔐 [APP_LOCK] App paused/inactive, authentication will wait');
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔐 [APP_LOCK] Starting biometric authentication...');
      final service = ref.read(biometricAuthServiceProvider);
      
      // Verifica disponibilità
      debugPrint('🔐 [APP_LOCK] Checking biometric availability...');
      final isAvailable = await service.isBiometricAvailable();
      debugPrint('🔐 [APP_LOCK] Biometric available: $isAvailable');
      
      if (!isAvailable) {
        debugPrint('🔐 [APP_LOCK] Biometric not available, unlocking automatically');
        setState(() {
          _errorMessage = 'Autenticazione biometrica non disponibile. Sblocco automatico...';
        });
        // Auto-unlock if biometrics aren't available
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          ref.read(appLockedProvider.notifier).state = false;
          widget.onUnlocked();
        }
        return;
      }

      // Autentica
      debugPrint('🔐 [APP_LOCK] Calling authenticate()...');
      final authenticated = await service.authenticate(
        reason: 'Conferma la tua identità per accedere a Pensieve',
      );
      debugPrint('🔐 [APP_LOCK] Authentication result: $authenticated');

      if (authenticated) {
        // Sblocca l'app nel provider
        debugPrint('🔐 [APP_LOCK] Authentication successful, unlocking...');
        if (mounted) {
          ref.read(appLockedProvider.notifier).state = false;
          widget.onUnlocked();
        }
      } else {
        debugPrint('🔐 [APP_LOCK] Authentication failed');
        setState(() {
          _errorMessage = 'Autenticazione fallita. Riprova o disabilita il blocco biometrico dalle impostazioni.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      debugPrint('🔐 [APP_LOCK] Authentication error: $e');
      
      // Se l'errore è userCanceled (cancellazione di sistema), non mostrare errore
      // Questo succede quando il telefono viene bloccato mentre il prompt sta per apparire
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('usercanceled') || errorString.contains('user canceled')) {
        debugPrint('🔐 [APP_LOCK] System canceled authentication (phone locked), staying on lock screen');
        setState(() {
          _isAuthenticating = false;
          // Non impostare _errorMessage, così l'utente non vede l'errore
        });
      } else {
        // Per altri errori, mostra il messaggio
        setState(() {
          _errorMessage = 'Errore durante l\'autenticazione: $e';
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricAvailable = ref.watch(biometricAvailableProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o icona app
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),

                // Titolo
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Sottotitolo
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Icona biometrica animata
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: _isAuthenticating
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : biometricAvailable.when(
                          data: (available) {
                            if (available) {
                              return Column(
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    size: 80,
                                    color: _errorMessage != null
                                        ? Colors.red.shade300
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tocca per autenticarti',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return const Icon(
                                Icons.error_outline_rounded,
                                size: 80,
                                color: Colors.orange,
                              );
                            }
                          },
                          loading: () => const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          error: (_, __) => const Icon(
                            Icons.error_outline_rounded,
                            size: 80,
                            color: Colors.red,
                          ),
                        ),
                ),

                const SizedBox(height: 32),

                // Messaggio di errore
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade300.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Pulsante riprova
                if (!_isAuthenticating)
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Riprova'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Pulsante disabilita blocco (per emergenza)
                if (!_isAuthenticating && _errorMessage != null)
                  TextButton.icon(
                    onPressed: () async {
                      // Disabilita il blocco biometrico nelle impostazioni
                      final settingsNotifier = ref.read(appSettingsProvider.notifier);
                      final currentSettings = ref.read(appSettingsProvider).value;
                      if (currentSettings != null) {
                        await settingsNotifier.updateSettings(
                          currentSettings.copyWith(enableBiometric: false),
                        );
                      }
                      // Sblocca l'app
                      if (mounted) {
                        ref.read(appLockedProvider.notifier).state = false;
                        widget.onUnlocked();
                      }
                    },
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Disabilita blocco biometrico'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade200,
                    ),
                  ),

                const SizedBox(height: 8),

                // Pulsante esci
                TextButton.icon(
                  onPressed: () {
                    SystemNavigator.pop(); // Esci dall'app
                  },
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Esci dall\'app'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget wrapper che mostra AppLockScreen se biometria è abilitata
class BiometricAppGuard extends ConsumerWidget {
  final Widget child;

  const BiometricAppGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Qui dovresti leggere dalle impostazioni se biometria è abilitata
    // Per ora, usa un provider o SharedPreferences
    
    // Esempio:
    // final settings = ref.watch(appSettingsProvider);
    // final biometricEnabled = settings.value?.enableBiometric ?? false;
    
    // TODO: Implementa la logica di verifica delle impostazioni
    // Per ora, sempre disabilitato - rimuovi il commento sotto per testare
    // const biometricEnabled = false;

    // Ritorna sempre il child - per abilitare il lock,
    // decommenta biometricEnabled e il codice seguente
    return child;
    
    // Codice per quando biometricEnabled = true:
    // if (biometricEnabled) {
    //   return AppLockScreen(
    //     onUnlocked: () {
    //       Navigator.of(context).pushReplacement(
    //         MaterialPageRoute(builder: (_) => child),
    //       );
    //     },
    //   );
    // }
  }
}
