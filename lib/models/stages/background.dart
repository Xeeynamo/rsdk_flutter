import 'dart:io';
import 'package:rsdk_flutter/models/reader.dart';

// https://github.com/Rubberduckycooly/RSDK-Reverse/blob/master/RSDKv4/BackgroundLayout.cs
class BackgroundV4 {
  final File _file;
  List<ScrollInfo> hLines = List.empty();
  List<ScrollInfo> vLines = List.empty();
  List<BackgroundLayerV4> layers = List.empty();

  BackgroundV4(this._file);

  Future<void> load() async {
    final reader = Reader(await _file.readAsBytes());
    final layerCount = reader.readByte();
    hLines = List.generate(reader.readByte(), (index) => ScrollInfo(reader));
    vLines = List.generate(reader.readByte(), (index) => ScrollInfo(reader));
    layers = List.generate(layerCount, (index) => BackgroundLayerV4(reader));
  }
}

// https://github.com/Rubberduckycooly/RSDK-Reverse/blob/master/RSDKv4/BackgroundLayout.cs
class ScrollInfo {
  late int relativeSpeed;
  late int constantSpeed;
  late int behaviour;

  ScrollInfo(Reader reader) {
    relativeSpeed = reader.readShort();
    constantSpeed = reader.readByte();
    behaviour = reader.readByte();
  }
}

// https://github.com/Rubberduckycooly/RSDK-Reverse/blob/master/RSDKv4/BackgroundLayout.cs
class BackgroundLayerV4 {
  late int width;
  late int height;
  late int behaviour;
  late int relativeSpeed;
  late int constantSpeed;
  late List<int> lineIndices;
  late List<int> layout;

  BackgroundLayerV4(Reader reader) {
    width = reader.readShort();
    height = reader.readShort();
    behaviour = reader.readByte();
    relativeSpeed = reader.readShort();
    constantSpeed = reader.readByte();
    lineIndices = List.filled(height * 128 + 2, 0);

    for (var lineCount = 0; reader.offset < reader.length;) {
      var ch = reader.readByte();
      if (ch == 0xFF)
      {
          ch = reader.readByte();
          if (ch != 0xFF)
          {
              var length = reader.readByte() - 1;
              for (var i = 0; i < length; i++) {
                lineIndices[lineCount++] = ch;
              }
          }
          else {
            break;
          }
      }
      else {
        lineIndices[lineCount++] = ch;
      }
    }

    layout = List.generate(width * height, (index) => reader.readShort());
  }
}