import 'package:material_ui/material_ui.dart';

/// Short arrival motion for a screen's sections: fade plus a small lift,
/// staggered by [index]. Runs once per mount and is skipped entirely when
/// the system asks for reduced motion.
class Arrive extends StatefulWidget {
  const Arrive({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Position in the stagger; each step adds 45 ms (capped at 8 steps).
  final int index;

  @override
  State<Arrive> createState() => _ArriveState();
}

class _ArriveState extends State<Arrive> with SingleTickerProviderStateMixin {
  static const _run = 420;
  late final int _delay = 45 * widget.index.clamp(0, 8);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _run + _delay),
  );
  // The stagger lives inside the curve (no timers), so tests can settle.
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delay / (_run + _delay),
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * 16),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
