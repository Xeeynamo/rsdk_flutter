import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path/path.dart' as path;
import 'package:rsdk_flutter/models/gameconfig.dart';
import 'package:rsdk_flutter/models/gamestage.dart';
import 'package:rsdk_flutter/models/stages/act.dart';

class Stage {
  static const chunkSize = 128;

  final String dataPath;
  final GameConfigV4 config;
  final GameStage stage;

  late final String stagePath;
  late final File configFile;
  late final File actFile;
  late final File gfxFile;
  late final File tileFile;
  late final File bgFile;
  late final File collisionFile;

  List<Image> chunksImage = List.empty();
  late final ActV4 act;

  Stage(this.dataPath, this.config, this.stage) {
    stagePath = path.join(dataPath, "Stages/", stage.path);
    configFile = File(path.join(stagePath, "StageConfig.bin"));
    actFile = File(path.join(stagePath, "Act" + stage.act + ".bin"));
    gfxFile = File(path.join(stagePath, "16x16Tiles.gif"));
    tileFile = File(path.join(stagePath, "128x128Tiles.bin"));
    bgFile = File(path.join(stagePath, "Backgrounds.bin"));
    collisionFile = File(path.join(stagePath, "CollisionMasks.bin"));

    act = ActV4(actFile);
  }

  Future<void> load() {
    return Future.wait([
      _generateChunks(),
      act.load(),
    ]);
  }

  Future<void> _generateChunks() async {
    final codec = await instantiateImageCodec(await gfxFile.readAsBytes());
    final frame = await codec.getNextFrame();
    final gfxByteData = await frame.image.toByteData();
    final gfxData = gfxByteData!.buffer.asUint8List();

    var tile128desc = await tileFile.readAsBytes();
    chunksImage = await Future.wait(List.generate(0x200, (index) =>
      _createChunkImage(gfxData, tile128desc, index)));
  }

  Future<Image> _createChunkImage(Uint8List gfxData, Uint8List chunkDescData, int chunkId) {
    const bpp = 4;
    const tileSize = 16;
    const tilesPerRow = 8;
    const tilesPerChunk = tilesPerRow * 8;
    const tileStride = tileSize * bpp;
    const lineStride = tileStride * tilesPerRow;
    const gfxIdLength = 3;

    final imageData = List.filled(chunkSize * chunkSize * bpp, 0);
    final chunkDataIndex = chunkId * tilesPerChunk * gfxIdLength;
    for (var i = 0; i < tilesPerChunk; i++) {
      final gfxId = chunkDescData[chunkDataIndex + i * gfxIdLength + 1] | (chunkDescData[chunkDataIndex + i * gfxIdLength + 0] << 8);
      final gfxStartIndex = (gfxId & 0x3FF) * tileSize * tileSize * bpp;
      var chunkStartIndex = ((i % 8) * tileStride) + ((i >> 3) * tileSize * lineStride);

      // copy all the 16 pixel lines from the GFX data
      for (var y = 0; y < tileSize; y++) {
        final yIndex = chunkStartIndex + y * lineStride;
        // Dart does not have a decent version of memcpy...
        for (var x = 0; x < tileSize * bpp; x += bpp) {
          imageData[yIndex + x + 0] = gfxData[gfxStartIndex + y * tileSize * bpp + x + 0];
          imageData[yIndex + x + 1] = gfxData[gfxStartIndex + y * tileSize * bpp + x + 1];
          imageData[yIndex + x + 2] = gfxData[gfxStartIndex + y * tileSize * bpp + x + 2];
          imageData[yIndex + x + 3] = gfxData[gfxStartIndex + y * tileSize * bpp + x + 3];
        }
      }
    }

    final imageFuture = Completer<Image>();
    decodeImageFromPixels(
      Uint8List.fromList(imageData),
      Stage.chunkSize,
      Stage.chunkSize,
      PixelFormat.rgba8888,
      imageFuture.complete);

    return imageFuture.future;
  }
}