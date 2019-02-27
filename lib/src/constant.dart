import 'common/convert.dart';

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

  static var defaultSm2Id = Convert.strToBytes('1234567812345678');

  static const ontBip44Path = "m/44'/1024'/0'/0/0";
}
