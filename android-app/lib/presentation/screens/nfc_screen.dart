import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NfcScreen extends ConsumerWidget {
  final String? initialAction;
  
  const NfcScreen({super.key, this.initialAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'NFC Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Manage NFC tags and interactions.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (initialAction != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Initial Action: $initialAction',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.nfc, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'NFC functionality coming soon!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
