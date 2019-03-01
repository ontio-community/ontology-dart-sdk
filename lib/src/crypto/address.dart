import 'dart:typed_data';
import 'package:convert/convert.dart';
import '../common/shim.dart';
import '../neocore/shim.dart';
import '../constant.dart';
import 'base58.dart';
import 'hash.dart';
import 'key.dart';

class Address {
  Uint8List value;

  Address(Uint8List value) : value = value;

  String serialize() {
    return hex.encode(value);
  }

  Future<String> toBase58() async {
    return encodeToBase58(value);
  }

  String get hexEncodedLE {
    return hex.encode(value.reversed.toList());
  }

  String get hexEncoded {
    return hex.encode(value);
  }

  Uint8List get valueLE {
    return Uint8List.fromList(value.reversed.toList());
  }

  static Future<Uint8List> decode(String b58) async {
    Uint8List data = await Base58.decode(b58);
    Uint8List val = data.sublist(1, 21);
    String act = await encodeToBase58(val);
    if (act != b58) {
      throw ArgumentError('Deformed base58 address');
    }
    return val;
  }

  static Future<String> encodeToBase58(Uint8List data) async {
    var buf = Buffer();
    buf.addUint8(Constant.addrVersion);
    buf.appendBytes(data);
    Uint8List hash = await Hash.sha256sha256(buf.bytes);
    Uint8List chksum = hash.sublist(0, 4);
    buf.appendBytes(chksum);
    return Base58.encode(buf.bytes);
  }

  static Future<Address> fromBase58(String b58) async {
    var data = await Base58.decode(b58);
    var val = data.sublist(1, 21);
    var act = await encodeToBase58(val);
    if (b58 != act) throw ArgumentError('Decode base58 error');
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

  static Future<Address> fromPubkey(PublicKey pubkey) async {
    var prog = ProgramBuilder.fromPubkey(pubkey);
    var hash = await Hash.sha256ripemd160(prog.buf.bytes);
    return Address(hash);
  }

  static Future<Address> fromVMCode(Uint8List code) async {
    var hash = await Hash.sha256ripemd160(code);
    return Address(hash);
  }

  static Future<String> generateOntId(PublicKey pubkey) async {
    var addr = await Address.fromPubkey(pubkey);
    var b58 = await addr.toBase58();
    return 'did:ont:' + b58;
  }

  static Future<Address> fromOntId(String ontid) async {
    return Address.fromBase58(ontid.substring(8));
  }
}
