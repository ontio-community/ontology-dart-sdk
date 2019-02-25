class Curve {
  static Curve p224 = Curve('P-224', 1);
  static Curve p256 = Curve('P-256', 2);
  static Curve p384 = Curve('P-384', 3);
  static Curve p521 = Curve('P-521', 4);
  static Curve sm2p256v1 = Curve('sm2p256v1', 20);
  static Curve ed25519 = Curve('ed25519', 25);

  String label;
  int value;

  Curve(String label, int value)
      : label = label,
        value = value;

  static fromLabel(String label) {
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

  static fromValue(int value) {}
}
