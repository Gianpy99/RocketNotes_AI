// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/nfc_service.dart';
import '../../data/services/deep_link_service.dart';
import '../../features/rocketbook/camera/camera_screen.dart';
import '../providers/app_providers_simple.dart';
import '../widgets/mode_card.dart';
import '../widgets/quick_action_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? initialMode;

  const HomeScreen({super.key, this.initialMode});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final NfcService _nfcService = NfcService();
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _isNfcScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appModeProvider.notifier).setMode(widget.initialMode!);
      });
    }
    _listenToDeepLinks();
    
    // DEBUG TOAST
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐛 DEBUG: Cerca icona BUG ARANCIONE in alto a destra!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  void _listenToDeepLinks() {
    _deepLinkService.linkStream.listen((uri) {
      final mode = _deepLinkService.extractModeFromUri(uri);
      if (mode != null) {
        ref.read(appModeProvider.notifier).setMode(mode);
      }
    });
  }

  Future<void> _scanNfcTag() async {
    if (_isNfcScanning) return;

    setState(() {
      _isNfcScanning = true;
    });

    try {
      final result = await _nfcService.readNfcTag();
      if (result.success && result.data != null) {
        final mode = _nfcService.extractModeFromUri(result.data!);
        if (mode != null) {
          ref.read(appModeProvider.notifier).setMode(mode);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to $mode mode'),
                backgroundColor: mode == 'work' 
                    ? AppColors.workBlue 
                    : AppColors.personalGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading NFC tag: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isNfcScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(appModeProvider);
    final recentNotes = ref.watch(recentNotesProvider(7)); // Get notes from last 7 days

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'RocketNotes AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: currentMode == 'work'
                        ? [AppColors.workBlue, AppColors.workBlue.withValues(alpha: 0.8)]
                        : [AppColors.personalGreen, AppColors.personalGreen.withValues(alpha: 0.8)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.rocket_launch,
                    size: 60,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            actions: [
              // DEBUG BUTTON - SUPER VISIBILE
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.orange, size: 30),
                onPressed: () async {
                  // DEBUG: Mostra tutte le note salvate
                  await _showDebugNotesDialog();
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Mode Indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentMode == 'work'
                          ? AppColors.workBlue.withValues(alpha: 0.1)
                          : AppColors.personalGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentMode == 'work'
                            ? AppColors.workBlue
                            : AppColors.personalGreen,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentMode == 'work' ? Icons.work : Icons.home,
                          color: currentMode == 'work'
                              ? AppColors.workBlue
                              : AppColors.personalGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Mode',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${currentMode.toUpperCase()} MODE',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: currentMode == 'work'
                                    ? AppColors.workBlue
                                    : AppColors.personalGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mode Selection
                  Text(
                    'Switch Mode',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ModeCard(
                          mode: 'work',
                          isSelected: currentMode == 'work',
                          onTap: () => ref.read(appModeProvider.notifier).setMode('work'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ModeCard(
                          mode: 'personal',
                          isSelected: currentMode == 'personal',
                          onTap: () => ref.read(appModeProvider.notifier).setMode('personal'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // NFC Scanning
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.nfc,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'NFC Quick Switch',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap an NFC tag to quickly switch modes',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isNfcScanning ? null : _scanNfcTag,
                          icon: _isNfcScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.nfc),
                          label: Text(_isNfcScanning ? 'Scanning...' : 'Scan NFC Tag'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'New Note',
                          color: AppColors.primaryBlue,
                          onTap: () => context.push('/editor'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.list_alt,
                          label: 'All Notes',
                          color: AppColors.accentOrange,
                          onTap: () => context.push('/notes'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Notes
                  recentNotes.when(
                    data: (notes) {
                      if (notes.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Notes',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...notes.take(3).map((note) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: note.mode == 'work'
                                          ? AppColors.workBlue
                                          : AppColors.personalGreen,
                                      child: Icon(
                                        note.mode == 'work' ? Icons.work : Icons.home,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      note.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      _formatDate(note.updatedAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    onTap: () => context.push('/editor?id=${note.id}'),
                                  ),
                                )),
                          ],
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // FLOATING ACTION BUTTON per camera
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RocketbookCameraScreen(),
            ),
          );
        },
        backgroundColor: Colors.deepPurple[700],
        tooltip: 'Open Camera',
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showDebugNotesDialog() async {
    final notesAsyncValue = ref.read(notesProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐛 DEBUG: Note Salvate'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: notesAsyncValue.when(
            data: (notes) {
              if (notes.isEmpty) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Nessuna nota salvata'),
                    Text('Le note scattate dalla camera dovrebbero apparire qui'),
                  ],
                );
              }
              
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        note.title.isNotEmpty ? note.title : 'Senza titolo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.content.length > 100 
                              ? '${note.content.substring(0, 100)}...'
                              : note.content,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Creata: ${_formatDate(note.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'ID: ${note.id}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Errore: $error'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.read(notesProvider.notifier).loadNotes(),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(notesProvider.notifier).loadNotes();
              Navigator.of(context).pop();
              _showDebugNotesDialog(); // Riapri dopo il refresh
            },
            child: const Text('🔄 Aggiorna'),
          ),
        ],
      ),
    );
  }
}
