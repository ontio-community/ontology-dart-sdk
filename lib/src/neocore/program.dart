import 'dart:typed_data';
import '../crypto/key.dart';
import 'script.dart';
import '../common/convert.dart';
import '../common/buffer.dart';

class ProgramInfo {
  int m = 0;
  List<PublicKey> pubkeys = [];
}

class ProgramBuilder extends ScriptBuilder {
  ProgramBuilder() : super();

  ProgramBuilder.fromPubkey(PublicKey pubkey) : super() {
    pushPubkey(pubkey);
    pushOpcode(OpCode.checksig);
  }

  ProgramBuilder.fromHexStrParams(List<String> params) : super() {
    params.sort();
    params.forEach((param) => pushBytes(Convert.hexStrToBytes(param)));
  }

  ProgramBuilder.fromRawParams(List<Uint8List> params) : super() {
    List<String> ps = params.map((param) => Convert.bytesToHexStr(param));
    ProgramBuilder.fromHexStrParams(ps);
  }

  pushPubkey(PublicKey pubkey) {
    if (pubkey.algorithm == KeyType.ecdsa) {
      pushVarBytes(pubkey.raw);
    } else if (pubkey.algorithm == KeyType.eddsa ||
        pubkey.algorithm == KeyType.sm2) {
      ScriptBuilder b = ScriptBuilder();
      b.pushNum(x: pubkey.algorithm.value);
      b.pushNum(x: pubkey.parameters.curve.value);
      b.pushRawBytes(pubkey.raw);
      pushVarBytes(b.buf.bytes);
    }
  }

  pushBytes(Uint8List bytes) {
    int len = bytes.lengthInBytes;
    if (len == 0) throw ArgumentError('empty bytes');

    if (len <= OpCode.pushbytes75 + 1 - OpCode.pushbytes1) {
      pushNum(x: len + OpCode.pushbytes1 - 1);
    } else if (len < 0x100) {
      pushOpcode(OpCode.pushdata1);
      pushNum(x: len);
    } else if (len < 0x10000) {
      pushOpcode(OpCode.pushdata2);
      pushNum(x: len, len: 2, bigEndian: false);
    } else if (len < 0x100000000) {
      pushOpcode(OpCode.pushdata4);
      pushNum(x: len, len: 4, bigEndian: false);
    } else {
      throw ArgumentError('Invalid bytes len: ' + len.toString());
    }
    pushRawBytes(bytes);
  }

  static int comparePublicKeys(_Pubkey a, _Pubkey b) {
    if (a.algo != b.algo) {
      return a.algo - b.algo;
    }

    if (a.algo == KeyType.ecdsa.value || a.algo == KeyType.sm2.value) {
      int cx = a.x.compareTo(b.x);
      if (cx != 0) return cx;
      return a.y.compareTo(b.y);
    }

    int aa = Buffer.fromBytes(a.raw).readUint64(ofst: 0);
    int bb = Buffer.fromBytes(b.raw).readUint64(ofst: 0);
    if (aa == bb) return 0;
    if (aa > bb) return 1;
    return -1;
  }

  /// TODO:: add tests later see:
  /// https://github.com/ontio/ontology-ts-sdk/blob/4a77b47090df55b81ed13d0eeb6e93c65a3851ff/test/transfer.test.ts
  static Future<ProgramBuilder> fromPubkeys(
      List<PublicKey> pubkeys, int m) async {
    ProgramBuilder prog = ProgramBuilder();
    int n = pubkeys.length;
    if (!(1 <= m && m <= n && n <= 1024))
      throw ArgumentError('Wrong multi sig params');

    Map<String, _Pubkey> pkMap = {};
    List<Future<dynamic>> convertTasks = [];
    var convertToPk = (PublicKey key) async {
      var pk = await _Pubkey.from(key);
      var kk = Convert.bytesToHexStr(key.raw);
      pkMap[kk] = pk;
    };

    pubkeys.forEach((pk) => convertTasks.add(convertToPk(pk)));
    await Future.wait(convertTasks);

    pubkeys.sort((a, b) {
      var ka = Convert.bytesToHexStr(a.raw);
      var kb = Convert.bytesToHexStr(b.raw);
      return comparePublicKeys(pkMap[ka], pkMap[kb]);
    });

    prog.pushInt(m);
    pubkeys.forEach((k) => prog.pushRawBytes(k.raw));
    prog.pushInt(n);
    prog.pushOpcode(OpCode.checkmultisig);
    return prog;
  }
}

class _Pubkey {
  Uint8List raw;
  int algo;
  BigInt x;
  BigInt y;

  static Future<_Pubkey> from(PublicKey pk) async {
    var ret = _Pubkey();
    ret.raw = pk.raw;
    ret.algo = pk.algorithm.value;
    List<String> xy = await Ecdsa.pubkeyXY(pk.raw, pk.parameters.curve);
    ret.x = BigInt.parse(xy[0], radix: 16);
    ret.y = BigInt.parse(xy[1], radix: 16);
    return ret;
  }
}

class ProgramReader extends ScriptReader {
  ProgramReader(Buffer buf, {int ofst = 0}) : super(buf, ofst: ofst);

  List<Uint8List> readParams() {
    var sig = <Uint8List>[];
    while (!isEnd) {
      sig.add(readBytes());
    }
    return sig;
  }

  PublicKey readPubkey() {
    var bytes = readVarBytes();
    return PublicKey.fromBytes(bytes);
  }

  ProgramInfo readInfo() {
    var info = ProgramInfo();
    var op = readOpCode();
    if (op == OpCode.checksig) {
      info.m = 1;
      info.pubkeys.add(readPubkey());
      return info;
    }
    if (op == OpCode.checkmultisig) {
      info.m = readInt().toInt();
      var n = ScriptReader(Buffer.fromBytes(buf.bytes.sublist(-5)))
          .readInt()
          .toInt();
      for (var i = 0; i < n; i++) {
        info.pubkeys.add(readPubkey());
      }
      return info;
    }
    throw ArgumentError('Unsupported prog');
  }
}
