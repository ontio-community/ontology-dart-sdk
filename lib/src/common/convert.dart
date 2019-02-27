import 'dart:typed_data';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'buffer.dart';

// references https://github.com/PointyCastle/pointycastle/blob/master/lib/src/utils.dart
BigInt _decodeBigInt(List<int> bytes) {
  BigInt result = new BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += new BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

var _byteMask = new BigInt.from(0xff);

/// Encode a BigInt into bytes using big-endian encoding.
Uint8List _encodeBigInt(BigInt number) {
  // Not handling negative numbers. Decide how you want to do that.
  int size = (number.bitLength + 7) >> 3;
  var result = new Uint8List(size);
  for (int i = 0; i < size; i++) {
    result[size - i - 1] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  return result;
}

var int8Max = 127;
var int8Min = -128;

var int16Max = 32767;
var int16Min = -32768;

var int32Max = 2147483647;
var int32Min = -2147483648;

var int64Max = 9223372036854775807;
var int64Min = -9223372036854775808;

class Convert {
  static Uint8List hexStrToBytes(String str) {
    return Uint8List.fromList(hex.decode(str));
  }

  static String bytesToHexStr(Uint8List bytes) {
    return hex.encode(bytes.toList());
  }

  static BigInt hexStrToBigInt({String str, bool bigEndian = true}) {
    var bytes = hexStrToBytes(str);
    if (!bigEndian) bytes = Uint8List.fromList(bytes.reversed.toList());
    return _decodeBigInt(bytes.toList());
  }

  static BigInt bytesToBigInt({Uint8List bytes, bool bigEndian = true}) {
    if (!bigEndian) bytes = Uint8List.fromList(bytes.reversed.toList());
    return BigInt.parse(bytesToHexStr(bytes), radix: 16);
  }

  static Uint8List bigIntToBytes({BigInt v, bool bigEndian = true}) {
    Buffer buf = Buffer();
    if (v >= BigInt.from(int8Min) && v <= BigInt.from(int8Max)) {
      buf.addInt8(v.toInt());
      return buf.bytes;
    }
    if (v >= BigInt.from(int16Min) && v <= BigInt.from(int16Max)) {
      buf.addInt16(v: v.toInt(), bigEndian: bigEndian);
      return buf.bytes;
    }
    if (v >= BigInt.from(int32Min) && v <= BigInt.from(int32Max)) {
      buf.addInt32(v: v.toInt(), bigEndian: bigEndian);
      return buf.bytes;
    }
    if (v >= BigInt.from(int64Min) && v <= BigInt.from(int64Max)) {
      buf.addInt64(v: v.toInt(), bigEndian: bigEndian);
      return buf.bytes;
    }

    assert(
        v >= BigInt.from(0),
        'BigInt whose size is larger then int64 must be a positive number: ' +
            v.toRadixString(10));

    var bytes = _encodeBigInt(v);
    return bigEndian ? bytes : Uint16List.fromList(bytes.reversed.toList());
  }

  static Uint8List base64ToBytes(String b64) {
    return Base64Codec().decode(b64);
  }

  static String bytesToBase64(Uint8List bytes) {
    return Base64Encoder().convert(bytes.toList());
  }

  static Uint8List strToBytes(String str) {
    return Uint8List.fromList(Utf8Encoder().convert(str));
  }

  static String bytesToStr(Uint8List bytes) {
    return Utf8Decoder().convert(bytes.toList());
  }
}
