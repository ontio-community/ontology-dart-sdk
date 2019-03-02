import 'dart:typed_data';
import '../common/convert.dart';
import 'script.dart';

abstract class Payload {
  Uint8List serialize();
  deserialize<T extends ScriptReader>(T r);
}

class InvokeCode extends Payload {
  Uint8List code;

  InvokeCode();

  @override
  Uint8List serialize() {
    var b = ScriptBuilder();
    b.pushVarBytes(code);
    return b.buf.bytes;
  }

  @override
  deserialize<T extends ScriptReader>(T r) {
    code = r.readVarBytes();
  }
}

class DeployCode extends Payload {
  Uint8List code;
  bool needStorage;
  String name;
  String version;
  String author;
  String email;
  String desc;

  DeployCode();

  @override
  Uint8List serialize() {
    var b = ScriptBuilder();
    b.pushVarBytes(code);
    b.pushBool(needStorage);
    b.pushVarBytes(Convert.strToBytes(name));
    b.pushVarBytes(Convert.strToBytes(version));
    b.pushVarBytes(Convert.strToBytes(author));
    b.pushVarBytes(Convert.strToBytes(email));
    b.pushVarBytes(Convert.strToBytes(desc));
    return b.buf.bytes;
  }

  @override
  deserialize<T extends ScriptReader>(T r) {
    code = r.readVarBytes();
    needStorage = r.readBool();
    name = Convert.bytesToStr(r.readVarBytes());
    version = Convert.bytesToStr(r.readVarBytes());
    author = Convert.bytesToStr(r.readVarBytes());
    email = Convert.bytesToStr(r.readVarBytes());
    desc = Convert.bytesToStr(r.readVarBytes());
  }
}
