// ==========================================
// lib/app/app.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/themes/app_theme.dart';
import '../presentation/providers/app_providers_simple.dart';
import 'routes_simple.dart';

class RocketNotesApp extends ConsumerStatefulWidget {
  const RocketNotesApp({super.key});

  @override
  ConsumerState<RocketNotesApp> createState() => _RocketNotesAppState();
}

class _RocketNotesAppState extends ConsumerState<RocketNotesApp> {
  @override
  void initState() {
    super.initState();
    // Initialize app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appInitializationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final initAsync = ref.watch(appInitializationProvider);
    
    return initAsync.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rocket_launch,
                  size: 64,
                  color: Colors.blue,
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing RocketNotes...'),
              ],
            ),
          ),
        ),
      ),
      error: (error, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Initialization Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(appInitializationProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (_) => MaterialApp.router(
        title: 'RocketNotes AI',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Global error boundary and loading overlay
          return Consumer(
            builder: (context, ref, _) {
              final globalError = ref.watch(globalErrorProvider);
              final isLoading = ref.watch(globalLoadingProvider);
              
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  
                  // Global loading overlay
                  if (isLoading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  
                  // Global error snackbar
                  if (globalError != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Material(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.red,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  globalError,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref.read(globalErrorProvider.notifier).state = null;
                                },
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
