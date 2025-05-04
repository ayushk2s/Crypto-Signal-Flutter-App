import 'package:flutter/material.dart';

class TransitionAnimationFirst extends PageRouteBuilder {
  final Widget route;

  TransitionAnimationFirst({required this.route})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => route,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation);

      final scaleAnimation = Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(animation);

      return SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}
