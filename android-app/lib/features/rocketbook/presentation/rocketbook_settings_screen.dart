// ==========================================
// lib/features/rocketbook/presentation/rocketbook_settings_screen.dart
// ==========================================

import 'package:flutter/material.dart';
import '../models/rocketbook_template.dart';
import '../services/symbol_action_service.dart';
import '../../../data/repositories/topic_repository.dart';
import '../../../data/models/topic.dart';

class RocketbookSettingsScreen extends StatefulWidget {
  const RocketbookSettingsScreen({super.key});

  @override
  State<RocketbookSettingsScreen> createState() => _RocketbookSettingsScreenState();
}

class _RocketbookSettingsScreenState extends State<RocketbookSettingsScreen> {
  List<SymbolAction> _configurations = [];
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  Future<void> _loadConfigurations() async {
    setState(() => _isLoading = true);
    
    try {
      // Load symbol configurations
      _configurations = SymbolActionService.instance.getAllConfigurations();
      
      // Load topics for topic assignment
      final topicRepo = TopicRepository();
      _topics = await topicRepo.getAllTopics();
      
      debugPrint('[RocketbookSettings] Loaded ${_configurations.length} symbols and ${_topics.length} topics');
    } catch (e) {
      debugPrint('[RocketbookSettings] Error loading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configurations: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConfiguration(SymbolAction action) async {
    await SymbolActionService.instance.updateConfiguration(action);
    await _loadConfigurations();
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all symbol configurations to their defaults. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SymbolActionService.instance.saveConfigurations(DefaultSymbolConfigs.defaults);
      await _loadConfigurations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset to default configurations')),
        );
      }
    }
  }

  void _editSymbol(SymbolAction action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SymbolConfigSheet(
        action: action,
        topics: _topics,
        onSave: _updateConfiguration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rocketbook Symbols'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Defaults',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _configurations.length,
                    itemBuilder: (context, index) {
                      final config = _configurations[index];
                      return _buildSymbolCard(config);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          const Text(
            'Configure Symbol Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Set what happens when you mark each symbol at the bottom of a Rocketbook page',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolCard(SymbolAction config) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _editSymbol(config),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Symbol icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: config.enabled
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  config.symbol.icon,
                  size: 28,
                  color: config.enabled
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              
              // Symbol info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.symbol.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.enabled
                          ? config.actionType.displayName
                          : 'Disabled',
                      style: TextStyle(
                        color: config.enabled ? Colors.blue : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    if (config.destination != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        config.destination!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Enabled switch
              Switch(
                value: config.enabled,
                onChanged: (value) {
                  _updateConfiguration(config.copyWith(enabled: value));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Symbol Configuration Bottom Sheet
// ==========================================

class _SymbolConfigSheet extends StatefulWidget {
  final SymbolAction action;
  final List<Topic> topics;
  final Future<void> Function(SymbolAction) onSave;

  const _SymbolConfigSheet({
    required this.action,
    required this.topics,
    required this.onSave,
  });

  @override
  State<_SymbolConfigSheet> createState() => _SymbolConfigSheetState();
}

class _SymbolConfigSheetState extends State<_SymbolConfigSheet> {
  late SymbolActionType _selectedActionType;
  late String? _destination;
  late bool _enabled;
  final _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedActionType = widget.action.actionType;
    _destination = widget.action.destination;
    _enabled = widget.action.enabled;
    if (_destination != null) {
      _destinationController.text = _destination!;
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _save() async {
    final newAction = SymbolAction(
      symbol: widget.action.symbol,
      actionType: _selectedActionType,
      destination: _destination?.isNotEmpty == true ? _destination : null,
      enabled: _enabled,
    );
    
    Navigator.pop(context);
    await widget.onSave(newAction);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(widget.action.symbol.icon, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Configure ${widget.action.symbol.displayName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action type dropdown
            const Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<SymbolActionType>(
              value: _selectedActionType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: SymbolActionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedActionType = value;
                    _destination = null;
                    _destinationController.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Destination field
            if (_needsDestination) ...[
              Text(
                _getDestinationLabel(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_selectedActionType == SymbolActionType.assignToTopic)
                _buildTopicDropdown()
              else
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _getDestinationHint(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _destination = value,
                ),
              const SizedBox(height: 16),
            ],
            
            // Enabled switch
            SwitchListTile(
              title: const Text('Enabled'),
              subtitle: const Text('Enable this symbol action'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _needsDestination {
    return _selectedActionType == SymbolActionType.email ||
           _selectedActionType == SymbolActionType.assignToTopic ||
           _selectedActionType == SymbolActionType.googleDrive ||
           _selectedActionType == SymbolActionType.dropbox ||
           _selectedActionType == SymbolActionType.custom;
  }

  String _getDestinationLabel() {
    switch (_selectedActionType) {
      case SymbolActionType.email:
        return 'Email Address';
      case SymbolActionType.assignToTopic:
        return 'Topic';
      case SymbolActionType.googleDrive:
      case SymbolActionType.dropbox:
        return 'Folder Path';
      case SymbolActionType.custom:
        return 'Custom Configuration';
      default:
        return 'Destination';
    }
  }

  String _getDestinationHint() {
    switch (_selectedActionType) {
      case SymbolActionType.email:
        return 'example@email.com';
      case SymbolActionType.googleDrive:
      case SymbolActionType.dropbox:
        return '/My Folder/Notes';
      case SymbolActionType.custom:
        return 'Enter custom settings';
      default:
        return '';
    }
  }

  Widget _buildTopicDropdown() {
    return DropdownButtonFormField<String>(
      value: _destination,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: const Text('Select a topic'),
      items: widget.topics.map((topic) {
        return DropdownMenuItem(
          value: topic.id,
          child: Row(
            children: [
              if (topic.icon != null)
                Icon(topic.icon, size: 20, color: topic.color),
              const SizedBox(width: 8),
              Text(topic.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _destination = value);
      },
    );
  }
}
