import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../constant.dart';
import 'method_channel.dart';

class Scrypt {
  static Future<dynamic> decryptWithGcm(
      {@required Uint8List encrypted,
      @required Uint8List addr58,
      @required Uint8List salt,
      @required Uint8List pwd,
      ScryptParams params}) async {
    if (params == null) params = ScryptParams.defaultParams;

    Uint8List derived =
        await encrypt(password: pwd, salt: salt, params: params);

    Uint8List iv = derived.sublist(0, 11);
    Uint8List key = derived.sublist(32);
    return invokeCrypto('aes256gcm.decrypt', [encrypted, key, iv, addr58]);
  }

  static Future<dynamic> encrypt(
      {@required Uint8List password,
      @required Uint8List salt,
      ScryptParams params}) async {
    if (params == null) params = ScryptParams.defaultParams;

    return invokeCrypto('scrypt.encrypt', [password, salt, params.toJson()]);
  }

  static Future<dynamic> encryptWithGcm(
      {@required Uint8List prikey,
      @required Uint8List addr58,
      @required Uint8List salt,
      @required Uint8List pwd,
      ScryptParams params}) async {
    if (params == null) params = ScryptParams.defaultParams;

    Uint8List derived =
        await encrypt(password: pwd, salt: salt, params: params);

    Uint8List iv = derived.sublist(0, 11);
    Uint8List key = derived.sublist(32);
    return invokeCrypto('aes256gcm.encrypt', [prikey, key, iv, addr58]);
  }
}

class ScryptParams {
  static ScryptParams defaultParams = ScryptParams(
      n: Constant.defaultScrypt['cost'],
      r: Constant.defaultScrypt['blockSize'],
      p: Constant.defaultScrypt['parallel'],
      dkLen: Constant.defaultScrypt['size']);

  int n;
  int r;
  int p;
  int dkLen;

  ScryptParams({int n = 16384, int r = 8, int p = 8, int dkLen = 64})
      : n = n,
        r = r,
        p = p,
        dkLen = dkLen;

  ScryptParams.fromJson(Map<String, dynamic> json)
      : n = json['n'],
        r = json['r'],
        p = json['p'],
        dkLen = json['dkLen'];

  Map<String, dynamic> toJson() => {'n': n, 'r': r, 'p': p, 'dkLen': dkLen};
}
