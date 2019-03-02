import '../crypto/shim.dart';

class Keystore {
  String type;
  String label;
  String algorithm;
  ScryptParams scrypt;
  String key;
  String salt;
  String address;
  KeyParameters parameters;

  Keystore(this.type, this.label, this.algorithm, this.scrypt, this.key,
      this.salt, this.address, this.parameters);

  Keystore.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    label = json['label'];
    algorithm = json['algorithm'];
    salt = json['salt'];
    scrypt = ScryptParams.fromJson(json['scrypt']);
    key = json['key'];
    address = json['address'];
    parameters = KeyParameters.fromJson(json['parameters']);
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        'algorithm': algorithm,
        'scrypt': algorithm,
        'key': key,
        'salt': key,
        'address': address,
        'parameters': parameters
      };
}
