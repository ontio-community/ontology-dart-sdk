import 'dart:typed_data';
import 'bridge.dart';

class Base58 {
  static Future<Uint8List> decode(String encoded) async {
    var res = await invokeCrypto('base58.decode', [encoded]);
    return res as Uint8List;
  }

  static Future<String> encode(Uint8List plain) async {
    var res = await invokeCrypto('base58.encode', [plain]);
    return res as String;
  }
}
