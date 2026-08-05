import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/models/meal_entry.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Single-row meal entry shown inside a meal-group card on the dashboard.
class MealEntryRow extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback? onDelete;

  const MealEntryRow({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.glassOverlaySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.neonSweep,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(entry.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppText.h4,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.brand != null && entry.brand!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.brand!,
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniChip(text: '${Formatters.grams(entry.gramsConsumed)}', color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    _MiniChip(text: Formatters.kcal(entry.calories), color: AppColors.macroCalories),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDelete!();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.glassDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
