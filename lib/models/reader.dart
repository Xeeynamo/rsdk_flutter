import 'dart:typed_data';

class Reader {
  final Uint8List data;
  int offset = 0;

  int get length => data.length;

  Reader(this.data);

  List<int> read(int length) {
    offset += length;
    return data.getRange(offset - length, offset).toList();
  }

  int readByte() => data[offset++];
  int readShort() {
    offset += 2;
    return data[offset - 2] | (data[offset - 1] << 8);
  }
  int readShortReverse() {
    offset += 2;
    return data[offset - 1] | (data[offset - 2] << 8);
  }
  int readIntReverse() {
    offset += 4;
    return data[offset - 1] |
        (data[offset - 2] << 8) |
        (data[offset - 3] << 16) |
        (data[offset - 4] << 24);
  }

  String readRsdkString() =>
      String.fromCharCodes(read(readByte()));
}
