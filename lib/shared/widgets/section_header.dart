import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Overline-style header used between dashboard sections (`TODAY'S MEALS`,
/// `WATER`, etc.). Optional trailing widget (typically a link/button).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppText.overline.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          if (trailingLabel != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: onTrailingTap,
              child: Row(
                children: [
                  Text(
                    trailingLabel!,
                    style: AppText.label.copyWith(color: AppColors.neonLime),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.neonLime,
                    size: 12,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
