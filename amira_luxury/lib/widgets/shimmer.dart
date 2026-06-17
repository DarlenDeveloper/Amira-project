import 'package:flutter/material.dart';

/// Wraps [child] in a soft left-to-right shimmer sweep. Use it around a layout
/// of plain [SkeletonBox]es to build a loading placeholder. A single controller
/// drives the whole subtree, so wrap the group, not each box.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // Warm neutrals that fit the off-white background.
  static const Color _base = Color(0xFFE6E6E0);
  static const Color _highlight = Color(0xFFF4F4EF);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0 → 1
        final dx = (t * 2 - 1) * 1.5; // sweep from -1.5 → 1.5
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + dx, 0),
              end: Alignment(1 + dx, 0),
              colors: const [_base, _highlight, _base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A neutral rounded block used as a shimmer placeholder. Colour is supplied by
/// the [Shimmer] shader, so any opaque fill works.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E0),
        borderRadius: borderRadius,
      ),
    );
  }
}
