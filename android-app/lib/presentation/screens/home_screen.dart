// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/nfc_service.dart';
import '../../data/services/deep_link_service.dart';
import '../providers/app_providers.dart';
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
      final uri = await _nfcService.readNfcTag();
      if (uri != null) {
        final mode = _nfcService.extractModeFromUri(uri);
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
    final recentNotes = ref.watch(recentNotesProvider);

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
                        ? [AppColors.workBlue, AppColors.workBlue.withOpacity(0.8)]
                        : [AppColors.personalGreen, AppColors.personalGreen.withOpacity(0.8)],
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
                          ? AppColors.workBlue.withOpacity(0.1)
                          : AppColors.personalGreen.withOpacity(0.1),
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
                  if (recentNotes.isNotEmpty) ...[
                    Text(
                      'Recent Notes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...recentNotes.take(3).map((note) => Card(
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
                ],
              ),
            ),
          ),
        ],
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
}
