import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Animated circular progress ring used by the dashboard's macro tiles.
///
/// Renders a conic sweep via [CustomPaint] with a glowing neon stroke. The
/// [progress] is clamped to 0..1 (over-100% is shown as full).
class MacroRing extends StatefulWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? trackColor;
  final Widget? center;
  final String? centerText;
  final String? centerLabel;
  final String? suffixText;
  final bool pulse;
  final Duration duration;

  const MacroRing({
    super.key,
    required this.progress,
    this.size = 140,
    this.strokeWidth = 14,
    this.color = AppColors.neonLime,
    this.trackColor,
    this.center,
    this.centerText,
    this.centerLabel,
    this.suffixText,
    this.pulse = false,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<MacroRing> createState() => _MacroRingState();
}

class _MacroRingState extends State<MacroRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.progress.clamp(0, 1)).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(MacroRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: _anim.value, end: widget.progress.clamp(0, 1)).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.trackColor ?? widget.color.withValues(alpha: 0.12);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _anim.value,
              color: widget.color,
              trackColor: track,
              strokeWidth: widget.strokeWidth,
              pulse: widget.pulse,
            ),
            child: Center(
              child: widget.center ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.centerText != null)
                        Text(
                          widget.centerText!,
                          style: AppText.metric.copyWith(color: widget.color),
                        ),
                      if (widget.centerLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.centerLabel!,
                            style: AppText.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (widget.suffixText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.suffixText!,
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool pulse;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Outer glow under the ring.
    if (progress > 0) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, glow);
    }

    // Track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    // Progress arc
    if (progress > 0) {
      final seg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi * 2,
          colors: [color, color.withValues(alpha: 0.65), color],
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, seg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.strokeWidth != strokeWidth;
}
