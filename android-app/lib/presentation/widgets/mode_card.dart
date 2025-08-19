// lib/presentation/widgets/mode_card.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ModeCard extends StatelessWidget {
  final String mode;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = mode == 'work' ? AppColors.workBlue : AppColors.personalGreen;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                mode == 'work' ? Icons.work : Icons.home,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mode.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode == 'work' ? 'Professional' : 'Personal Life',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
