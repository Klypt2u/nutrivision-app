import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Primary gradient pill button used for action CTAs across the app.
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final LinearGradient? gradient;
  final Color? tint;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool haptic;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.gradient,
    this.tint,
    this.radius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.haptic = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 0.06,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 - _press.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!disabled && widget.haptic) HapticFeedback.lightImpact();
          _press.forward();
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: disabled ? null : widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: widget.loading ? 0.7 : 1,
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppColors.neonSweep,
              color: widget.tint,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: disabled
                  ? const []
                  : [
                      BoxShadow(
                        color: (widget.gradient?.colors.first ?? AppColors.neonLime)
                            .withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null && !widget.loading) ...[
                  Icon(widget.icon, color: AppColors.textOnAccent, size: 18),
                  const SizedBox(width: 8),
                ],
                if (widget.loading)
                  const CupertinoActivityIndicator(color: AppColors.textOnAccent)
                else
                  Text(
                    widget.label,
                    style: AppText.button.copyWith(color: AppColors.textOnAccent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
