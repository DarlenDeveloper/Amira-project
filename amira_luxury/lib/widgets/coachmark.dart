import 'dart:math';
import 'package:flutter/material.dart';

// ── Brand tokens (kept local so the widget is self-contained) ───────────────
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFC4A464);
const _white = Colors.white;

/// A single coachmark step: the widget to highlight (by [targetKey]) and the
/// title/body shown in the tooltip bubble.
class CoachStep {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final double radius;
  const CoachStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.radius = 18,
  });
}

/// Shows a sequence of coachmark tooltips over the current screen. Each step
/// dims the screen, cuts a soft spotlight around its target, and floats a white
/// tooltip bubble (with a tail) pointing at it. Calls [onFinish] when the user
/// finishes or skips.
class Coachmarks {
  // Ensures only one tour is on screen at a time (prevents a tour from one
  // screen rendering over another).
  static bool _active = false;

  static void show(
    BuildContext context,
    List<CoachStep> steps, {
    VoidCallback? onFinish,
  }) {
    if (steps.isEmpty || _active) return;
    _active = true;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachmarkView(
        steps: steps,
        onClose: (completed) {
          entry.remove();
          _active = false;
          // Only mark as "seen" when the user actually went through it.
          if (completed) onFinish?.call();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _CoachmarkView extends StatefulWidget {
  final List<CoachStep> steps;
  final void Function(bool completed) onClose;
  const _CoachmarkView({required this.steps, required this.onClose});

  @override
  State<_CoachmarkView> createState() => _CoachmarkViewState();
}

class _CoachmarkViewState extends State<_CoachmarkView>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _missFrames = 0;
  bool _stepReady = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _prepareStep();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // Scrolls the current target into view, then reveals the spotlight. This
  // prevents an all-dim "black" screen when the target is off-screen (e.g.
  // replaying the tour while scrolled down).
  void _prepareStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx = widget.steps[_index].targetKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
      if (!mounted) return;
      setState(() => _stepReady = true);
      _anim
        ..reset()
        ..forward();
    });
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onClose(true);
      return;
    }
    setState(() {
      _index++;
      _missFrames = 0;
      _stepReady = false;
    });
    _prepareStep();
  }

  Rect? _targetRect(CoachStep step) {
    final ctx = step.targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final media = MediaQuery.of(context);
    final screen = media.size;
    final rect = _targetRect(step);

    // If a target isn't laid out yet, retry on the next frame (don't burn
    // through the tour). Give up only after many misses.
    if (rect == null) {
      _missFrames++;
      if (_missFrames > 30) {
        // Target never resolved (e.g. empty list) — skip this step.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _next();
        });
        return const SizedBox.shrink();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }
    _missFrames = 0;

    final spotlight = rect.inflate(8);
    final placeAbove = rect.center.dy > screen.height / 2;

    const margin = 20.0;
    final maxWidth = min(330.0, screen.width - margin * 2);
    final left = (rect.center.dx - maxWidth / 2)
        .clamp(margin, screen.width - margin - maxWidth);
    final tailDx = (rect.center.dx - left).clamp(24.0, maxWidth - 24.0);
    final isLast = _index == widget.steps.length - 1;

    return FadeTransition(
      opacity: _anim,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Dim + spotlight cutout. Tapping the scrim advances.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _next,
                child: CustomPaint(
                  painter: _ScrimPainter(
                    hole: RRect.fromRectAndRadius(
                      spotlight,
                      Radius.circular(step.radius),
                    ),
                  ),
                ),
              ),
            ),

            // Tooltip bubble, anchored above or below the target.
            Positioned(
              left: left,
              top: placeAbove ? null : rect.bottom + 12,
              bottom: placeAbove ? (screen.height - rect.top + 12) : null,
              width: maxWidth,
              child: _TooltipBubble(
                title: step.title,
                body: step.body,
                tailUp: !placeAbove,
                tailDx: tailDx,
                isLast: isLast,
                onNext: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scrim with a soft spotlight hole + gold ring ─────────────────────────────
class _ScrimPainter extends CustomPainter {
  final RRect hole;
  _ScrimPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, Paint()..color = const Color(0xCC110C04));
    canvas.drawRRect(hole, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    // Subtle gold ring around the spotlight.
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _gold.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}

// ── White tooltip bubble with a directional tail ─────────────────────────────
class _TooltipBubble extends StatelessWidget {
  final String title;
  final String body;
  final bool tailUp;
  final double tailDx;
  final bool isLast;
  final VoidCallback onNext;

  const _TooltipBubble({
    required this.title,
    required this.body,
    required this.tailUp,
    required this.tailDx,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final tail = Padding(
      padding: EdgeInsets.only(left: tailDx - 9),
      child: CustomPaint(
        size: const Size(18, 9),
        painter: _TailPainter(up: tailUp),
      ),
    );

    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _dark,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _grey,
              height: 1.45,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onNext,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLast ? 'Got it' : 'Next',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tailUp ? [tail, card] : [card, tail],
    );
  }
}

class _TailPainter extends CustomPainter {
  final bool up;
  _TailPainter({required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _white;
    final path = Path();
    if (up) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.up != up;
}
