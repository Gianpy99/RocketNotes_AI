import 'package:flutter/material.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final List<String> _logs = [];
  final ValueNotifier<List<String>> logsNotifier = ValueNotifier([]);

  void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    
    // Standard debug print
    debugPrint(logEntry);
    
    // Add to in-app log
    _logs.add(logEntry);
    if (_logs.length > 100) {
      _logs.removeAt(0); // Keep only last 100 logs
    }
    
    logsNotifier.value = List.from(_logs);
  }

  void clear() {
    _logs.clear();
    logsNotifier.value = [];
  }

  List<String> get logs => List.from(_logs);
}

class DebugLogViewer extends StatelessWidget {
  const DebugLogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => DebugLogger().clear(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: DebugLogger().logsNotifier,
        builder: (context, logs, child) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('No logs yet'),
            );
          }
          
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index]; // Reverse order
              return Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLogColor(log),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('❌') || log.contains('Error')) {
      return Colors.red..withValues(alpha: 0.1);
    } else if (log.contains('⚠️') || log.contains('Warning')) {
      return Colors.orange..withValues(alpha: 0.1);
    } else if (log.contains('✅') || log.contains('success')) {
      return Colors.green..withValues(alpha: 0.1);
    } else if (log.contains('🤖') || log.contains('AI')) {
      return Colors.blue..withValues(alpha: 0.1);
    }
    return Colors.grey..withValues(alpha: 0.05);
  }
}

class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 10,
      child: FloatingActionButton.small(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DebugLogViewer()),
          );
        },
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }
}
