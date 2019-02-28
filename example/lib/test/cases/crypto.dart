import '../test_case.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/common.dart';

var testCases = [
  TestCase('testMnemonic', () async {
    var mnemonic =
        'doll remember harbor resource desert curious fatigue nature arrest fix nation rhythm';
    var prikey = await PrivateKey.fromMnemonic(mnemonic);
    return Convert.bytesToHexStr(prikey.raw) ==
        '49e590700c9a28f86e00aa516cb9493c39743e0a255bae6fa51b57a7238b223a';
  }),
  TestCase('testEcdsaSign', () async {
    var prikey = PrivateKey.fromHex(
        '0fdbd5d046997da9959b1931c727c96d83dff19e8ec0244952c1e72d1cdb5bf4');
    var msg = Convert.strToBytes('helloworld');
    var pubkey = await prikey.getPublicKey();
    var sig = await prikey.sign(msg);
    return await pubkey.verify(msg, sig) == true;
  }),
  TestCase('testEcdsaSignWithJavaResult', () async {
    var prikey = PrivateKey.fromHex(
        '0fdbd5d046997da9959b1931c727c96d83dff19e8ec0244952c1e72d1cdb5bf4');
    var pubkey = await prikey.getPublicKey();
    var msg = Convert.strToBytes(
        'deviceCode=device79dd02d40eb6422bb1f7924c2a6b06af&nonce=1042961893&ontId=did:ont:AVRKWDig5TorzjCS5xphjgMnmdsT7KgsGD&timestamp=1535970123');
    var sig = await Signature.fromBytes(Convert.base64ToBytes(
        'AYUi0ZgY7ZGN9Msr42prWjsghbcQ6yGaRL34RSUwQr949JMXuhrbjWCYIO3UV1FbFbNKG0YZByYHkffu800pNMw='));
    return await pubkey.verify(msg, sig) == true;
  }),
  TestCase('testSm2Sign', () async {
    var prikey = PrivateKey.fromHex(
        '0fdbd5d046997da9959b1931c727c96d83dff19e8ec0244952c1e72d1cdb5bf4',
        algorithm: KeyType.sm2,
        parameters: KeyParameters.fromCurve(Curve.sm2p256v1));
    var pubkey = await prikey.getPublicKey();
    var msg = Convert.strToBytes('helloworld');
    var sig = await prikey.sign(msg, schema: SignatureSchema.sm2Sm3);
    return await pubkey.verify(msg, sig) == true;
  }),
  TestCase('testSm2VerifyTsSig', () async {
    var prikey = PrivateKey.fromHex(
        'ab80a7ad086249c01e65c4d9bb6ce18de259dcfc218cd49f2455c539e9112ca3',
        algorithm: KeyType.sm2,
        parameters: KeyParameters.fromCurve(Curve.sm2p256v1));
    var pubkey = await prikey.getPublicKey();
    var msg = Convert.strToBytes('test');
    var sig = Signature.fromBytes(Convert.hexStrToBytes(
        '09313233343536373831323334353637380061f57a6006df7e8d503dcf8b3261c1309222a44f6b7a6a3184f0fd37e75879d234f38f4e47efd81d616d3ee60440be63d46e1bd75259c2042faf56f415fb7776'));
    return await pubkey.verify(msg, sig) == true;
  }),
  TestCase('testEddsaKeypair', () async {
    var prikey = PrivateKey.fromHex(
        '176fbdfa6eb71f06d849fdfb9b7a4b879b19d49fa963bb58ce327c417666f5a5',
        algorithm: KeyType.eddsa,
        parameters: KeyParameters.fromCurve(Curve.ed25519));
    var pubkey = await prikey.getPublicKey();
    return Convert.bytesToHexStr(pubkey.raw) ==
        'e22ec1de59aefda80beb0b6397e55f4db7e0a0c4fede5cf40b1dcf9613a4d800';
  }),
  TestCase('testEddsaSign', () async {
    var prikey = PrivateKey.fromHex(
        '176fbdfa6eb71f06d849fdfb9b7a4b879b19d49fa963bb58ce327c417666f5a5',
        algorithm: KeyType.eddsa,
        parameters: KeyParameters.fromCurve(Curve.ed25519));
    var pubkey = await prikey.getPublicKey();
    var msg = Convert.strToBytes('helloworld');
    var sig = await prikey.sign(msg);
    return await pubkey.verify(msg, sig) == true;
  }),
  TestCase('testScryptEnc', () async {
    var prikey = PrivateKey.fromHex(
        '6717c0df45159d5b5ef383521e5d8ed8857a02cdbbfdefeeeb624f9418b0895e');
    var salt = Convert.base64ToBytes('sJwpxe1zDsBt9hI2iA2zKQ==');
    var addr = await Address.fromBase58('AakBoSAJapitE4sMPmW7bs8tfT4YqPeZEU');
    var pwd = Convert.strToBytes('11111111');
    var enc = await prikey.encrypt(pwd, addr, salt);
    return Convert.bytesToBase64(enc.raw) ==
        'dRiHlKa16kKGuWEYWhXUxvHcPlLiJcorAN3ocZ9fQ5HBHBwf47A+MYoMg1nV6UuP';
  }),
  TestCase('testScryptDec', () async {
    var enc = await PrivateKey(Convert.base64ToBytes(
        'dRiHlKa16kKGuWEYWhXUxvHcPlLiJcorAN3ocZ9fQ5HBHBwf47A+MYoMg1nV6UuP'));
    var salt = Convert.base64ToBytes('sJwpxe1zDsBt9hI2iA2zKQ==');
    var addr = await Address.fromBase58('AakBoSAJapitE4sMPmW7bs8tfT4YqPeZEU');
    var pwd = Convert.strToBytes('11111111');
    var dec = await enc.decrypt(pwd, addr, salt);
    return Convert.bytesToHexStr(dec.raw) ==
        '6717c0df45159d5b5ef383521e5d8ed8857a02cdbbfdefeeeb624f9418b0895e';
  }),
  TestCase('testToWif', () async {
    var prikey = PrivateKey.fromHex(
        'e467a2a9c9f56b012c71cf2270df42843a9d7ff181934068b4a62bcdd570e8be');
    return await prikey.getWif() ==
        'L4shZ7B4NFQw2eqKncuUViJdFRq6uk1QUb6HjiuedxN4Q2CaRQKW';
  }),
  TestCase('testFromWif', () async {
    var prikey = await PrivateKey.fromWif(
        'L4shZ7B4NFQw2eqKncuUViJdFRq6uk1QUb6HjiuedxN4Q2CaRQKW');
    return Convert.bytesToHexStr(prikey.raw) ==
        'e467a2a9c9f56b012c71cf2270df42843a9d7ff181934068b4a62bcdd570e8be';
  }),
  TestCase('testJavaGeneratedKey', () async {
    var prikey = PrivateKey.fromHex(
        '176fbdfa6eb71f06d849fdfb9b7a4b879b19d49fa963bb58ce327c417666f5a5');
    var pubkey = await prikey.getPublicKey();
    var addr = await Address.fromPubkey(pubkey);
    var enc = await prikey.encrypt(Convert.strToBytes('123456'), addr,
        Convert.base64ToBytes('4vD1aBdikit9C1FNm0zE5Q=='),
        params: ScryptParams());
    return Convert.bytesToBase64(enc.raw) ==
        'YRUp1haBykuJvbNCPiTaAU3HunubC47n7bZXveUsAlcNkjo6KF31g+arGq2t2C0t';
  }),
];
