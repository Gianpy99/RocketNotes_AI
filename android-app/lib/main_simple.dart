import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/note_model.dart';
import 'screens/note_editor_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'features/rocketbook/camera/web_camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NoteModelAdapter());
    }

    // Open box
    await Hive.openBox('notes');
  } catch (e) {
    print('Error initializing Hive: $e');
  }

  runApp(const ProviderScope(child: RocketNotesApp()));
}

// Simple notes provider
final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  NotesNotifier() : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    try {
      final box = Hive.box('notes');
      final notes = box.values.cast<NoteModel>().toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = notes;
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  void loadNotes() => _loadNotes();

  Future<void> addNote(NoteModel note) async {
    try {
      final box = Hive.box('notes');
      await box.put(note.id, note);
      _loadNotes();
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      final box = Hive.box('notes');
      await box.put(note.id, note);
      _loadNotes();
    } catch (e) {
      print('Error updating note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final box = Hive.box('notes');
      await box.delete(id);
      _loadNotes();
    } catch (e) {
      print('Error deleting note: $e');
    }
  }
}

class RocketNotesApp extends StatelessWidget {
  const RocketNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RocketNotes AI',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Filter provider
final filterProvider = StateProvider<String>((ref) => 'all');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotes = ref.watch(notesProvider);
    final filter = ref.watch(filterProvider);
    
    final filteredNotes = filter == 'all' 
        ? allNotes 
        : allNotes.where((note) => note.mode == filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 RocketNotes AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tutte'),
                  selected: filter == 'all',
                  onSelected: (selected) {
                    ref.read(filterProvider.notifier).state = 'all';
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.work, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text('Lavoro'),
                    ],
                  ),
                  selected: filter == 'work',
                  onSelected: (selected) {
                    ref.read(filterProvider.notifier).state = 'work';
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Personale'),
                    ],
                  ),
                  selected: filter == 'personal',
                  onSelected: (selected) {
                    ref.read(filterProvider.notifier).state = 'personal';
                  },
                ),
              ],
            ),
          ),
          // Notes list
          Expanded(
            child: filteredNotes.isEmpty
                ? EmptyNotesWidget(filter: filter)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return NoteCard(note: note);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildExpandableFAB(context),
    );
  }
  
  Widget _buildExpandableFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Analysis FAB
        FloatingActionButton(
          heroTag: "ai",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIAnalysisScreen()),
            );
          },
          backgroundColor: Colors.orange,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Camera FAB
        FloatingActionButton(
          heroTag: "scan",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WebRocketbookCameraScreen()),
            );
          },
          backgroundColor: Colors.deepPurple[700],
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Create Note FAB
        FloatingActionButton.extended(
          heroTag: "create",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
            );
          },
          label: const Text('Nuova Nota'),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class EmptyNotesWidget extends StatelessWidget {
  final String filter;
  
  const EmptyNotesWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    String message;
    String description;
    
    switch (filter) {
      case 'work':
        message = 'Nessuna nota di lavoro';
        description = 'Crea la tua prima nota di lavoro';
        break;
      case 'personal':
        message = 'Nessuna nota personale';
        description = 'Crea la tua prima nota personale';
        break;
      default:
        message = 'Nessuna nota ancora';
        description = 'Tocca il pulsante + per creare la tua prima nota';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.note_add,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NoteCard extends ConsumerWidget {
  final NoteModel note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(note: note),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: note.mode == 'work' ? Colors.blue.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note.mode == 'work' ? Icons.work : Icons.home,
                          size: 16,
                          color: note.mode == 'work' ? Colors.blue : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.mode.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: note.mode == 'work' ? Colors.blue : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (note.title.isNotEmpty) ...[
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m fa';
      }
      return '${difference.inHours}h fa';
    } else if (difference.inDays == 1) {
      return 'Ieri';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
