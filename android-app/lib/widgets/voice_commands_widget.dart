// ==========================================
// lib/widgets/voice_commands_widget.dart
// ==========================================
import 'package:flutter/material.dart';
import '../models/voice_models.dart';
import '../services/voice_commands_service.dart';

// T030: Voice Commands Integration Widget
// - Voice command button with microphone UI
// - Real-time speech recognition feedback
// - Voice command results display
// - Integration with app navigation and actions

class VoiceCommandsWidget extends StatefulWidget {
  final Function(String route)? onNavigate;
  final Function(Map<String, dynamic> data)? onAction;
  final bool showFullInterface;
  final VoiceSettings? settings;

  const VoiceCommandsWidget({
    super.key,
    this.onNavigate,
    this.onAction,
    this.showFullInterface = false,
    this.settings,
  });

  @override
  State<VoiceCommandsWidget> createState() => _VoiceCommandsWidgetState();
}

class _VoiceCommandsWidgetState extends State<VoiceCommandsWidget>
    with TickerProviderStateMixin {
  final VoiceCommandsService _voiceService = VoiceCommandsService();
  VoiceRecognitionState _state = const VoiceRecognitionState();
  String _lastResult = '';
  VoiceCommandResult? _lastCommandResult;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVoiceService() async {
    final result = await _voiceService.initialize();
    if (result.isSuccess) {
      setState(() {
        _state = _state.copyWith(isAvailable: true);
      });
    } else {
      setState(() {
        _state = _state.copyWith(
          status: VoiceRecognitionStatus.error,
          error: result.error,
        );
      });
    }
  }

  Future<void> _startListening() async {
    if (_state.isListening) {
      await _stopListening();
      return;
    }

    setState(() {
      _state = _state.copyWith(
        status: VoiceRecognitionStatus.listening,
        error: null,
      );
      _lastResult = '';
      _lastCommandResult = null;
    });

    _pulseController.repeat(reverse: true);

    final result = await _voiceService.startListening(
      timeout: widget.settings?.listeningTimeout,
    );

    if (!result.isSuccess) {
      setState(() {
        _state = _state.copyWith(
          status: VoiceRecognitionStatus.error,
          error: result.error,
        );
      });
      _stopAnimations();
    }
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() {
      _state = _state.copyWith(status: VoiceRecognitionStatus.idle);
    });
    _stopAnimations();
  }

  void _stopAnimations() {
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showFullInterface) {
      return _buildFullInterface();
    } else {
      return _buildCompactButton();
    }
  }

  Widget _buildCompactButton() {
    return FloatingActionButton(
      onPressed: _state.isAvailable ? _startListening : null,
      backgroundColor: _getButtonColor(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _state.isListening ? _pulseAnimation.value : 1.0,
            child: Icon(
              _getButtonIcon(),
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullInterface() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voice Commands',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Status indicator
            _buildStatusIndicator(),
            const SizedBox(height: 16),
            
            // Voice button
            Center(
              child: GestureDetector(
                onTap: _state.isAvailable ? _startListening : null,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getButtonColor(),
                        boxShadow: _state.isListening
                            ? [
                                BoxShadow(
                                  color: _getButtonColor().withValues(alpha: 0.3),
                                  blurRadius: 20 * _pulseAnimation.value,
                                  spreadRadius: 5 * _pulseAnimation.value,
                                ),
                              ]
                            : null,
                      ),
                      child: Transform.scale(
                        scale: _state.isListening ? _pulseAnimation.value : 1.0,
                        child: Icon(
                          _getButtonIcon(),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Current text or result
            if (_lastResult.isNotEmpty || _lastCommandResult != null)
              _buildResultDisplay(),
            
            // Help text
            if (_state.status == VoiceRecognitionStatus.idle && 
                _lastResult.isEmpty && 
                _lastCommandResult == null)
              _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_state.status) {
      case VoiceRecognitionStatus.idle:
        statusText = 'Ready';
        statusColor = Colors.grey;
        statusIcon = Icons.mic_none;
        break;
      case VoiceRecognitionStatus.listening:
        statusText = 'Listening...';
        statusColor = Colors.blue;
        statusIcon = Icons.mic;
        break;
      case VoiceRecognitionStatus.processing:
        statusText = 'Processing...';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case VoiceRecognitionStatus.speaking:
        statusText = 'Speaking...';
        statusColor = Colors.green;
        statusIcon = Icons.volume_up;
        break;
      case VoiceRecognitionStatus.error:
        statusText = 'Error: ${_state.error ?? "Unknown error"}';
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastResult.isNotEmpty) ...[
            Text(
              'You said:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"$_lastResult"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_lastCommandResult != null) const SizedBox(height: 12),
          ],
          
          if (_lastCommandResult != null) ...[
            Row(
              children: [
                Icon(
                  _lastCommandResult!.success ? Icons.check_circle : Icons.error,
                  color: _lastCommandResult!.success ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _lastCommandResult!.success ? 'Success' : 'Failed',
                  style: TextStyle(
                    color: _lastCommandResult!.success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _lastCommandResult!.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try saying:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...const [
            '"Create note shopping list"',
            '"Search for meeting notes"',
            '"Go to family"',
            '"Help"',
          ].map((example) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $example',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getButtonColor() {
    switch (_state.status) {
      case VoiceRecognitionStatus.listening:
        return Colors.red;
      case VoiceRecognitionStatus.processing:
        return Colors.orange;
      case VoiceRecognitionStatus.speaking:
        return Colors.green;
      case VoiceRecognitionStatus.error:
        return Colors.red.withValues(alpha: 0.7);
      default:
        return Theme.of(context).primaryColor;
    }
  }

  IconData _getButtonIcon() {
    switch (_state.status) {
      case VoiceRecognitionStatus.listening:
        return Icons.stop;
      case VoiceRecognitionStatus.processing:
        return Icons.hourglass_empty;
      case VoiceRecognitionStatus.speaking:
        return Icons.volume_up;
      case VoiceRecognitionStatus.error:
        return Icons.error;
      default:
        return Icons.mic;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Voice command settings widget
class VoiceSettingsWidget extends StatefulWidget {
  final VoiceSettings settings;
  final Function(VoiceSettings) onSettingsChanged;

  const VoiceSettingsWidget({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<VoiceSettingsWidget> createState() => _VoiceSettingsWidgetState();
}

class _VoiceSettingsWidgetState extends State<VoiceSettingsWidget> {
  late VoiceSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
  }

  void _updateSetting<T>(T value, VoiceSettings Function(T) updater) {
    setState(() {
      _currentSettings = updater(value);
    });
    widget.onSettingsChanged(_currentSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Commands Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        SwitchListTile(
          title: const Text('Enable Voice Commands'),
          subtitle: const Text('Turn on voice recognition and commands'),
          value: _currentSettings.enabled,
          onChanged: (value) => _updateSetting(
            value,
            (enabled) => _currentSettings.copyWith(enabled: enabled),
          ),
        ),
        
        SwitchListTile(
          title: const Text('Auto Listen'),
          subtitle: const Text('Automatically start listening after a command'),
          value: _currentSettings.autoListen,
          onChanged: _currentSettings.enabled
              ? (value) => _updateSetting(
                  value,
                  (autoListen) => _currentSettings.copyWith(autoListen: autoListen),
                )
              : null,
        ),
        
        SwitchListTile(
          title: const Text('Confirm Actions'),
          subtitle: const Text('Ask for confirmation before executing commands'),
          value: _currentSettings.confirmActions,
          onChanged: _currentSettings.enabled
              ? (value) => _updateSetting(
                  value,
                  (confirm) => _currentSettings.copyWith(confirmActions: confirm),
                )
              : null,
        ),
        
        if (_currentSettings.enabled) ...[
          const SizedBox(height: 16),
          Text(
            'Speech Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          ListTile(
            title: const Text('Speech Rate'),
            subtitle: Slider(
              value: _currentSettings.speechRate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(_currentSettings.speechRate * 10).round() / 10}x',
              onChanged: (value) => _updateSetting(
                value,
                (rate) => _currentSettings.copyWith(speechRate: rate),
              ),
            ),
          ),
          
          ListTile(
            title: const Text('Pitch'),
            subtitle: Slider(
              value: _currentSettings.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${(_currentSettings.pitch * 10).round() / 10}',
              onChanged: (value) => _updateSetting(
                value,
                (pitch) => _currentSettings.copyWith(pitch: pitch),
              ),
            ),
          ),
          
          ListTile(
            title: const Text('Volume'),
            subtitle: Slider(
              value: _currentSettings.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_currentSettings.volume * 100).round()}%',
              onChanged: (value) => _updateSetting(
                value,
                (volume) => _currentSettings.copyWith(volume: volume),
              ),
            ),
          ),
        ],
      ],
    );
  }
}