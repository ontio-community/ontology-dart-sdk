import 'dart:typed_data';
import '../common/buffer.dart';
import '../constant.dart';
import '../common/convert.dart';
import 'package:collection/collection.dart';

class SignatureSchema {
  static SignatureSchema ecdsaSha224 =
      SignatureSchema._internal('SHA224withECDSA', 0);
  static SignatureSchema ecdsaSha256 =
      SignatureSchema._internal('SHA256withECDSA', 1);
  static SignatureSchema ecdsaSha384 =
      SignatureSchema._internal('SHA384withECDSA', 2);
  static SignatureSchema ecdsaSha512 =
      SignatureSchema._internal('SHA512withECDSA', 3);
  static SignatureSchema ecdsaSha3_224 =
      SignatureSchema._internal('SHA3-224withECDSA', 4);
  static SignatureSchema ecdsaSha3_256 =
      SignatureSchema._internal('SHA3-256withECDSA', 5);
  static SignatureSchema ecdsaSha3_384 =
      SignatureSchema._internal('SHA3-384withECDSA', 6);
  static SignatureSchema ecdsaSha3_512 =
      SignatureSchema._internal('SHA3-512withECDSA', 7);
  static SignatureSchema ecdsaRipemd160 =
      SignatureSchema._internal('RIPEMD160withECDSA', 8);
  static SignatureSchema sm2Sm3 = SignatureSchema._internal('SM3withSM2', 9);
  static SignatureSchema eddsaSha512 =
      SignatureSchema._internal('SHA512withEdDSA', 10);

  String label;
  int value;

  SignatureSchema._internal(String label, int value)
      : label = label,
        value = value;

  factory SignatureSchema.fromLabel(String label) {
    switch (label) {
      case 'SHA224withECDSA':
        return ecdsaSha224;
      case 'SHA256withECDSA':
        return ecdsaSha256;
      case 'SHA384withECDSA':
        return ecdsaSha384;
      case 'SHA512withECDSA':
        return ecdsaSha512;
      case 'SHA3-224withECDSA':
        return ecdsaSha3_224;
      case 'SHA3-256withECDSA':
        return ecdsaSha3_256;
      case 'SHA3-384withECDSA':
        return ecdsaSha3_384;
      case 'SHA3-512withECDSA':
        return ecdsaSha3_512;
      case 'RIPEMD160withECDSA':
        return ecdsaRipemd160;
      case 'SM3withSM2':
        return sm2Sm3;
      case 'SHA512withEdDSA':
        return eddsaSha512;
      default:
        throw ArgumentError('Invalid label');
    }
  }

  factory SignatureSchema.fromValue(int value) {
    switch (value) {
      case 0:
        return ecdsaSha224;
      case 1:
        return ecdsaSha256;
      case 2:
        return ecdsaSha384;
      case 3:
        return ecdsaSha512;
      case 4:
        return ecdsaSha3_224;
      case 5:
        return ecdsaSha3_256;
      case 6:
        return ecdsaSha3_384;
      case 7:
        return ecdsaSha3_512;
      case 8:
        return ecdsaRipemd160;
      case 9:
        return sm2Sm3;
      case 10:
        return eddsaSha512;
      default:
        throw ArgumentError('Invalid label');
    }
  }
}

class Signature {
  Uint8List r;
  Uint8List s;
  SignatureSchema algorithm;

  Signature(Uint8List r, Uint8List s, String sigSchemaLabel)
      : r = r,
        s = s,
        algorithm = SignatureSchema.fromLabel(sigSchemaLabel);

  Signature.fromBytes(Uint8List bytes) {
    algorithm = SignatureSchema.fromValue(bytes[0]);
    var rs = bytes.sublist(1);
    if (algorithm == SignatureSchema.sm2Sm3) {
      var idx = rs.indexWhere((b) => b == 0);
      if (idx == -1) throw ArgumentError('Missing sm2 id');
      if (!ListEquality().equals(rs.sublist(0, idx), Constant.defaultSm2Id))
        throw ArgumentError('Deformed sm2 id');
      rs = rs.sublist(idx + 1);
    }
    r = rs.sublist(0, 32);
    s = rs.sublist(32);
  }

  Signature.fromHexStr(String hex) : this.fromBytes(Convert.hexStrToBytes(hex));

  Uint8List get bytes {
    var buf = Buffer();
    buf.addUint8(algorithm.value);
    if (algorithm == SignatureSchema.sm2Sm3) {
      buf.appendBytes(Constant.defaultSm2Id);
      buf.addUint8(0);
    }
    buf.appendBytes(r);
    buf.appendBytes(s);
    return buf.bytes;
  }

  String get hexEncoded {
    return Convert.bytesToHexStr(bytes);
  }
}
