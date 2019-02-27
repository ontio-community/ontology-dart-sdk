import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import './src/crypto/key.dart';
import './src/crypto/scrypt.dart';
import 'dart:convert';
import './src/crypto/base58.dart';
import './src/common/convert.dart';
import './src/crypto/address.dart';
import './src/crypto/signature.dart';
import './src/wallet/shim.dart';

class OntologyDartSdk {
  static const MethodChannel _channel =
      const MethodChannel('ontology_dart_sdk');

  static var _byteMask = new BigInt.from(0xff);

  static Uint8List encodeBigInt(BigInt number) {
    // Not handling negative numbers. Decide how you want to do that.
    int size = (number.bitLength + 7) >> 3;
    var result = new Uint8List(size);
    for (int i = 0; i < size; i++) {
      result[size - i - 1] = (number & _byteMask).toInt();
      number = number >> 8;
    }
    return result;
  }

  static Future<String> get platformVersion async {
    // Uint8List raw = Uint8List(1);
    // Key key = Key(raw: raw);
    // print(key.raw);
    // print(key.parameters.toJson());
    // Uint8List password = Uint8List.fromList(Utf8Encoder().convert("test"));
    // Uint8List salt = Base64Decoder().convert("sJwpxe1zDsBt9hI2iA2zKQ==");
    // final Uint8List res = await Scrypt.encrypt(password: password, salt: salt);
    // print(res);
    // print(
    //     await Base58.encode(Uint8List.fromList(Utf8Encoder().convert("test"))));

    // var buffer = new Uint8List(0).buffer;
    // var bdata = new ByteData.view(buffer);
    // bdata.setFloat32(0, 3.04);
    // int huh = bdata.getInt32(0);
    // print(huh);

    // print(Convert.hexStrToBigInt(str: '1234', bigEndian: false));
    // print(Convert.bigIntToBytes(v: BigInt.from(13330), bigEndian: false));

    // var pubkey = PublicKey();
    // var raw = Convert.hexStrToBytes(
    //     '031220580679fda524f575ac48b39b9f74cb0a97993df4fac5798b04c702d07a39');
    // // pubkey.algorithm = KeyType.sm2;
    // print(await Ecdsa.pubkeyXY(raw, Curve.sm2p256v1));

    // var prikey =PrivateKey.fromHex('0fdbd5d046997da9959b1931c727c96d83dff19e8ec0244952c1e72d1cdb5bf4');
    // var sig = await prikey.sig(Convert.strToBytes("test"));
    // print(sig.bytes);

    var prikey = PrivateKey.fromHex(
        '6717c0df45159d5b5ef383521e5d8ed8857a02cdbbfdefeeeb624f9418b0895e');
    var salt = Convert.base64ToBytes('sJwpxe1zDsBt9hI2iA2zKQ==');
    var addr = await Address.fromBase58('AakBoSAJapitE4sMPmW7bs8tfT4YqPeZEU');
    var pwd = Convert.strToBytes('11111111');
    var enc = await prikey.encrypt(pwd, addr, salt);
    assert(
        Convert.bytesToBase64(enc.raw) ==
            'dRiHlKa16kKGuWEYWhXUxvHcPlLiJcorAN3ocZ9fQ5HBHBwf47A+MYoMg1nV6UuP',
        'test private key encrypt');

    prikey = PrivateKey.fromHex(
        'e467a2a9c9f56b012c71cf2270df42843a9d7ff181934068b4a62bcdd570e8be');
    assert(
        await prikey.getWif() ==
            'L4shZ7B4NFQw2eqKncuUViJdFRq6uk1QUb6HjiuedxN4Q2CaRQKW',
        'test to wif');

    prikey = await PrivateKey.fromWif(
        'L4shZ7B4NFQw2eqKncuUViJdFRq6uk1QUb6HjiuedxN4Q2CaRQKW');
    assert(
        Convert.bytesToHexStr(prikey.raw) ==
            'e467a2a9c9f56b012c71cf2270df42843a9d7ff181934068b4a62bcdd570e8be',
        'test from wif');

    prikey = PrivateKey.fromHex(
        '0fdbd5d046997da9959b1931c727c96d83dff19e8ec0244952c1e72d1cdb5bf4');
    var msg = Convert.strToBytes('helloworld');
    var pubkey = await prikey.getPublicKey();
    var sig = await prikey.sign(msg);
    assert(await pubkey.verify(msg, sig), 'test ecdsa sign');

    prikey = PrivateKey.fromHex(
        'ab80a7ad086249c01e65c4d9bb6ce18de259dcfc218cd49f2455c539e9112ca3',
        algorithm: KeyType.fromLabel('SM2'),
        parameters: KeyParameters.fromCurveLabel('sm2p256v1'));
    msg = Convert.strToBytes('helloworld');
    sig = await prikey.sign(msg, schema: SignatureSchema.sm2Sm3);
    pubkey = await prikey.getPublicKey();
    assert(await pubkey.verify(msg, sig), 'test sm2 sign');

    prikey = await PrivateKey.fromMnemonic(
        'doll remember harbor resource desert curious fatigue nature arrest fix nation rhythm');
    assert(
        Convert.bytesToHexStr(prikey.raw) ==
            '49e590700c9a28f86e00aa516cb9493c39743e0a255bae6fa51b57a7238b223a',
        'mnemonic test');

    var acc = await Account.create('1234');
    print(jsonEncode(acc));

    return "11";
  }
}
