import 'package:flutter/material.dart';
import 'package:rsdk_flutter/painters/stagepainter.dart';
import 'models/stages/stage.dart';

class LevelView extends StatelessWidget {
  final Stage stage;

  const LevelView({Key? key, required this.stage}) : super(key: key);

  int get stageWidth => stage.act.width;
  int get stageHeight => stage.act.height;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SizedBox(
          width: stageWidth * Stage.chunkSize / 1,
          height: stageHeight * Stage.chunkSize / 1,
          child: _paintStageForeground(context),
        ),
        scrollDirection: Axis.horizontal);
  }

  Widget _paintStageForeground(BuildContext context) {
    return CustomPaint(
      painter: StagePainter(stage),
    );
  }
}
