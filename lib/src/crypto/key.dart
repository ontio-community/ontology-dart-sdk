import 'dart:typed_data';
import 'package:collection/collection.dart';
import '../constant.dart';
import '../common/shim.dart';
import 'signature.dart';
import 'bridge.dart';
import 'scrypt.dart';
import 'address.dart';
import 'hash.dart';
import 'base58.dart';

class Curve {
  static Curve p224 = Curve._internal('P-224', 1);
  static Curve p256 = Curve._internal('P-256', 2);
  static Curve p384 = Curve._internal('P-384', 3);
  static Curve p521 = Curve._internal('P-521', 4);
  static Curve sm2p256v1 = Curve._internal('sm2p256v1', 20);
  static Curve ed25519 = Curve._internal('ed25519', 25);

  String label;
  int value;

  Curve._internal(String label, int value)
      : label = label,
        value = value;

  factory Curve.fromLabel(String label) {
    switch (label) {
      case 'P-224':
        return p224;
      case 'P-256':
        return p256;
      case 'P-384':
        return p384;
      case 'P-521':
        return p521;
      case 'sm2p256v1':
        return sm2p256v1;
      case 'ed25519':
        return ed25519;
      default:
        throw ArgumentError('Unsupported label');
    }
  }

  factory Curve.fromValue(int value) {
    switch (value) {
      case 1:
        return p224;
      case 2:
        return p256;
      case 3:
        return p384;
      case 4:
        return p521;
      case 20:
        return sm2p256v1;
      case 25:
        return ed25519;
      default:
        throw ArgumentError('Unsupported label');
    }
  }
}

class KeyType {
  static KeyType ecdsa =
      KeyType._internal('ECDSA', 0x12, SignatureSchema.ecdsaSha256);
  static KeyType sm2 = KeyType._internal('SM2', 0x13, SignatureSchema.sm2Sm3);
  static KeyType eddsa =
      KeyType._internal('eddsa', 0X14, SignatureSchema.eddsaSha512);

  String label;
  int value;
  SignatureSchema defaultSchema;

  KeyType._internal(String label, int value, SignatureSchema defaultSchema)
      : label = label,
        value = value,
        defaultSchema = defaultSchema;

  factory KeyType.fromLabel(String label) {
    switch (label) {
      case 'ECDSA':
        return ecdsa;
      case 'SM2':
        return sm2;
      case 'EDDSA':
        return eddsa;
      default:
        throw ArgumentError('Unsupported label');
    }
  }

  factory KeyType.fromValue(int value) {
    switch (value) {
      case 0x12:
        return ecdsa;
      case 0x13:
        return sm2;
      case 0x14:
        return eddsa;
      default:
        throw ArgumentError('Unsupported label');
    }
  }

  @override
  String toString() {
    return label;
  }
}

class KeyParameters {
  Curve curve;

  KeyParameters(Curve curve) : curve = curve;

  KeyParameters.fromCurveLabel(String curve) : curve = Curve.fromLabel(curve);
  KeyParameters.fromCurve(Curve curve) : curve = curve;

  KeyParameters.fromJson(Map<String, dynamic> json)
      : this.fromCurveLabel(json['curve']);

  Map<String, dynamic> toJson() => {'curve': curve.label};
}

class Key {
  KeyType algorithm;
  KeyParameters parameters;
  Uint8List raw;

  Key(Uint8List raw, {KeyType algorithm, KeyParameters parameters})
      : raw = raw,
        algorithm = algorithm,
        parameters = parameters {
    if (algorithm == null) {
      this.algorithm =
          KeyType.fromLabel(Constant.defaultAlgorithm['algorithm']);
    }
    if (parameters == null) {
      this.parameters = KeyParameters.fromCurveLabel(
          Constant.defaultAlgorithm['parameters']['curve']);
    }
  }
}

class Ecdsa {
  static Future<List<String>> pubkeyXY(Uint8List raw, Curve curve) async {
    var res = await invokeCrypto('ecdsa.pubkeyXY', [raw, curve.label]);
    return res as List<String>;
  }

