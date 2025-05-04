import 'package:flutter/material.dart';

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  SlideAnimation({required this.child, required this.delay});

  @override
  _SlideAnimationState createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    final curve = CurvedAnimation(
      curve: Curves.easeOut,
      parent: _animationController,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}
