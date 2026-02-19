import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SmoothScrollView extends StatefulWidget {
  SmoothScrollView({
    super.key,
    required this.child,
    this.controller,
    this.scrollSpeed = 1.0,
    this.damping = 0.15,
    this.minDuration = 80,
    this.maxDuration = 220,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  ScrollController? controller = ScrollController();
  final double scrollSpeed;
  final double damping;
  final int minDuration;
  final int maxDuration;
  final Curve curve;

  @override
  State<SmoothScrollView> createState() => _SmoothMouseScrollViewState();
}

class _SmoothMouseScrollViewState extends State<SmoothScrollView> with SingleTickerProviderStateMixin {
  ScrollController _controller = ScrollController();
  late final AnimationController _anim;
  ScrollPhysics _physics = const NeverScrollableScrollPhysics();

  double _target = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _anim = AnimationController(vsync: this)..addListener(_tick);
  }

  void _tick() {
    final current = _controller.offset;
    final delta = (_target - current) * widget.damping;

    if (delta.abs() < 0.3) {
      _controller.jumpTo(_target);
      _anim.stop();
    } else {
      _controller.jumpTo(current + delta);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _target += event.scrollDelta.dy * widget.scrollSpeed;

      _target = _target.clamp(0.0, _controller.position.maxScrollExtent);

      final velocity = event.scrollDelta.dy.abs();
      final duration = (widget.maxDuration - (velocity * 0.5).clamp(0, widget.maxDuration)).toInt().clamp(
        widget.minDuration,
        widget.maxDuration,
      );

      _anim
        ..duration = Duration(milliseconds: duration)
        ..forward(from: 0);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _physics = ClampingScrollPhysics();
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _physics = NeverScrollableScrollPhysics();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal,
      child: ListView(controller: _controller, physics: _physics, children: [widget.child]),
    );
  }
}
