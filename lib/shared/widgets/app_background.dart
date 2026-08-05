import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';

/// Permanent app-wide background: a deep dark gradient with two soft glow
/// blobs that lend the "premium" glassmorphism feel.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F0F12),
            Color(0xFF0A0A0E),
            Color(0xFF08080B),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Two glow blobs to give the background depth.
          const Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(
              size: 280,
              color: Color(0xFF00FF87),
              opacity: 0.10,
            ),
          ),
          const Positioned(
            top: 200,
            right: -120,
            child: _GlowBlob(
              size: 320,
              color: Color(0xFF60EFFF),
              opacity: 0.08,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowBlob({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Re-export of [AppColors] consumed by feature screens for spot-color use.
const kAccentLime = AppColors.neonLime;
const kAccentCyan = AppColors.neonCyan;
