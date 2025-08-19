// lib/presentation/widgets/mode_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/app_providers.dart';

class ModeSelector extends ConsumerWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appModeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    title: 'Work',
                    icon: Icons.work,
                    color: AppColors.workBlue,
                    isSelected: currentMode == AppConstants.workMode,
                    onTap: () => ref.read(appModeProvider.notifier).setMode(AppConstants.workMode),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeButton(
                    title: 'Personal',
                    icon: Icons.person,
                    color: AppColors.personalGreen,
                    isSelected: currentMode == AppConstants.personalMode,
                    onTap: () => ref.read(appModeProvider.notifier).setMode(AppConstants.personalMode),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
