import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path/path.dart' as path;
import 'package:rsdk_flutter/models/gameconfig.dart';
import 'package:rsdk_flutter/models/gamestage.dart';
import 'package:rsdk_flutter/models/stages/act.dart';
import 'package:rsdk_flutter/models/stages/background.dart';

class Stage {
  static const chunkSize = 128;
  static const tileSize = 16;
  static const bpp = 4;
  static const tilesPerRow = 8;
  static const tilesPerChunk = tilesPerRow * 8;
  static const tileStride = tileSize * bpp;
  static const lineStride = tileStride * tilesPerRow;
  static const bitMaskFlipX = 0x400;
  static const bitMaskFlipY = 0x800;
  static const bitMaskZ = 0x1000;

  final String dataPath;
  final GameConfigV4 config;
  final GameStage stage;

  late final _drawTile = [
    _paintTile,
    _paintTileFlipX,
    _paintTileFlipY,
    _paintTileFlipXY
  ];
  late final String stagePath;
  late final File configFile;
  late final File actFile;
  late final File gfxFile;
  late final File tileFile;
  late final File bgFile;
  late final File collisionFile;

  List<Image> chunksImage = List.empty();
  late final ActV4 act;
  late final BackgroundV4 background;

  Stage(this.dataPath, this.config, this.stage) {
    stagePath = path.join(dataPath, "Stages/", stage.path);
    configFile = File(path.join(stagePath, "StageConfig.bin"));
    actFile = File(path.join(stagePath, "Act" + stage.act + ".bin"));
    gfxFile = File(path.join(stagePath, "16x16Tiles.gif"));
    tileFile = File(path.join(stagePath, "128x128Tiles.bin"));
    bgFile = File(path.join(stagePath, "Backgrounds.bin"));
    collisionFile = File(path.join(stagePath, "CollisionMasks.bin"));

    act = ActV4(actFile);
    background = BackgroundV4(bgFile);
  }

  Future<void> load() => Future.wait([
        _generateChunks(),
        act.load(),
        background.load(),
      ]);

  Future<void> _generateChunks() async {
    final codec = await instantiateImageCodec(await gfxFile.readAsBytes());
    final frame = await codec.getNextFrame();
    final gfxByteData = await frame.image.toByteData();
    final gfxData = gfxByteData!.buffer.asUint8List();

    var tile128desc = await tileFile.readAsBytes();
    chunksImage = await Future.wait(List.generate(
        0x200, (index) => _createChunkImage(gfxData, tile128desc, index)));
  }

  Future<Image> _createChunkImage(
      Uint8List gfxData, Uint8List chunkDescData, int chunkId) {
    const gfxIdLength = 3;

    final imageData = List.filled(chunkSize * chunkSize * bpp, 0);
    final chunkDataIndex = chunkId * tilesPerChunk * gfxIdLength;
    for (var i = 0; i < tilesPerChunk; i++) {
      final gfxId = chunkDescData[chunkDataIndex + i * gfxIdLength + 1] |
          (chunkDescData[chunkDataIndex + i * gfxIdLength + 0] << 8);
      final gfxStartIndex = (gfxId & 0x3FF) * tileSize * tileSize * bpp;
      final chunkStartIndex =
          ((i % 8) * tileStride) + ((i >> 3) * tileSize * lineStride);
      final flipXY = (gfxId >> 10) & 3;

      _drawTile[flipXY](imageData, chunkStartIndex, gfxData, gfxStartIndex);
    }

    final imageFuture = Completer<Image>();
    decodeImageFromPixels(Uint8List.fromList(imageData), Stage.chunkSize,
        Stage.chunkSize, PixelFormat.rgba8888, imageFuture.complete);

    return imageFuture.future;
  }

  void _paintTile(
      List<int> imgData, int chunkStart, List<int> gfxData, int gfxStart) {
    // copy all the 16 pixel lines from the GFX data
    for (var y = 0; y < tileSize; y++) {
      final ySrc = y * tileSize * bpp;
      final yDst = chunkStart + y * lineStride;
      // Dart does not have a decent version of memcpy...
      for (var x = 0; x < tileSize * bpp; x += bpp) {
        imgData[yDst + x + 0] = gfxData[gfxStart + ySrc + x + 0];
        imgData[yDst + x + 1] = gfxData[gfxStart + ySrc + x + 1];
        imgData[yDst + x + 2] = gfxData[gfxStart + ySrc + x + 2];
        imgData[yDst + x + 3] = gfxData[gfxStart + ySrc + x + 3];
      }
    }
  }

  void _paintTileFlipX(
      List<int> imgData, int chunkStart, List<int> gfxData, int gfxStart) {
    const flipXMod = (tileSize - 1) * bpp;
    for (var y = 0; y < tileSize; y++) {
      final ySrc = y * tileSize * bpp;
      final yDst = chunkStart + y * lineStride;
      for (var x = 0; x < tileSize * bpp; x += bpp) {
        imgData[yDst + x + 0] = gfxData[gfxStart + ySrc + flipXMod - x + 0];
        imgData[yDst + x + 1] = gfxData[gfxStart + ySrc + flipXMod - x + 1];
        imgData[yDst + x + 2] = gfxData[gfxStart + ySrc + flipXMod - x + 2];
        imgData[yDst + x + 3] = gfxData[gfxStart + ySrc + flipXMod - x + 3];
      }
    }
  }

  void _paintTileFlipY(
      List<int> imgData, int chunkStart, List<int> gfxData, int gfxStart) {
    const flipYMod = tileSize - 1;
    for (var y = 0; y < tileSize; y++) {
      final ySrc = (flipYMod - y) * tileSize * bpp;
      final yDst = chunkStart + y * lineStride;
      for (var x = 0; x < tileSize * bpp; x += bpp) {
        imgData[yDst + x + 0] = gfxData[gfxStart + ySrc + x + 0];
        imgData[yDst + x + 1] = gfxData[gfxStart + ySrc + x + 1];
        imgData[yDst + x + 2] = gfxData[gfxStart + ySrc + x + 2];
        imgData[yDst + x + 3] = gfxData[gfxStart + ySrc + x + 3];
      }
    }
  }

  void _paintTileFlipXY(
      List<int> imgData, int chunkStart, List<int> gfxData, int gfxStart) {
    const flipXMod = (tileSize - 1) * bpp;
    const flipYMod = tileSize - 1;
    for (var y = 0; y < tileSize; y++) {
      final ySrc = (flipYMod - y) * tileSize * bpp;
      final yDst = chunkStart + y * lineStride;
      for (var x = 0; x < tileSize * bpp; x += bpp) {
        imgData[yDst + x + 0] = gfxData[gfxStart + ySrc + flipXMod - x + 0];
        imgData[yDst + x + 1] = gfxData[gfxStart + ySrc + flipXMod - x + 1];
        imgData[yDst + x + 2] = gfxData[gfxStart + ySrc + flipXMod - x + 2];
        imgData[yDst + x + 3] = gfxData[gfxStart + ySrc + flipXMod - x + 3];
      }
    }
  }
}
