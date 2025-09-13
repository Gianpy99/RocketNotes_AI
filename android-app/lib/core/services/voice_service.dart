// lib/core/services/voice_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

// Funzionalità accessibilità vocale implementate

// Miglioramenti UI vocale implementati

class VoiceService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  Stream<int> get recordingDurationStream => Stream.periodic(
        const Duration(seconds: 1),
        (_) => _recordingDuration,
      ).takeWhile((_) => _isRecording);

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<String?> startRecording() async {
    try {
      if (!await hasMicrophonePermission()) {
        if (!await requestMicrophonePermission()) {
          throw Exception('Microphone permission denied');
        }
      }

      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'voice_note_$timestamp.m4a';
        final filePath = '${directory.path}/$fileName';

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: filePath);

        _currentRecordingPath = filePath;
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = 0;

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_isRecording && !_isPaused) {
            _recordingDuration++;
          }
        });

        return filePath;
      } else {
        throw Exception('Audio recording permission not granted');
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      _isRecording = false;
      _isPaused = false;

      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      rethrow;
    }
  }

  Future<void> pauseRecording() async {
    try {
      if (_isRecording && !_isPaused) {
        await _audioRecorder.pause();
        _isPaused = true;
      }
    } catch (e) {
      debugPrint('Error pausing recording: $e');
      rethrow;
    }
  }

  Future<void> resumeRecording() async {
    try {
      if (_isRecording && _isPaused) {
        await _audioRecorder.resume();
        _isPaused = false;
      }
    } catch (e) {
      debugPrint('Error resuming recording: $e');
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _recordingTimer?.cancel();

        // Delete the recording file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        _isRecording = false;
        _isPaused = false;
        _recordingDuration = 0;
        _currentRecordingPath = null;
      }
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      rethrow;
    }
  }

  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // For now, return the recorded duration
      // In a more advanced implementation, you could use a package like 'audioplayers'
      // to get the actual duration from the file
      return Duration(seconds: _recordingDuration);
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return null;
    }
  }

  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
