import 'dart:ui';
import 'package:flutter/widgets.dart' as widgets;
import 'package:rsdk_flutter/models/stages/background.dart';
import 'package:rsdk_flutter/models/stages/stage.dart';

class BackgroundPainter extends widgets.CustomPainter {
  static const chunkSize = 128.0;
  final Stage _stage;
  final Offset offset;

  BackgroundPainter(this._stage, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer in _stage.background.layers) {
      _paintLayer(canvas, size, layer);
    }
  }

  @override
  bool shouldRepaint(covariant widgets.CustomPainter oldDelegate) => true;

  void _paintLayer(Canvas canvas, Size size, BackgroundLayerV4 layer) {
    final imagePaint = Paint();
    final sizeHeight = (size.height + chunkSize * 2 - 1) ~/ chunkSize;
    final sizeWidth = (size.width + chunkSize * 2 - 1) ~/ chunkSize;
    for (var y = 0; y < sizeHeight && y < layer.height; y++) {
      for (var x = 0; x < sizeWidth && x < layer.width; x++) {
        final chunkId = layer.layout[x + y * layer.width];
        canvas.drawImage(_stage.chunksImage[chunkId],
            Offset(x * chunkSize, y * chunkSize), imagePaint);
      }
    }
  }
}
