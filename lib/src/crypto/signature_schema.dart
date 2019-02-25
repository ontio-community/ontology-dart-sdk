class SignatureSchema {
  static SignatureSchema ecdsaSha224 = SignatureSchema('SHA224withECDSA', 0);
  static SignatureSchema ecdsaSha256 = SignatureSchema('SHA256withECDSA', 1);
  static SignatureSchema ecdsaSha384 = SignatureSchema('SHA384withECDSA', 2);
  static SignatureSchema ecdsaSha512 = SignatureSchema('SHA512withECDSA', 3);
  static SignatureSchema ecdsaSha3_224 =
      SignatureSchema('SHA3-224withECDSA', 4);
  static SignatureSchema ecdsaSha3_256 =
      SignatureSchema('SHA3-256withECDSA', 5);
  static SignatureSchema ecdsaSha3_384 =
      SignatureSchema('SHA3-384withECDSA', 6);
  static SignatureSchema ecdsaSha3_512 =
      SignatureSchema('SHA3-512withECDSA', 7);
  static SignatureSchema ecdsaRipemd160 =
      SignatureSchema('RIPEMD160withECDSA', 8);
  static SignatureSchema sm2Sm3 = SignatureSchema('SM3withSM2', 9);
  static SignatureSchema eddsaSha512 = SignatureSchema('SHA512withEdDSA', 10);

  String label;
  int value;

  SignatureSchema(String label, int value)
      : label = label,
        value = value;
}
