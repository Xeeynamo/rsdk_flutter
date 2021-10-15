import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rsdk_flutter/painters/stagepainter.dart';
import 'models/stages/stage.dart';

class LevelView extends StatefulWidget {
  final Stage stage;

  const LevelView({Key? key, required this.stage}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => _LevelViewState(stage);
}

class _LevelViewState extends State<LevelView>
    with SingleTickerProviderStateMixin {
  final Stage stage;

  late final AnimationController _controller;
  late Animation<Offset> _animation;
  Size _viewportSize = Size.zero;
  Offset _offset = Offset.zero;

  Offset get offset => _offset;
  set offset(Offset offset) {
    setState(() {
      _offset = offset;
    });
  }

  _LevelViewState(this.stage);

  @override
  initState() {
    _controller = AnimationController(vsync: this);
    _offset = Offset.zero;

    _controller.addListener(() {
      offset = _animation.value;
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _builder);

  Widget _builder(BuildContext context, BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    _viewportSize = size;
    return Stack(fit: StackFit.expand, children: <Widget>[
      Draggable(
        child: _paintStageForeground(context),
        feedback: const SizedBox.shrink(),
        onDragUpdate: (details) => offset -= details.delta,
        onDragEnd: (details) =>
            _runDropAnimation(details.velocity.pixelsPerSecond, size),
      )
    ]);
  }

  Widget _paintStageForeground(BuildContext context) =>
      CustomPaint(painter: StagePainter(stage, _offset));

  /// Calculates and runs a [SpringSimulation].
  _runDropAnimation(Offset pixelsPerSecond, Size size) {
    final maxCamX = stage.act.width * 128 - _viewportSize.width;
    final maxCamY = stage.act.height * 128 - _viewportSize.height;
    final finalOffset = Offset(
        max(min(_offset.dx, maxCamX), 0), max(min(_offset.dy, maxCamY), 0));
    if (_offset == finalOffset) {
      return;
    }

    _animation = _controller.drive(_OffsetTween(_offset, finalOffset));

    // Calculate the velocity relative to the unit interval, [0,1],
    // used by the animation controller.
    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;

    const spring = SpringDescription(
      mass: 30,
      stiffness: 1,
      damping: 1,
    );

    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

    _controller.animateWith(simulation);
  }
}

class _OffsetTween extends Tween<Offset> {
  /// Creates a fractional offset tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as meaning the center.
  _OffsetTween(Offset begin, Offset end) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Offset lerp(double t) => Offset.lerp(begin, end, t)!;
}
