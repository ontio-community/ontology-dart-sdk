import 'dart:typed_data';

import 'package:convert/convert.dart';

class Convert {
  static Uint8List hexStrToBytes(String str) {
    return Uint8List.fromList(hex.decode(str));
  }

  static String bytesTohexStr(Uint8List bytes) {
    return hex.encode(bytes.toList());
  }
}
