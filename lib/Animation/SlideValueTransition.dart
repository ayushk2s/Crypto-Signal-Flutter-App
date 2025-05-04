import 'package:flutter/material.dart';

class SlideValueTransition extends StatefulWidget{
  final Widget child;
  double dxb, dyb, dxe, dye;
   SlideValueTransition({required this.child, Key? key, required this.dxb,
    required this.dyb, required this.dxe, required this.dye})
      : super(key: key);
  @override
  State<SlideValueTransition> createState() => _SlideValueTransitionState();
}

class _SlideValueTransitionState extends State<SlideValueTransition> with
    TickerProviderStateMixin{
  late AnimationController controller;
  late Animation<Offset> positionChange;
  late Animation<double> scaleTransition;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds: 2));
    positionChange = Tween<Offset>(begin: Offset(widget.dxb, widget.dyb),
        end: Offset(widget.dxe, widget.dye))
        .animate(
      CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOutBack
      ),
    );
    scaleTransition = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: controller,
            curve: Curves.easeInOutBack)
    );
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose the controller first
    super.dispose(); // Then call super.dispose()
  }


  @override
  Widget build(BuildContext context){
    return SlideTransition(
      position: positionChange,
      child: ScaleTransition(
        scale: scaleTransition,
        child: widget.child,
      ),
    );
  }
}