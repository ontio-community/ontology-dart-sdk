import 'dart:typed_data';
import 'package:convert/convert.dart';
import '../common/convert.dart';
import '../constant.dart';
import 'base58.dart';
import 'hash.dart';

class Address {
  Uint8List value;

  Address(Uint8List value) : value = value;

  String serialize() {
    return hex.encode(value);
  }

  Future<String> toBase58() async {
    return encodeToBase58(value);
  }

  String toHex() {
    return hex.encode(value.reversed);
  }

  static Future<Uint8List> decode(String b58) async {
    Uint8List data = await Base58.decode(b58);
    Uint8List val = data.sublist(1, 20);
    String act = await encodeToBase58(val);
    if (act != b58) {
      throw ArgumentError('Deformed base58 address');
    }
    return val;
  }

  static Future<String> encodeToBase58(Uint8List data) async {
    Uint8List buf = Uint8List(0);
    buf.add(Constant.addrVersion);
    buf.addAll(data);
    Uint8List hash = await Hash.sha256sha256(buf);
    Uint8List chksum = hash.sublist(0, 3);
    buf.addAll(chksum);
    return Base58.encode(buf);
  }

  static Future<Address> fromBase58(String b58) async {
    Uint8List val = await Base58.decode(b58);
    return Address(val);
  }

  static Future<Address> fromValue(String value) async {
    if (value.length == 40) {
      return Address(Convert.hexStrToBytes(value));
    } else if (value.length == 34) {
      return fromBase58(value);
    } else {
      throw ArgumentError('Deformed address value');
    }
  }
}
