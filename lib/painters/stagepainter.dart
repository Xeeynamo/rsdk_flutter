import 'dart:ui';
import 'package:flutter/widgets.dart' as widgets;
import 'package:rsdk_flutter/models/stages/stage.dart';

class StagePainter extends widgets.CustomPainter {
  static const chunkSize = 128.0;
  final Stage _stage;

  StagePainter(this._stage);

  @override
  void paint(Canvas canvas, Size size) {
    final imagePaint = Paint();
    for (var y = 0; y < size.height && y < _stage.act.height; y++) {
      for (var x = 0; x < size.width && x < _stage.act.width; x++) {
        final chunkId = _stage.act.getChunkId(x, y);
        canvas.drawImage(_stage.chunksImage[chunkId], Offset(x * chunkSize, y * chunkSize), imagePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant widgets.CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return false;
  }

} 