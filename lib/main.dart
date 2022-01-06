import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const DraggableCard(
        child: FlutterLogo(
          size: 128,
        ),
      ),
    );
  }
}

class DraggableCard extends StatefulWidget {
  const DraggableCard({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  _DraggableCardState createState() => _DraggableCardState();
}

/// To animate the widget, need to use [SingleTickerProviderStateMixin]
class _DraggableCardState extends State<DraggableCard> with SingleTickerProviderStateMixin {
  /// [_animationController] will be initialized from the [initState]
  late AnimationController _animationController;

  late Animation<Alignment> _animation;

  /// The alignment position of widget.
  /// This can be calculated by user gesture.
  Alignment _alignment = Alignment.center;

  @override
  void initState() {
    super.initState();

    // Create [AnimationController]
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    // Add listener to [_animationController] to update [_alignment]
    _animationController.addListener(() {
      setState(() {
        _alignment = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanDown: _handlePanDown,
      onPanEnd: _handlePanEnd,
      child: Align(
        alignment: _alignment,
        child: Card(
          child: widget.child,
        ),
      ),
    );
  }

  /// The [DragUpdateDetails] contains [DragUpdateDetails.delta].
  /// When pan updated, update [_alignment] with [DragUpdateDetails.delta].
  /// The [Alignment] is set of ratio from alignment origin, and the default origin is center of its container.
  /// ```dart
  /// Alignment(0, 0);   // This is center of container
  /// Alignment(1, 1);   // This is bottom right of container
  /// Alignment(-1, -1); // This is top left of container
  /// ```
  /// So, it is required to change [DragUpdateDetails.delta] to ratio.
  /// That's why dividing [DragUpdateDetails.delta] with half of [Size]. (The container is fit with device screen)
  void _handlePanUpdate(DragUpdateDetails details) {
    Size size = MediaQueryData.fromWindow(window).size;

    double cx = size.width / 2;
    double cy = size.height / 2;

    setState(() {
      _alignment += Alignment(
        details.delta.dx / cx,
        details.delta.dy / cy,
      );
    });
  }

  /// Call [AnimationController.stop] on pan down to handle user action
  void _handlePanDown(DragDownDetails? details) {
    _animationController.stop();
  }

  /// Run [AnimationController] when pan end.
  /// Create [_animation] by driving [_animationController].
  /// Then reset the controller progress and run animation forward to set widget to
  /// center of the view from last alignment position.
  void _handlePanEnd(DragEndDetails? details) {
    _animation = _animationController.drive(
      AlignmentTween(
        begin: _alignment,
        end: Alignment.center,
      ),
    );

    if (details != null) {
      Size size = MediaQueryData.fromWindow(window).size;

      Offset pixelsPerSecond = details.velocity.pixelsPerSecond;
      double unitsPerSecondX = pixelsPerSecond.dx / size.width;
      double unitsPerSecondY = pixelsPerSecond.dy / size.height;
      Offset unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
      double unitVelocity = unitsPerSecond.distance;

      inspect(details);

      const spring = SpringDescription(
        mass: 30,
        stiffness: 1,
        damping: 1,
      );

      SpringSimulation simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

      _animationController.animateWith(simulation);
    } else {
      _animationController.reset();
      _animationController.forward();
    }
  }
}
