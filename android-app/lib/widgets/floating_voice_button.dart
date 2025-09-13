// ==========================================
// lib/widgets/floating_voice_button.dart
// ==========================================
import 'package:flutter/material.dart';
import '../widgets/voice_commands_widget.dart';
import '../models/voice_models.dart';

// T030: Floating Voice Commands Button
// - Quick access voice command button for any screen
// - Can be added to existing screens without major modifications
// - Provides instant voice command access
// - Handles navigation and actions automatically

class FloatingVoiceButton extends StatelessWidget {
  final Function(String route)? onNavigate;
  final Function(Map<String, dynamic> data)? onAction;
  final VoiceSettings? settings;
  final EdgeInsets? margin;
  final bool mini;

  const FloatingVoiceButton({
    Key? key,
    this.onNavigate,
    this.onAction,
    this.settings,
    this.margin,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: VoiceCommandsWidget(
        showFullInterface: false,
        settings: settings ?? const VoiceSettings(),
        onNavigate: onNavigate ?? _defaultNavigate,
        onAction: onAction ?? _defaultAction,
      ),
    );
  }

  void _defaultNavigate(String route) {
    // Default navigation handler
    print('Voice navigation: $route');
  }

  void _defaultAction(Map<String, dynamic> data) {
    // Default action handler
    print('Voice action: $data');
  }
}

/// Voice quick actions overlay
class VoiceQuickActionsOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoiceSettings? settings;

  const VoiceQuickActionsOverlay({
    Key? key,
    required this.child,
    this.enabled = true,
    this.settings,
  }) : super(key: key);

  @override
  State<VoiceQuickActionsOverlay> createState() => _VoiceQuickActionsOverlayState();
}

class _VoiceQuickActionsOverlayState extends State<VoiceQuickActionsOverlay> {
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'voice_overlay',
              onPressed: _toggleOverlay,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
              child: Icon(
                _isShowing ? Icons.close : Icons.keyboard_voice,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  void _toggleOverlay() {
    if (_isShowing) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 150,
        right: 16,
        left: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: VoiceCommandsWidget(
              showFullInterface: true,
              settings: widget.settings,
              onNavigate: (route) {
                Navigator.of(context).pushNamed(route);
                _hideOverlay();
              },
              onAction: (data) {
                _showActionResult(data);
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isShowing = true;
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isShowing = false;
    });
  }

  void _showActionResult(Map<String, dynamic> data) {
    String message = 'Action completed';
    
    if (data.containsKey('noteId')) {
      message = 'Note created successfully';
    } else if (data.containsKey('notes')) {
      final notes = data['notes'] as List;
      message = 'Found ${notes.length} notes';
    } else if (data.containsKey('familyId')) {
      message = 'Family created successfully';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }
}