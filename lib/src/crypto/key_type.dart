import 'signature_schema.dart';

class KeyType {
  static KeyType ecdsa = KeyType('ECDSA', 0x12, SignatureSchema.ecdsaSha256);
  static KeyType sm2 = KeyType('SM2', 0x13, SignatureSchema.sm2Sm3);
  static KeyType eddsa = KeyType('eddsa', 0X14, SignatureSchema.eddsaSha512);

  String label;
  int value;
  SignatureSchema defaultSchema;

  KeyType(String label, int value, SignatureSchema defaultSchema)
      : label = label,
        value = value,
        defaultSchema = defaultSchema;

  static from(String label) {
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

  @override
  String toString() {
    return label;
  }
}
