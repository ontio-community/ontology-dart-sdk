import '../crypto/shim.dart';
import '../common/shim.dart';
import 'keystore.dart';

class ControlData {
  String id;
  PrivateKey encryptedKey;
  String address;
  String publicKey;
  String salt;
  String hash = "sha256";

  ControlData(
      this.id, this.encryptedKey, this.address, this.publicKey, this.salt);

  ControlData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    address = json['address'];
    salt = json['salt'];
    publicKey = json['publicKey'];

    var algo = KeyType.fromLabel(json['algorithm']);
    var params = KeyParameters.fromJson(json['parameters']);
    var key = Convert.base64ToBytes(json['key']);
    encryptedKey = PrivateKey(key, algorithm: algo, parameters: params);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'salt': salt,
        'publicKey': publicKey,
        'enc-alg': 'aes-256-gcm',
        'hash': hash,
        'algorithm': encryptedKey.algorithm.label,
        'parameters': encryptedKey.parameters,
        'key': Convert.bytesToBase64(encryptedKey.raw),
        'scrypt': encryptedKey.scrypt
      };
}

class Identity {
  String ontid;
  String label;
  bool lock;
  bool isDefault;
  List<ControlData> controls = [];
  String extra;

  Identity(this.ontid, this.label, this.lock, this.isDefault, {this.extra});

  Identity.fromJson(Map<String, dynamic> json) {
    ontid = json['ontid'];
    label = json['label'];
    lock = json['lock'];
    isDefault = json['isDefault'];
    extra = json['extra'];
    List<dynamic> controls = json['controls'];
    controls.forEach((c) => this.controls.add(ControlData.fromJson(c)));
  }

  Map<String, dynamic> toJson() => {
        'ontid': ontid,
        'label': label,
        'lock': lock,
        'isDefault': isDefault,
        'controls': controls,
        'extra': extra
      };

  Future<PrivateKey> getPrivateKey(String pwd, {ScryptParams params}) async {
    var enc = controls[0].encryptedKey;
    var addr = await Address.fromBase58(controls[0].address);
    var salt = Convert.base64ToBytes(controls[0].salt);
    return enc.decrypt(Convert.strToBytes(pwd), addr, salt, params: params);
  }

  Keystore toKeystore() {
    var ctrl = controls[0];
    return Keystore(
        'I',
        label,
        ctrl.encryptedKey.algorithm.label,
        ctrl.encryptedKey.scrypt,
        Convert.bytesToBase64(ctrl.encryptedKey.raw),
        ctrl.salt,
        ctrl.address,
        ctrl.encryptedKey.parameters);
  }

  static Future<Identity> create(PrivateKey prikey, String pwd, String label,
      {ScryptParams params}) async {
    var pubkey = await prikey.getPublicKey();
    var ontid = await Address.generateOntId(pubkey);
    var addr = await Address.fromOntId(ontid);
    var salt = (await Buffer.random(16)).bytes;
    var enc = await prikey.encrypt(Convert.strToBytes(pwd), addr, salt,
        params: params);

    var ctrl = ControlData("1", enc, await addr.toBase58(), pubkey.hexEncoded,
        Convert.bytesToBase64(salt));
    var ret = Identity(ontid, label, false, false);
    ret.controls.add(ctrl);
    return ret;
  }

  static Future<String> randomLabel() async {
    return Convert.bytesToHexStr((await Buffer.random(4)).bytes);
  }

  static Future<Identity> fromEncryptedKey(
      PrivateKey encrypted, String label, String pwd, Address addr, String salt,
      {ScryptParams params}) async {
    var saltBytes = Convert.base64ToBytes(salt);
    var prikey =
        await encrypted.decrypt(Convert.strToBytes(pwd), addr, saltBytes);
    label = label == "" ? await randomLabel() : label;
    var pubkey = await prikey.getPublicKey();
    var ontid = await Address.generateOntId(pubkey);
    var ret = Identity(ontid, label, false, false);
    var ctrl = ControlData(
        "1", encrypted, await addr.toBase58(), pubkey.hexEncoded, salt);
    ret.controls.add(ctrl);
    return ret;
  }

  static Future<Identity> fromKeystore(Keystore keystore, String pwd) async {
    if (keystore.type != 'I')
      throw ArgumentError('Deformed keystore type: ' + keystore.type);

    var algo = KeyType.fromLabel(keystore.algorithm);
    var parameters = KeyParameters.fromCurve(keystore.parameters.curve);
    var scrypt = keystore.scrypt;
    var enc = PrivateKey(Convert.base64ToBytes(keystore.key),
        algorithm: algo, parameters: parameters, scrypt: scrypt);
    var addr = await Address.fromBase58(keystore.address);
    return fromEncryptedKey(enc, keystore.label, pwd, addr, keystore.salt);
  }
}
