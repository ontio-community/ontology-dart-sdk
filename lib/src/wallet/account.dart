import '../crypto/shim.dart';
import '../common/shim.dart';

class Account {
  String label;
  String address;
  bool lock;
  PrivateKey encryptedKey;
  String hash;
  String salt;
  String publicKey;
  bool isDefault;
  String extra;

  Account(this.label, this.address, this.lock, this.encryptedKey, this.salt,
      this.publicKey, this.isDefault,
      {this.hash, this.extra});

  static Future<Account> create(String pwd,
      {PrivateKey prikey, String label, ScryptParams params}) async {
    prikey = prikey ?? await PrivateKey.random();
    label = label ?? await randomLabel();
    var salt = (await Buffer.random(4)).bytes;
    var pubkey = await prikey.getPublicKey();
    var addr = await Address.fromPubkey(pubkey);
    var enc = await prikey.encrypt(Convert.strToBytes(pwd), addr, salt,
        params: params);
    return Account(label, await addr.toBase58(), false, enc,
        Convert.bytesToBase64(salt), pubkey.hexEncoded, false);
  }

  static Future<String> randomLabel() async {
    return Convert.bytesToHexStr((await Buffer.random(4)).bytes);
  }

  static Future<Account> fromEncryptedKey(
      PrivateKey enc, String label, String pwd, Address addr, String salt,
      {ScryptParams params}) async {
    var saltBytes = Convert.base64ToBytes(salt);
    var prikey = await enc.decrypt(Convert.strToBytes(pwd), addr, saltBytes);
    label = label == "" ? await randomLabel() : label;
    var pubkey = await prikey.getPublicKey();
    return Account(label, await addr.toBase58(), false, enc, salt,
        pubkey.hexEncoded, false);
  }

  static Future<Account> fromWif(String wif, String pwd,
      {String label, ScryptParams params}) async {
    var prikey = await PrivateKey.fromWif(wif);
    return create(pwd, prikey: prikey, label: label, params: params);
  }

  static Future<Account> fromMnemonic(String mnemonic, String pwd,
      {String label, ScryptParams params}) async {
    var prikey = await PrivateKey.fromMnemonic(mnemonic);
    return create(pwd, prikey: prikey, label: label, params: params);
  }

  Account.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    address = json['address'];
    lock = json['lock'];
    salt = json['salt'];
    publicKey = json['publicKey'];
    hash = json['hash'];
    extra = json['extra'];

    var algo = KeyType.fromLabel(json['algorithm']);
    var params = KeyParameters.fromJson(json['parameters']);
    var key = Convert.base64ToBytes(json['key']);
    encryptedKey = PrivateKey(key, algorithm: algo, parameters: params);
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'address': address,
        'lock': lock,
        'enc-alg': 'aes-256-gcm',
        'salt': salt,
        'isDefault': isDefault,
        'publicKey': publicKey,
        'signatureScheme': encryptedKey.algorithm.defaultSchema.label,
        'algorithm': encryptedKey.algorithm.label,
        'parameters': encryptedKey.parameters,
        'key': Convert.bytesToBase64(encryptedKey.raw),
        'hash': hash,
        'extra': extra,
      };
}
