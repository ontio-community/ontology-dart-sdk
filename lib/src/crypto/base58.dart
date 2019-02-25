import 'dart:typed_data';
import 'method_channel.dart';

class Base58 {
  static Future<dynamic> decode(String encoded) async {
    return invokeCrypto('base58.decode', [encoded]);
  }

  static Future<dynamic> encode(Uint8List plain) async {
    return invokeCrypto('base58.encode', [plain]);
  }
}
