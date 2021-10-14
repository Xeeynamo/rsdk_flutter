import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rsdk_flutter/painters/stagepainter.dart';
import 'models/stages/stage.dart';

class LevelView extends StatefulWidget {
  final Stage stage;

  LevelView({Key? key, required this.stage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LevelViewState(stage);
}

class _LevelViewState extends State<LevelView> {
  final Stage stage;
  Offset _offset = Offset.zero;

  _LevelViewState(this.stage);

  Offset get offset => _offset;
  set offset(Offset value) => setState(() {
        _offset = Offset(_bound(value.dx, stage.act.width),
            _bound(value.dy, stage.act.height));
      });

  @override
  initState() {
    _offset = Offset.zero;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: <Widget>[
      Draggable(
        child: _paintStageForeground(context),
        feedback: const SizedBox.shrink(),
        onDragUpdate: (details) => offset -= details.delta,
      )
    ]);
  }

  Widget _paintStageForeground(BuildContext context) =>
      CustomPaint(painter: StagePainter(stage, _offset));

  double _bound(double value, int chunkBoundary) =>
      min(max(value, 0), chunkBoundary * 128);
}
