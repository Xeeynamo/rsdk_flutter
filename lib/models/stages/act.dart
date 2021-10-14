import 'dart:io';

import '../reader.dart';

class ActV4 {
  static const int MaxLayerCount = 5;
  final File _file;

  String title = "";
  List<int> layers = List.empty();
  int _width = 0;
  int _height = 0;
  List<int> _layout = List.empty();

  ActV4(this._file);

  int get width => _width;
  int get height => _height;

  Future<void> load() async {
    final reader = Reader(await _file.readAsBytes());
    title = reader.readRsdkString();
    layers = reader.read(MaxLayerCount);
    _width = reader.readShort();
    _height = reader.readShort();
    _layout = List.generate(
      width * height,
      (index) => reader.readShort(),
      growable: false);
  }

  int getChunkId(int x, int y) {
    assert(x >= 0 && x < width);
    assert(y >= 0 && y < height);

    return _layout[x + y * width];
  }
}