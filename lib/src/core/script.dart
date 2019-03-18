import 'dart:typed_data';
import 'package:ontology_dart_sdk/common.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'opcode.dart';
import 'contract.dart';

class ScriptBuilder {
  Buffer buf;

  ScriptBuilder() : buf = Buffer();

  pushNum(int x, {int len = 1, bigEndian = true}) {
    switch (len) {
      case 1:
        buf.addUint8(x);
        break;
      case 2:
        buf.addUint16(v: x, bigEndian: bigEndian);
        break;
      case 4:
        buf.addUint32(v: x, bigEndian: bigEndian);
        break;
      case 8:
        buf.addUint64(v: x, bigEndian: bigEndian);
        break;
      default:
        throw ArgumentError('Invalid num len: ' + len.toString());
    }
  }

  pushBool(bool b) {
    pushNum(b ? OpCode.pusht : OpCode.pushf);
  }

  pushRawBytes(Uint8List bytes) {
    buf.appendBytes(bytes);
  }

  pushVarInt(int x) {
    if (x < 0xfd) {
      pushNum(x);
    } else if (x < 0xffff) {
      pushNum(0xfd);
      pushNum(x, len: 2, bigEndian: false);
    } else if (x < 0xffffffff) {
      pushNum(0xfe);
      pushNum(x, len: 4, bigEndian: false);
    } else {
      pushNum(0xff);
      pushNum(x, len: 8, bigEndian: false);
    }
  }

  pushVarBytes(Uint8List bytes) {
    pushVarInt(bytes.lengthInBytes);
    pushRawBytes(bytes);
  }

  pushHex(Uint8List hex) {
    int len = hex.lengthInBytes;
    if (len < OpCode.pushbytes75) {
      pushNum(len);
    } else if (len < 0x100) {
      pushNum(OpCode.pushdata1);
      pushNum(len);
    } else if (len < 0x10000) {
      pushNum(OpCode.pushdata2);
      pushNum(len, len: 2, bigEndian: false);
    } else {
      pushNum(OpCode.pushdata4);
      pushNum(len, len: 4, bigEndian: false);
    }
    pushRawBytes(hex);
  }

  pushBigInt(BigInt x) async {
    if (x == BigInt.from(-1)) {
      pushNum(OpCode.pushm1);
    } else if (x == BigInt.from(0)) {
      pushNum(OpCode.push0);
    } else if (x > BigInt.from(0) && x < BigInt.from(16)) {
      pushNum(OpCode.push1 - 1 + x.toInt());
    } else {
      pushHex(Convert.bigIntToBytes(v: x, bigEndian: false));
    }
  }

  pushInt(int x) {
    if (x == -1) {
      pushNum(OpCode.pushm1);
    } else if (x == 0) {
      pushNum(OpCode.push0);
    } else if (x > 0 && x < 16) {
      pushNum(OpCode.push1 - 1 + x);
    } else {
      pushBigInt(BigInt.from(x));
    }
  }

  pushHexStr(String str) {
    pushHex(Convert.hexStrToBytes(str));
  }

  pushAddress(Address addr) {
    pushHex(addr.value);
  }

  pushOpcode(int opcode) {
    pushNum(opcode);
  }

  pushStr(String str) {
    pushHex(Convert.strToBytes(str));
  }
}

class ScriptReader extends BufferReader {
  ScriptReader(Buffer buf, {int ofst = 0}) : super(buf, ofst: ofst);

  int readOpCode() {
    return readUint8();
  }

  bool readBool() {
    return readOpCode() == OpCode.pusht;
  }

  Uint8List readBytes() {
    int op = readOpCode();
    int len = 0;
    if (op == OpCode.pushdata4) {
      len = readUint32LE();
    } else if (op == OpCode.pushdata2) {
      len = readUint16LE();
    } else if (op == OpCode.pushdata1) {
      len = readUint8();
    } else if (op <= OpCode.pushbytes75 && op >= OpCode.pushbytes1) {
      len = op - OpCode.pushbytes1 + 1;
    } else {
      throw ArgumentError('Unsupported opcode: ' + op.toString());
    }
    return forward(len);
  }

  int readVarInt() {
    int len = readUint8();
    if (len == 0xfd) {
      return readUint16LE();
    } else if (len == 0xfe) {
      return readUint32LE();
    } else if (len == 0xff) {
      return readUint64LE();
    }
    return len;
  }

  Uint8List readVarBytes() {
    int len = readVarInt();
    return forward(len);
  }

  BigInt readInt() {
    int op = readOpCode();
    int x = op - OpCode.push1 + 1;
    if (op == OpCode.push0) {
      return BigInt.from(0);
    } else if (1 <= x && x >= 16) {
      return BigInt.from(x);
    }
    return Convert.bytesToBigInt(readVarBytes(), bigEndian: false);
  }

  Uint8List readNullTerminated() {
    var buf = Buffer();
    while (true) {
      int byte = readUint8();
      if (byte == 0) break;
      buf.addUint8(byte);
    }
    return buf.bytes;
  }

  Struct readStruct() {
    readOpCode();
    var ret = Struct();
    var len = readUint8();
    for (var i = 0; i < len; i++) {
      var type = readUint8();
      var bytes = readVarBytes();
      ret.list.add(StructField(type, bytes));
    }
    return ret;
  }
}
