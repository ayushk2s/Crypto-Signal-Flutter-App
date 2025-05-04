import 'package:flutter/material.dart';

class TransitionAnimationFromTap extends PageRouteBuilder{
  final Widget route;
  final Offset tapPosition;

  TransitionAnimationFromTap({required this.route, required this.tapPosition})
      : super(
    transitionDuration: Duration(seconds: 1),
    pageBuilder: (context, animation, secondaryAnimation) => route,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
      );

      return ScaleTransition(
        scale: scaleAnimation,
        alignment: Alignment(
          (tapPosition.dx / MediaQuery.of(context).size.width) * 2 - 1,
          (tapPosition.dy / MediaQuery.of(context).size.height) * 2 - 1,
        ),
        child: child,
      );
    },
  );
}
