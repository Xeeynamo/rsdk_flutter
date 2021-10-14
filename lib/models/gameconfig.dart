import 'dart:io';
import 'package:rsdk_flutter/models/gamestage.dart';
import 'package:rsdk_flutter/models/gamevariable.dart';
import 'package:rsdk_flutter/models/reader.dart';

import 'gameobject.dart';

class GameConfigV4 {
  final File _file;
  String name = "";
  String description = "";
  List<int> palette = List.filled(0x120, 0);
  List<GameObject> gameObjects = List.empty();
  List<GameVariable> gameVariables = List.empty();
  List<GameObject> soundEffects = List.empty();
  List<String> players = List.empty();
  List<GameStage> stagesPresentation = List.empty();
  List<GameStage> stagesRegular = List.empty();
  List<GameStage> stagesSpecial = List.empty();
  List<GameStage> stagesBonus = List.empty();

  GameConfigV4(this._file);

  Future<void> read() async {
    final reader = Reader(await _file.readAsBytes());
    name = reader.readRsdkString();
    description = reader.readRsdkString();
    palette = reader.read(palette.length);
    gameObjects = _readGameObjects(reader);
    gameVariables = _readGameItems(reader, _readGameVariable);
    soundEffects = _readGameObjects(reader);
    players = _readGameItems(reader, (r) => r.readRsdkString());
    stagesPresentation = _readGameItems(reader, _readGameStage);
    stagesRegular = _readGameItems(reader, _readGameStage);
    stagesSpecial = _readGameItems(reader, _readGameStage);
    stagesBonus = _readGameItems(reader, _readGameStage);
  }

  List<GameObject> _readGameObjects(Reader reader) =>
      List.generate(reader.readByte(), (index) => reader.readRsdkString())
          .map((e) => GameObject(e, reader.readRsdkString()))
          .toList();

  List<E> _readGameItems<E>(
          Reader reader, E Function(Reader reader) readItem) =>
      List.generate(reader.readByte(), (index) => readItem(reader));

  GameVariable _readGameVariable(Reader reader) =>
      GameVariable(reader.readRsdkString(), reader.readIntReverse());

  GameStage _readGameStage(Reader reader) => GameStage(reader.readRsdkString(),
      reader.readRsdkString(), reader.readRsdkString(), reader.readByte());
}
