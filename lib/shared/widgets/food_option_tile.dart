import 'package:flutter/cupertino.dart';

import '../../core/models/food_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Generic tile for foods: emoji badge + name/brand + macro chips + kcal.
/// Re-used in search results, scanner results, and the manual-log picker.
class FoodOptionTile extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final String? trailing;

  const FoodOptionTile({super.key, required this.food, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.glassOverlaySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            _FoodBadge(emoji: food.emoji),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: AppText.h4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.glassDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          food.source.badge,
                          style: AppText.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((food.subtitle ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        food.subtitle!,
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Chip(text: Formatters.kcal(food.caloriesPer100g.roundToDouble()), tint: AppColors.macroCalories),
                      const SizedBox(width: 6),
                      _Chip(text: 'P ${food.proteinPer100g.toStringAsFixed(1)}g', tint: AppColors.macroProtein),
                      const SizedBox(width: 6),
                      _Chip(text: 'C ${food.carbsPer100g.toStringAsFixed(1)}g', tint: AppColors.macroCarbs),
                      const SizedBox(width: 6),
                      _Chip(text: 'F ${food.fatPer100g.toStringAsFixed(1)}g', tint: AppColors.macroFat),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null)
              Text(
                trailing!,
                style: AppText.bodySmall.copyWith(color: AppColors.neonLime),
              )
            else
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.textTertiary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodBadge extends StatelessWidget {
  final String emoji;
  const _FoodBadge({required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.macroSweep,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonLime.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color tint;
  const _Chip({required this.text, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: tint,
          fontSize: 10,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
