import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import './src/crypto/key.dart';
import './src/crypto/scrypt.dart';
import 'dart:convert';
import './src/crypto/base58.dart';

class OntologyDartSdk {
  static const MethodChannel _channel =
      const MethodChannel('ontology_dart_sdk');

  static Future<String> get platformVersion async {
    Uint8List raw = Uint8List(1);
    Key key = Key(raw: raw);
    print(key.raw);
    print(key.parameters.toJson());
    Uint8List password = Uint8List.fromList(Utf8Encoder().convert("test"));
    Uint8List salt = Base64Decoder().convert("sJwpxe1zDsBt9hI2iA2zKQ==");
    final Uint8List res =await Scrypt.encrypt(password: password,salt: salt);
    print(res);
    print(await Base58.encode(Uint8List.fromList(Utf8Encoder().convert("test"))));
    return "11";
  }
}
