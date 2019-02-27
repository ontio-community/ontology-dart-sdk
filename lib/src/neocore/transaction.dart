import 'dart:typed_data';
import '../crypto/shim.dart';
import '../common/shim.dart';
import '../constant.dart';
import 'payload.dart';
import 'script.dart';
import 'program.dart';
import 'opcode.dart';
import 'contract.dart';

class TxType {
  static var bookKeeper = TxType._internal('BookKeeper', 0x02);
  static var claim = TxType._internal('Claim', 0x03);
  static var deploy = TxType._internal('Deploy', 0xd0);
  static var invoke = TxType._internal('Invoke', 0xd1);
  static var enrollment = TxType._internal('Enrollment', 0x04);
  static var vote = TxType._internal('Vote', 0x05);

  String label;
  int value;

  TxType._internal(this.label, this.value);

  factory TxType.fromLabel(String label) {
    switch (label) {
      case 'BookKeeper':
        return bookKeeper;
      case 'Claim':
        return claim;
      case 'Deploy':
        return deploy;
      case 'Invoke':
        return invoke;
      case 'Enrollment':
        return enrollment;
      case 'Vote':
        return vote;
      default:
        throw ArgumentError('Invalid label');
    }
  }

  factory TxType.fromValue(int value) {
    switch (value) {
      case 0x02:
        return bookKeeper;
      case 0x03:
        return claim;
      case 0xd0:
        return deploy;
      case 0xd1:
        return invoke;
      case 0x04:
        return enrollment;
      case 0x05:
        return vote;
      default:
        throw ArgumentError('Invalid label');
    }
  }
}

class TxSignature {
  var pubkeys = <PublicKey>[];
  var m = 0;
  var sigData = <Uint8List>[];

  static Future<TxSignature> create(Signable data, PrivateKey pri,
      {SignatureSchema schema}) async {
    var ret = TxSignature();
    ret.pubkeys.add(await pri.getPublicKey());
    var sig = await pri.sign(await data.signContent(), schema: schema);
    ret.sigData.add(sig.bytes);
    return ret;
  }

  Future<Uint8List> serialize() async {
    var pb = ProgramBuilder.fromRawParams(sigData);
    var cnt = pubkeys.length;
    if (cnt == 0) throw ArgumentError('No pubkey');

    var sb = ScriptBuilder();
    sb.pushVarBytes(pb.buf.bytes);

    if (cnt == 1) {
      sb.pushVarBytes(ProgramBuilder.fromPubkey(pubkeys[0]).buf.bytes);
    } else {
      pb = await ProgramBuilder.fromPubkeys(pubkeys, m);
      sb.pushVarBytes(pb.buf.bytes);
    }
    return sb.buf.bytes;
  }

  static Future<TxSignature> deserialize(ProgramReader r) async {
    var tx = TxSignature();
    tx.sigData = r.readParams();
    var info = r.readInfo();
    tx.m = info.m;
    tx.pubkeys = info.pubkeys;
    return tx;
  }
}

abstract class Signable {
  Future<Uint8List> signContent();
  Uint8List serializeUnsignedData();
}

class Transaction extends Signable {
  var type = TxType.invoke;
  var version = 0x00;
  String nonce;
  var gasPrice = 0;
  var gasLimit = 0;
  Address payer;
  var sigs = <TxSignature>[];
  Payload payload;

  BigInt amount;
  String tokenType;
  Address from;
  Address to;
  String method;

  static Future<Transaction> create() async {
    var tx = Transaction();
    tx.payer =
        await Address.fromValue('0000000000000000000000000000000000000000');
    tx.nonce = Convert.bytesToHexStr((await Buffer.random(4)).bytes);
    return tx;
  }

  static Future<Transaction> deserialize(ScriptReader r) async {
    var tx = Transaction();
    tx.version = r.readUint8();
    tx.type = TxType.fromValue(r.readUint32LE());
    tx.nonce = Convert.bytesToHexStr(r.forward(4));
    tx.gasPrice = r.readUint64LE();
    tx.gasLimit = r.readUint64LE();
    tx.payer = Address(r.forward(20));

    Payload payload;
    if (tx.type == TxType.deploy) {
      payload = DeployCode();
    } else {
      payload = InvokeCode();
    }
    payload.deserialize(r);
    tx.payload = payload;

    r.readUint8();
    var sigLen = r.readVarInt();

    var buf = r.branch(r.ofst).buf;
    var pr = ProgramReader(buf);
    for (var i = 0; i < sigLen; i++) {
      tx.sigs.add(await TxSignature.deserialize(pr));
    }
    return tx;
  }

