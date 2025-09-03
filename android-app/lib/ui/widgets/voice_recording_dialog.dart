// lib/ui/widgets/voice_recording_dialog.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/voice_service.dart';

class VoiceRecordingDialog extends StatefulWidget {
  const VoiceRecordingDialog({super.key});

  @override
  State<VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<VoiceRecordingDialog>
    with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _initializeRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _initializeRecording() async {
    try {
      final hasPermission = await _voiceService.hasMicrophonePermission();
      if (!hasPermission) {
        final granted = await _voiceService.requestMicrophonePermission();
        if (!granted) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission is required for voice notes'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await _startRecording();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      final path = await _voiceService.startRecording();
      if (path != null && mounted) {
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });

        // Listen to recording duration updates
        _voiceService.recordingDurationStream.listen((duration) {
          if (mounted) {
            setState(() {
              _recordingDuration = duration;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _voiceService.stopRecording();
      if (path != null && mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
        });

        // Return the recording path to the caller
        Navigator.of(context).pop(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _voiceService.pauseRecording();
      if (mounted) {
        setState(() {
          _isPaused = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _voiceService.resumeRecording();
      if (mounted) {
        setState(() {
          _isPaused = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _voiceService.cancelRecording();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: _isRecording && !_isPaused ? AppColors.error : AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isRecording
                        ? (_isPaused ? 'Recording Paused' : 'Recording...')
                        : 'Voice Note',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recording Visualization
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording && !_isPaused ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording && !_isPaused
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isRecording && !_isPaused
                            ? AppColors.error
                            : AppColors.primary,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      _isPaused ? Icons.pause : Icons.mic,
                      size: 48,
                      color: _isRecording && !_isPaused
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Recording Duration
            Text(
              _voiceService.formatDuration(_recordingDuration),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Recording in progress...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause/Resume Button
                if (_isRecording)
                  FloatingActionButton(
                    onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  ),

                const SizedBox(width: 24),

                // Stop Button
                FloatingActionButton(
                  onPressed: _stopRecording,
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.stop),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            Text(
              'Tap pause to temporarily stop, stop to save your recording',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