  static Future<Uint8List> sign(
      Uint8List msg, Uint8List pri, Curve curve, int sigSchemaVal) async {
    var res =
        await invokeCrypto('ecdsa.sig', [msg, pri, curve.label, sigSchemaVal]);
    return res as Uint8List;
  }

  /// Generates pubkey bytes of the private key
  ///
  /// @param mode The compress mode of pubkey bytes, 0|1|2 represent uncompress|compress|mix
  static Future<Uint8List> pub(Uint8List pri, Curve curve, int mode) async {
    var res = await invokeCrypto('ecdsa.pub', [pri, curve.label, mode]);
    return res as Uint8List;
  }

  static Future<bool> verify(
      Uint8List msg, Signature sig, Uint8List pub, Curve curve) async {
    var res =
        await invokeCrypto('ecdsa.verify', [msg, sig.bytes, pub, curve.label]);
    return res as bool;
  }
}

class Eddsa {
  static Future<Uint8List> sign(Uint8List msg, Uint8List pri) async {
    var res = await invokeCrypto('eddsa.sig', [msg, pri]);
    return res as Uint8List;
  }

  static Future<Uint8List> pub(Uint8List pri) async {
    var res = await invokeCrypto('eddsa.pub', [pri]);
    return res as Uint8List;
  }

  static Future<bool> verify(
      Uint8List msg, Signature sig, Uint8List pub) async {
    var res = await invokeCrypto('eddsa.verify', [msg, sig.bytes, pub]);
    return res as bool;
  }
}

class PrivateKey extends Key {
  ScryptParams scrypt;

  PrivateKey(Uint8List raw,
      {KeyType algorithm, KeyParameters parameters, ScryptParams scrypt})
      : super(raw, algorithm: algorithm, parameters: parameters) {
    if (scrypt == null) this.scrypt = scrypt ?? ScryptParams.defaultParams;
  }

  PrivateKey.fromHex(String hex,
      {KeyType algorithm, KeyParameters parameters, ScryptParams scrypt})
      : this(Convert.hexStrToBytes(hex),
            algorithm: algorithm, parameters: parameters, scrypt: scrypt);

  PrivateKey.fromJson(Map<String, dynamic> json)
      : this(Convert.base64ToBytes(json['key']),
            algorithm: KeyType.fromLabel(json['algorithm']),
            parameters: KeyParameters.fromJson(json['parameters']),
            scrypt: ScryptParams.fromJson(json['scrypt']));

  Map<String, dynamic> toJson() => {
        'key': Convert.bytesToBase64(raw),
        'algorithm': algorithm.label,
        'parameters': parameters,
        'scrypt': scrypt
      };

  Future<Signature> sign(Uint8List msg, {SignatureSchema schema}) async {
    schema = schema ?? algorithm.defaultSchema;
    Uint8List sig;
    if (schema == SignatureSchema.eddsaSha512) {
      sig = await Eddsa.sign(msg, raw);
    } else {
      sig = await Ecdsa.sign(msg, raw, parameters.curve, schema.value);
    }
    return Signature.fromBytes(sig);
  }

  Future<PublicKey> getPublicKey() async {
    Uint8List pub;
    if (algorithm == KeyType.eddsa) {
      pub = await Eddsa.pub(raw);
    } else {
      pub = await Ecdsa.pub(raw, parameters.curve, 1);
    }
    return PublicKey(pub, algorithm: algorithm, parameters: parameters);
  }

  Future<PrivateKey> encrypt(Uint8List keyphrase, Address addr, Uint8List salt,
      {ScryptParams params}) async {
    var pubkey = await getPublicKey();
    var addrExpect = await addr.toBase58();
    var addrActual = await (await Address.fromPubkey(pubkey)).toBase58();
    if (addrExpect != addrActual)
      throw ArgumentError(
          'Invalid addr, except: $addrExpect  got: $addrActual ');

    var enc = await Scrypt.encryptWithGcm(
        prikey: raw,
        addr58: Convert.strToBytes(addrExpect),
        salt: salt,
        pwd: keyphrase,
        params: params);

    return PrivateKey(enc,
        algorithm: algorithm, parameters: parameters, scrypt: params);
  }

