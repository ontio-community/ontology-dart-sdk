import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../constant.dart';
import 'bridge.dart';

class Scrypt {
  static Future<Uint8List> decryptWithGcm(
      {@required Uint8List encrypted,
      @required Uint8List addr58,
      @required Uint8List salt,
      @required Uint8List pwd,
      ScryptParams params}) async {
    if (params == null) params = ScryptParams.defaultParams;

    var derived = await encrypt(password: pwd, salt: salt, params: params);

    var iv = derived.sublist(0, 12);
    var key = derived.sublist(32);

    var res =
        await invokeCrypto('aes256gcm.decrypt', [encrypted, key, iv, addr58]);
    return res as Uint8List;
  }

  static Future<Uint8List> encrypt(
      {@required Uint8List password,
      @required Uint8List salt,
      ScryptParams params}) async {
    if (params == null) params = ScryptParams.defaultParams;

    var res =
        await invokeCrypto('scrypt.encrypt', [password, salt, params.toJson()]);
    return res as Uint8List;
  }

  static Future<Uint8List> encryptWithGcm(
      {@required Uint8List prikey,
      @required Uint8List addr58,
      @required Uint8List salt,
      @required Uint8List pwd,
      ScryptParams params}) async {
    if (params == null) params = ScryptParams.defaultParams;

    var derived = await encrypt(password: pwd, salt: salt, params: params);

    var iv = derived.sublist(0, 12);
    var key = derived.sublist(32);
    var res =
        await invokeCrypto('aes256gcm.encrypt', [prikey, key, iv, addr58]);
    return res as Uint8List;
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
