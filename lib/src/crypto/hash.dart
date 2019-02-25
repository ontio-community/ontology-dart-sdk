import 'dart:typed_data';
import 'method_channel.dart';
import 'dart:convert';
import 'signature_schema.dart';

class Hash {
  static Future<dynamic> computeBytes(
      Uint8List bytes, String sigSchemaLabel) async {
    return invokeCrypto('hash.compute', [bytes, sigSchemaLabel]);
  }

  static Future<dynamic> computeMsg(String msg, String sigSchemaLabel) async {
    Uint8List bytes = Uint8List.fromList(Utf8Encoder().convert(msg));
    return computeBytes(bytes, sigSchemaLabel);
  }

  static Future<dynamic> sha256(Uint8List data) async {
    return computeBytes(data, SignatureSchema.ecdsaSha256.label);
  }

  static Future<dynamic> sha256sha256(Uint8List data) async {
    return sha256(await sha256(data));
  }
}
