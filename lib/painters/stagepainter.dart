import 'dart:ui';
import 'package:flutter/widgets.dart' as widgets;
import 'package:rsdk_flutter/models/stages/stage.dart';

class StagePainter extends widgets.CustomPainter {
  static const chunkSize = 128.0;
  final Stage _stage;
  final Offset offset;

  StagePainter(this._stage, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final imagePaint = Paint();
    final sizeHeight = (size.height + chunkSize * 2 - 1) ~/ chunkSize;
    final sizeWidth = (size.width + chunkSize * 2 - 1) ~/ chunkSize;
    final yMod = offset.dy ~/ chunkSize;
    final xMod = offset.dx ~/ chunkSize;
    final yOff = offset.dy.remainder(chunkSize);
    final xOff = offset.dx.remainder(chunkSize);
    for (var y = 0; y < sizeHeight && (yMod + y) < _stage.act.height; y++) {
      if (yMod + y < 0) continue;
      for (var x = 0; x < sizeWidth && (xMod + x) < _stage.act.width; x++) {
        if (xMod + x < 0) continue;
        final chunkId = _stage.act.getChunkId(xMod + x, yMod + y);
        canvas.drawImage(_stage.chunksImage[chunkId],
            Offset(x * chunkSize - xOff, y * chunkSize - yOff), imagePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant widgets.CustomPainter oldDelegate) => true;
}
