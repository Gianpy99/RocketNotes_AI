// lib/ui/widgets/common/floating_action_menu.dart
import 'package:flutter/material.dart';

class FloatingActionMenu extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback? onNewNote;
  final VoidCallback? onVoiceNote;

  const FloatingActionMenu({
    super.key,
    required this.controller,
    this.onNewNote,
    this.onVoiceNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.scale(
              scale: controller.value,
              child: FloatingActionButton(
                heroTag: "voice",
                mini: true,
                onPressed: onVoiceNote,
                child: const Icon(Icons.mic_rounded),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "main",
          onPressed: () {
            if (controller.isCompleted) {
              controller.reverse();
            } else {
              controller.forward();
            }
            onNewNote?.call();
          },
          child: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