  Future<PrivateKey> decrypt(Uint8List keyphrase, Address addr, Uint8List salt,
      {ScryptParams params}) async {
    var addr58 = await addr.toBase58();
    var dec = await Scrypt.decryptWithGcm(
        encrypted: raw,
        addr58: Convert.strToBytes(addr58),
        salt: salt,
        pwd: keyphrase,
        params: params);
    var key = PrivateKey(dec,
        algorithm: algorithm, parameters: parameters, scrypt: params);

    var pub = await key.getPublicKey();
    var addrAct = await Address.fromPubkey(pub);
    var addr58Act = await addrAct.toBase58();
    if (addr58 != addr58Act) throw ArgumentError('Decrypt error');

    return key;
  }

  Future<String> getWif() async {
    var buf = Buffer();
    buf.addUint8(0x80);
    buf.appendBytes(raw);
    buf.addUint8(0x01);
    var chksum = await Hash.sha256sha256(buf.bytes);
    buf.appendBytes(chksum.sublist(0, 4));
    return Base58.encode(buf.bytes);
  }

  static Future<PrivateKey> fromWif(String wif) async {
    var data = await Base58.decode(wif);
    if (data.length != 38 || data[0] != 0x80 || data[33] != 0x01)
      throw ArgumentError('Deformed wif');

    var chksum = data.sublist(34);
    var chksum1 = (await Hash.sha256sha256(data.sublist(0, 34))).sublist(0, 4);
    if (!ListEquality().equals(chksum, chksum1))
      throw ArgumentError('Illegal wif');

    return PrivateKey(data.sublist(1, 33));
  }

  static Future<PrivateKey> fromMnemonic(String mn) async {
    var raw =
        await invokeCrypto('prikey.fromMnemonic', [mn, Constant.ontBip44Path]);
    return PrivateKey(raw);
  }

  static Future<PrivateKey> random() async {
    var buf = await Buffer.random(32);
    return PrivateKey(buf.bytes);
  }
}

class PublicKey extends Key {
  PublicKey(Uint8List raw, {KeyType algorithm, KeyParameters parameters})
      : super(raw, algorithm: algorithm, parameters: parameters);

  PublicKey.fromHex(String hex, {KeyType algorithm, KeyParameters parameters})
      : this(Convert.hexStrToBytes(hex),
            algorithm: algorithm, parameters: parameters);

  PublicKey.fromBytes(Uint8List bytes, {int len = 33}) : super(null) {
    var buf = BufferReader(Buffer.fromBytes(bytes));
    if (len == 33) {
      // ecdsa
      raw = buf.forward(33);
      algorithm = KeyType.ecdsa;
      parameters = KeyParameters.fromCurve(Curve.p256);
    } else {
      algorithm = KeyType.fromValue(buf.readUint8());
      var curve = Curve.fromValue(buf.readUint8());
      raw = buf.forward(len - 2);
      parameters = KeyParameters.fromCurve(curve);
    }
  }

  Future<bool> verify(Uint8List msg, Signature sig) async {
    if (sig.algorithm == SignatureSchema.eddsaSha512) {
      return Eddsa.verify(msg, sig, raw);
    }
    return Ecdsa.verify(msg, sig, raw, parameters.curve);
  }

  String get hexEncoded {
    var buf = Buffer();
    if (algorithm == KeyType.ecdsa) {
      buf.appendBytes(raw);
    } else {
      buf.addUint8(algorithm.value);
      buf.addUint8(parameters.curve.value);
      buf.appendBytes(raw);
    }
    return Convert.bytesToHexStr(buf.bytes);
  }
}