  Uint8List serializeUnsignedData() {
    var sb = ScriptBuilder();
    sb.pushNum(version);
    sb.pushNum(type.value);

    sb.pushRawBytes(Convert.hexStrToBytes(nonce));
    sb.pushNum(gasPrice, len: 8, bigEndian: false);
    sb.pushNum(gasLimit, len: 8, bigEndian: false);
    sb.pushRawBytes(payer.value);

    if (payload == null) throw ArgumentError('Empty payload');
    sb.pushRawBytes(payload.serialize());
    return sb.buf.bytes;
  }

  @override
  Future<Uint8List> signContent() async {
    var data = serializeUnsignedData();
    return Hash.sha256sha256(data);
  }

  Future<Uint8List> serializeSignedData() async {
    var sb = ScriptBuilder();
    sb.pushNum(sigs.length);
    for (var sig in sigs) {
      sb.pushRawBytes(await sig.serialize());
    }
    return sb.buf.bytes;
  }

  Future<Uint8List> serialize() async {
    var us = serializeUnsignedData();
    var ss = await serializeSignedData();
    return us + ss;
  }
}

class TxBuilder {
  TxBuilder();

  Future<void> sign(Transaction tx, PrivateKey prikey,
      {SignatureSchema schema}) async {
    var sig = await TxSignature.create(tx, prikey, schema: schema);
    tx.sigs = [sig];
  }

  Future<void> addSig(Transaction tx, PrivateKey prikey,
      {SignatureSchema schema}) async {
    var sig = await TxSignature.create(tx, prikey, schema: schema);
    tx.sigs.add(sig);
  }

  Future<Transaction> makeNativeContractTx(
      String fnName, Uint8List params, Address contract,
      {int gasPrice, int gasLimit, Address payer}) async {
    var sb = ScriptBuilder();
    sb.pushRawBytes(params);
    sb.pushHex(Convert.strToBytes(fnName));
    sb.pushAddress(contract);
    sb.pushInt(0);
    sb.pushOpcode(OpCode.syscall);
    sb.pushHex(Convert.strToBytes(Constant.nativeInvokeName));
    var payload = InvokeCode();
    payload.code = sb.buf.bytes;

    var tx = await Transaction.create();
    tx.type = TxType.invoke;
    tx.payload = payload;
    tx.gasPrice = gasPrice;
    tx.gasLimit = gasLimit;
    tx.payer = payer;
    return tx;
  }

  Future<Transaction> makeDeployCodeTx(
      Uint8List code,
      String name,
      String version,
      String author,
      String email,
      String desc,
      bool needStoreage,
      int gasPrice,
      int gasLimit,
      Address payer) async {
    var dc = DeployCode();
    dc.author = author;
    dc.code = code;
    dc.name = name;
    dc.version = version;
    dc.email = email;
    dc.needStorage = needStoreage;
    dc.desc = desc;

    var tx = await Transaction.create();
    tx.version = 0x00;
    tx.payload = dc;
    tx.type = TxType.deploy;
    tx.gasPrice = gasPrice;
    tx.gasLimit = gasLimit;
    tx.payer = payer;
    return tx;
  }

  Future<Transaction> makeInvokeTx(String fnName, List<dynamic> params,
      Address contract, int gasPrice, int gasLimit, Address payer) async {
    var tx = await Transaction.create();

    var pb = VmParamsBuilder();
    pb.pushFn(fnName, params);

    var sb = ScriptBuilder();
    sb.pushRawBytes(pb.buf.bytes);
    sb.pushOpcode(OpCode.appcall);
    sb.pushRawBytes(contract.valueLE);

    var payload = InvokeCode();
    payload.code = sb.buf.bytes;
    tx.payload = payload;

    tx.gasPrice = gasPrice;
    tx.gasLimit = gasLimit;
    tx.payer = payer;
    return tx;
  }
}
