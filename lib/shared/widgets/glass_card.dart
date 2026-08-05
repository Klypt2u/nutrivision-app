import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glassmorphism.dart';

/// Canonical glassmorphism surface used by every primary card.
///
/// Composition:
/// 1. Translucent base color (background-attached feel).
/// 2. Subtle border with a thin inner highlight lip.
/// 3. Soft outer shadow.
/// 4. Optional radial gradient "glow" for hero cards.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final bool glow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(20),
    this.tint,
    this.border,
    this.shadow,
    this.gradient,
    this.glow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: tint ?? AppColors.glassOverlay,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: AppColors.borderSubtle, width: 1),
      boxShadow: shadow ?? GlassDecoration.cardShadow,
    );

    final body = Container(
      decoration: decoration,
      padding: padding,
      // Subtle inner highlight at top, suggesting a glass lip.
      foregroundDecoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Top highlight 1px gradient.
          Positioned.fill(
            top: 0, left: 0, right: 0, height: 24,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                  gradient: GlassDecoration.topLipGradient,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}
