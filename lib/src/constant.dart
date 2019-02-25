class Constant {
  static Map<String, dynamic> defaultAlgorithm = {
    'algorithm': 'ECDSA',
    'parameters': {'curve': 'P-256'},
  };

  static Map<String, dynamic> defaultScrypt = {
    'cost': 4096,
    'blockSize': 8,
    'parallel': 8,
    'size': 64
  };

  static const int addrVersion = 0x17;
}
