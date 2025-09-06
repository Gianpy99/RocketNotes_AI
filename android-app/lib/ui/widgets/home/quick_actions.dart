// lib/ui/widgets/home/quick_actions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/nfc_service.dart';
import '../voice_recording_dialog.dart';

// TODO: FAMILY_FEATURES - Add family quick actions
// - Add "Family Notes" quick action button
// - Add "Emergency Contacts" quick action
// - Add "Family Calendar" integration
// - Add "Shared Shopping List" quick action
// - Consider family member avatar/profile switching

class QuickActions extends StatefulWidget {
  const QuickActions({super.key});

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  final NfcService _nfcService = NfcService();
  bool _isNfcScanning = false;

  Future<void> _scanNfcTag() async {
    if (_isNfcScanning) return;

    setState(() {
      _isNfcScanning = true;
    });

    try {
      final result = await _nfcService.readNfcTag();

      if (result.success && result.data != null) {
        final mode = _nfcService.extractModeFromUri(result.data!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NFC tag scanned! Mode: ${mode ?? 'Unknown'}'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Here you could navigate to a specific screen or perform an action
        // based on the NFC tag data
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to read NFC tag: ${result.error ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
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
      if (mounted) {
        setState(() {
          _isNfcScanning = false;
        });
      }
    }
  }

  Future<void> _startVoiceNote() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => const VoiceRecordingDialog(),
    );

    if (result != null && result.isNotEmpty) {
      // Navigate to note editor with the voice note path
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/note-editor',
          arguments: {'voiceNotePath': result},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.add_rounded,
            title: 'New Note',
            onTap: () => context.push('/editor'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.nfc_rounded,
            title: 'NFC Scan',
            onTap: _isNfcScanning ? null : () => _scanNfcTag(),
            isLoading: _isNfcScanning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.mic_rounded,
            title: 'Voice Note',
            onTap: _startVoiceNote,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            isLoading
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(),
                  )
                : Icon(
                    icon,
                    color: onTap == null ? Colors.grey : AppColors.primary,
                    size: 32,
                  ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: onTap == null ? Colors.grey : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
