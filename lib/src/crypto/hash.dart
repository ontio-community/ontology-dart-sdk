import 'dart:typed_data';
import 'bridge.dart';
import 'dart:convert';
import 'signature.dart';

class Hash {
  static Future<Uint8List> computeBytes(
      Uint8List bytes, String sigSchemaLabel) async {
    var res = await invokeCrypto('hash.compute', [bytes, sigSchemaLabel]);
    return res as Uint8List;
  }

  static Future<Uint8List> computeMsg(String msg, String sigSchemaLabel) async {
    var bytes = Uint8List.fromList(Utf8Encoder().convert(msg));
    return computeBytes(bytes, sigSchemaLabel);
  }

  static Future<Uint8List> sha256(Uint8List data) async {
    return computeBytes(data, SignatureSchema.ecdsaSha256.label);
  }

  static Future<Uint8List> sha256sha256(Uint8List data) async {
    return sha256(await sha256(data));
  }

  static Future<Uint8List> sha256ripemd160(Uint8List data) async {
    var res = await invokeCrypto('hash.sha256ripemd160', [data]);
    return res as Uint8List;
  }
}
