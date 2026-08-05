import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';

/// Horizontal droplets + percentage bar showing today's water intake.
///
/// 8 droplet icons fill up as the user logs water. The bar underneath shows
/// fraction of goal.
class WaterIntakeBar extends StatelessWidget {
  final int currentMl;
  final double goalMl;
  final ValueChanged<int> onAdd;
  final int addStepMl;

  const WaterIntakeBar({
    super.key,
    required this.currentMl,
    required this.goalMl,
    required this.onAdd,
    this.addStepMl = 250,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (currentMl / goalMl).clamp(0.0, 1.0);
    final drops = 8;
    final filled = (pct * drops).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.drop_fill, color: AppColors.macroWater, size: 18),
            const SizedBox(width: 6),
            Text(
              'Water',
              style: AppText.label.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            Text(
              '${Formatters.ml(currentMl)} / ${Formatters.ml(goalMl)}',
              style: AppText.bodySmall.copyWith(color: AppColors.macroWater),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(drops, (i) {
            final isFilled = i < filled;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i == drops - 1 ? 0 : 6),
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: isFilled
                      ? const LinearGradient(
                          colors: [Color(0xFF6BB7FF), Color(0xFF60EFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isFilled ? null : AppColors.glassDark,
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: AppColors.macroWater.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: -2,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.drop_fill,
                    size: 16,
                    color: isFilled ? Color(0xFFFFFFFF) : AppColors.textTertiary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _WaterButton(
              icon: CupertinoIcons.minus,
              tint: AppColors.glassDark,
              iconColor: AppColors.textSecondary,
              onTap: () {
                HapticFeedback.selectionClick();
                onAdd(-addStepMl);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(height: 8, color: AppColors.glassDark),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 8,
                      width: MediaQuery.of(context).size.width * pct,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6BB7FF), Color(0xFF60EFFF)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _WaterButton(
              icon: CupertinoIcons.plus,
              tint: AppColors.macroWater,
              iconColor: Color(0xFFFFFFFF),
              onTap: () {
                HapticFeedback.selectionClick();
                onAdd(addStepMl);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _WaterButton extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;
  const _WaterButton({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: tint == AppColors.glassDark ? 1.0 : 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: tint != AppColors.glassDark
              ? [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

/// Cross-platform Color(0xFFFFFFFF) — Cupertino is otherwise too restrictive.
class Colors {
  static const white = Color(0xFFFFFFFF);
}
