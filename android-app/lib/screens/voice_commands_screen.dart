// ==========================================
// lib/screens/voice_commands_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import '../models/voice_models.dart';
import '../widgets/voice_commands_widget.dart';
import '../services/voice_commands_service.dart';

// T030: Voice Commands Integration Screen
// - Full-screen voice commands interface
// - Voice settings configuration
// - Command history and help
// - Integration with app navigation

class VoiceCommandsScreen extends StatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  State<VoiceCommandsScreen> createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen>
    with SingleTickerProviderStateMixin {
  final VoiceCommandsService _voiceService = VoiceCommandsService();
  
  late TabController _tabController;
  VoiceSettings _settings = const VoiceSettings();
  final List<VoiceCommandHistoryEntry> _commandHistory = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In real app, load from shared preferences or database
    setState(() {
      _settings = const VoiceSettings(
        enabled: true,
        language: 'en-US',
        speechRate: 0.5,
        pitch: 1.0,
        volume: 1.0,
        autoListen: false,
        confirmActions: true,
        listeningTimeout: Duration(seconds: 30),
        continuousListening: false,
      );
    });
  }

  Future<void> _saveSettings(VoiceSettings settings) async {
    // In real app, save to shared preferences or database
    setState(() {
      _settings = settings;
    });
    
    // Apply settings to voice service
    await _voiceService.setLanguage(settings.language);
  }

  void _handleNavigation(String route) {
    Navigator.of(context).pushNamed(route);
  }

  void _handleAction(Map<String, dynamic> data) {
    // Handle voice command actions
    if (data.containsKey('noteId')) {
      // Navigate to note editor with created note
      _showSnackBar('Note created: ${data['noteId']}');
    } else if (data.containsKey('notes')) {
      // Show search results
      final notes = data['notes'] as List;
      _showSnackBar('Found ${notes.length} notes');
    } else if (data.containsKey('familyId')) {
      // Navigate to family details
      _showSnackBar('Family created: ${data['familyId']}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Commands'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Voice'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.help), text: 'Help'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVoiceTab(),
          _buildSettingsTab(),
          _buildHelpTab(),
        ],
      ),
    );
  }

  Widget _buildVoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main voice interface
          VoiceCommandsWidget(
            showFullInterface: true,
            settings: _settings,
            onNavigate: _handleNavigation,
            onAction: _handleAction,
          ),
          
          const SizedBox(height: 24),
          
          // Quick action buttons
          _buildQuickActions(),
          
          const SizedBox(height: 24),
          
          // Command history (if any)
          if (_commandHistory.isNotEmpty) _buildCommandHistory(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  'Create Note',
                  Icons.note_add,
                  () => _simulateVoiceCommand('create note'),
                ),
                _buildActionChip(
                  'Search Notes',
                  Icons.search,
                  () => _simulateVoiceCommand('search for'),
                ),
                _buildActionChip(
                  'Go to Family',
                  Icons.family_restroom,
                  () => _simulateVoiceCommand('go to family'),
                ),
                _buildActionChip(
                  'Voice Help',
                  Icons.help,
                  () => _simulateVoiceCommand('help'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Future<void> _simulateVoiceCommand(String command) async {
    final result = await _voiceService.processVoiceCommand(command);
    
    if (result.success) {
      _handleAction(result.data ?? {});
      if (result.commandType == VoiceCommandType.navigate) {
        final route = result.data?['route'] as String?;
        if (route != null) {
          _handleNavigation(route);
        }
      }
    }
    
    _showSnackBar(result.message);
  }

  Widget _buildCommandHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Commands',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commandHistory.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final entry = _commandHistory[index];
                return ListTile(
                  leading: Icon(
                    entry.result.success ? Icons.check_circle : Icons.error,
                    color: entry.result.success ? Colors.green : Colors.red,
                  ),
                  title: Text(entry.command.originalText),
                  subtitle: Text(entry.result.message),
                  trailing: Text(
                    '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: VoiceSettingsWidget(
        settings: _settings,
        onSettingsChanged: _saveSettings,
      ),
    );
  }

  Widget _buildHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpSection(
            'Getting Started',
            [
              'Tap the microphone button to start listening',
              'Speak clearly and wait for the blue pulse animation',
              'The app will process your command and respond',
              'Use natural language - no special keywords required',
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildHelpSection(
            'Note Commands',
            [
              '"Create note shopping list" - Creates a new note',
              '"Create note meeting notes about project discussion" - Creates note with content',
              '"Search for meeting" - Finds notes containing "meeting"',
              '"Find note about groceries" - Search with different phrasing',
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildHelpSection(
            'Family Commands',
            [
              '"Create family called The Smiths" - Creates a new family',
              '"Create family My Family" - Creates family with simple name',
              '"Invite family member john@example.com" - (Coming soon)',
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildHelpSection(
            'Navigation Commands',
            [
              '"Go to notes" - Opens notes list',
              '"Go to family" - Opens family screen',
              '"Go to settings" - Opens app settings',
              '"Go to home" - Returns to main screen',
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildHelpSection(
            'Other Commands',
            [
              '"Help" - Shows available commands',
              '"Backup notes" - (Coming soon)',
              'More commands will be added in future updates',
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildTipsSection(),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Card(
  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for Better Recognition',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...const [
              'Speak clearly in a quiet environment',
              'Hold the device about 6 inches from your mouth',
              'Use natural language - avoid robot-like speech',
              'Wait for the animation to stop before speaking again',
              'Check your microphone permissions if voice doesn\'t work',
            ].map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}