// ==========================================
// lib/presentation/widgets/audio_note_recorder.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/voice_service.dart';
import '../../data/services/audio_transcription_service.dart';
import 'dart:async';

/// Provider for voice service
final voiceServiceProvider = Provider<VoiceService>((ref) => VoiceService());

/// State for audio recording
class AudioRecordingState {
  final bool isRecording;
  final bool isPaused;
  final bool isProcessing;
  final int duration;
  final String? recordingPath;
  final AudioTranscriptionResult? transcriptionResult;
  final String? error;

  AudioRecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.isProcessing = false,
    this.duration = 0,
    this.recordingPath,
    this.transcriptionResult,
    this.error,
  });

  AudioRecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    bool? isProcessing,
    int? duration,
    String? recordingPath,
    AudioTranscriptionResult? transcriptionResult,
    String? error,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isProcessing: isProcessing ?? this.isProcessing,
      duration: duration ?? this.duration,
      recordingPath: recordingPath ?? this.recordingPath,
      transcriptionResult: transcriptionResult ?? this.transcriptionResult,
      error: error ?? this.error,
    );
  }
}

/// Notifier for audio recording state
class AudioRecordingNotifier extends StateNotifier<AudioRecordingState> {
  AudioRecordingNotifier(this.voiceService) : super(AudioRecordingState());

  final VoiceService voiceService;
  Timer? _durationTimer;

  Future<void> startRecording() async {
    try {
      final path = await voiceService.startRecording();
      if (path != null) {
        state = state.copyWith(
          isRecording: true,
          recordingPath: path,
          error: null,
        );
        _startDurationTimer();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopRecording() async {
    try {
      _durationTimer?.cancel();
      final path = await voiceService.stopRecording();
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        recordingPath: path,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pauseRecording() async {
    try {
      await voiceService.pauseRecording();
      _durationTimer?.cancel();
      state = state.copyWith(isPaused: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeRecording() async {
    try {
      await voiceService.resumeRecording();
      _startDurationTimer();
      state = state.copyWith(isPaused: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cancelRecording() async {
    try {
      _durationTimer?.cancel();
      await voiceService.cancelRecording();
      state = AudioRecordingState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> transcribeAudio({String? targetLanguage}) async {
    if (state.recordingPath == null) return;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Get user's preferred language from settings if not provided
      if (targetLanguage == null) {
        // TODO: add user language preference to settings
        // final settings = await SettingsRepository().getSettings();
        targetLanguage = 'it'; // default Italian, make this configurable
      }

      final result = await AudioTranscriptionService.instance.transcribeAudio(
        audioFilePath: state.recordingPath!,
        targetLanguage: targetLanguage,
        autoTranslate: true,
      );

      state = state.copyWith(
        isProcessing: false,
        transcriptionResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Transcription failed: $e',
      );
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRecording && !state.isPaused) {
        state = state.copyWith(duration: state.duration + 1);
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}

/// Provider for audio recording state
final audioRecordingProvider =
    StateNotifierProvider<AudioRecordingNotifier, AudioRecordingState>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return AudioRecordingNotifier(voiceService);
});

/// Audio Note Recorder Widget
class AudioNoteRecorder extends ConsumerWidget {
  final Function(String transcription, String? translation)? onTranscriptionComplete;
  final String? targetLanguage;

  const AudioNoteRecorder({
    super.key,
    this.onTranscriptionComplete,
    this.targetLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioRecordingProvider);
    final notifier = ref.read(audioRecordingProvider.notifier);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  state.isRecording ? Icons.mic : Icons.mic_none,
                  color: state.isRecording ? Colors.red : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isRecording
                            ? (state.isPaused ? 'Paused' : 'Recording...')
                            : 'Audio Note',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (state.isRecording)
                        Text(
                          _formatDuration(state.duration),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recording controls
            if (!state.isProcessing && state.transcriptionResult == null)
              _buildRecordingControls(context, state, notifier),

            // Processing indicator
            if (state.isProcessing) _buildProcessingIndicator(),

            // Transcription result
            if (state.transcriptionResult != null)
              _buildTranscriptionResult(context, state, notifier),

            // Error display
            if (state.error != null) _buildError(state),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls(
    BuildContext context,
    AudioRecordingState state,
    AudioRecordingNotifier notifier,
  ) {
    if (!state.isRecording) {
      return ElevatedButton.icon(
        onPressed: notifier.startRecording,
        icon: const Icon(Icons.mic),
        label: const Text('Start Recording'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    return Column(
      children: [
        // Waveform or level indicator
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  10,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: (20 + (i % 3) * 10).toDouble(),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.cancelRecording,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: state.isPaused
                    ? notifier.resumeRecording
                    : notifier.pauseRecording,
                icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(state.isPaused ? 'Resume' : 'Pause'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await notifier.stopRecording();
                  await notifier.transcribeAudio(targetLanguage: targetLanguage);
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop & Transcribe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Column(
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Processing audio...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transcribing with AI',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTranscriptionResult(
    BuildContext context,
    AudioRecordingState state,
    AudioRecordingNotifier notifier,
  ) {
    final result = state.transcriptionResult!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transcription completed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      'Language: ${result.detectedLanguage} | ${result.provider}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Metrics
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetricChip('${result.transcription.length} chars', Icons.text_fields),
            _buildMetricChip('${(result.confidence * 100).toStringAsFixed(0)}%', Icons.speed),
            _buildMetricChip('${result.processingTime.inMilliseconds}ms', Icons.timer),
            _buildMetricChip('\$${result.estimatedCost.toStringAsFixed(4)}', Icons.attach_money),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Transcription text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transcription:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              SelectableText(
                result.transcription,
                style: const TextStyle(fontSize: 14),
              ),
              
              // Translation if available
              if (result.translation != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Translation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  result.translation!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Reset to record again
                  notifier.cancelRecording();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Record Again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  onTranscriptionComplete?.call(
                    result.transcription,
                    result.translation,
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Use Transcription'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(AudioRecordingState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: Colors.blue.shade50,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
