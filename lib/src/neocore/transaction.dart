import 'dart:typed_data';
import 'dart:math';
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
  Future<Uint8List> serializeUnsignedData();
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

  Future<Uint8List> serializeUnsignedData() async {
    var sb = ScriptBuilder();
    sb.pushNum(version);
    sb.pushNum(type.value);

    gasPrice = gasPrice ?? 0;
    gasLimit = gasLimit ?? 20000;
    payer = payer ??
        await Address.fromValue('0000000000000000000000000000000000000000');

    sb.pushRawBytes(Convert.hexStrToBytes(nonce));
    sb.pushNum(gasPrice, len: 8, bigEndian: false);
    sb.pushNum(gasLimit, len: 8, bigEndian: false);
    sb.pushRawBytes(payer.value);

    if (payload == null) throw ArgumentError('Empty payload');
    sb.pushRawBytes(payload.serialize());
    sb.pushNum(0);
    return sb.buf.bytes;
  }

  @override
  Future<Uint8List> signContent() async {
    var data = await serializeUnsignedData();
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
    var us = await serializeUnsignedData();
    var ss = await serializeSignedData();
    var buf = Buffer.fromBytes(us);
    buf.appendBytes(ss);
    return buf.bytes;
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

  Future<Transaction> makeInvokeTx(
      String fnName, List<dynamic> params, Address contract,
      {int gasPrice, int gasLimit, Address payer}) async {
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

class OntAssetTxBuilder {
  static const ontContract = '0000000000000000000000000000000000000001';
  static const ongContract = '0000000000000000000000000000000000000002';

  OntAssetTxBuilder();

  Future<Address> getTokenContractAddr(String tokenType) async {
    if (tokenType == Constant.tokenType['ONT']) {
      return Address.fromValue(ontContract);
    } else if (tokenType == Constant.tokenType['ONG']) {
      return Address.fromValue(ongContract);
    }
    throw ArgumentError('Invalid token type: ' + tokenType);
  }

  BigInt verifyAmount(BigInt amount) {
    assert(
        amount > BigInt.from(0), 'Invalid amount: ' + amount.toRadixString(10));
    return amount;
  }

  Future<Transaction> makeTransferTx(String tokenType, Address from, Address to,
      BigInt amount, int gasPrice, int gasLimit, Address payer) async {
    amount = verifyAmount(amount);
    var struct = Struct();
    struct.list.addAll([from, to, amount]);

    var pb = VmParamsBuilder();
    pb.pushNativeCodeScript([
      [struct]
    ]);
    var params = pb.buf.bytes;

    var contract = await getTokenContractAddr(tokenType);
    var txb = TxBuilder();
    var tx = await txb.makeNativeContractTx('transfer', params, contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);

    tx.tokenType = tokenType;
    tx.from = from;
    tx.to = to;
    tx.amount = amount;
    tx.method = 'transfer';
    tx.payer = payer ?? from;
    return tx;
  }

  Future<Transaction> makeWithdrawOngTx(Address from, Address to, BigInt amount,
      int gasPrice, int gasLimit, Address payer) async {
    amount = verifyAmount(amount);
    var struct = Struct();
    struct.list.addAll([from, await getTokenContractAddr('ONT'), to, amount]);

    var pb = VmParamsBuilder();
    pb.pushNativeCodeScript([struct]);
    var params = pb.buf.bytes;

    var txb = TxBuilder();
    var tx = await txb.makeNativeContractTx(
        'transferFrom', params, await getTokenContractAddr('ONG'),
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);

    tx.tokenType = 'ONG';
    tx.from = from;
    tx.to = to;
    tx.amount = amount;
    tx.method = 'transferFrom';
    return tx;
  }

  Future<Transaction> deserializeTx(ScriptReader r) async {
    var tx = await Transaction.deserialize(r);
    var code = Convert.bytesToHexStr(tx.payload.serialize());

    var contractIdx1 =
        code.indexOf('14' + '000000000000000000000000000000000000000');
    var contractIdx2 =
        code.indexOf('14' + '0000000000000000000000000000000000000002');

    if (contractIdx1 > 0 && substr(code, contractIdx1 + 41, 1) == '1') {
      tx.tokenType = 'ONT';
    } else if (contractIdx1 > 0 && substr(code, contractIdx1 + 41, 1) == '2') {
      tx.tokenType = 'ONG';
    } else {
      throw ArgumentError('Deformed transfer tx');
    }

    var contractIdx = max(contractIdx1, contractIdx2);
    var params = substr(code, 0, contractIdx);
    var paramsEnd = code.indexOf('6a7cc86c') + 8;
    String method;
    if (substr(params, paramsEnd, 4) == '51c1') {
      method = substr(params, paramsEnd + 6, params.length - paramsEnd - 6);
    } else {
      method = substr(params, paramsEnd + 2, params.length - paramsEnd - 2);
    }
    tx.method = Convert.hexStrToStr(method);

    var sb = ScriptReader(Buffer.fromBytes(Convert.hexStrToBytes(params)));
    if (tx.method == 'transfer') {
      sb.forward(5);
      tx.from = Address(sb.forward(20));
      sb.forward(4);
      tx.to = Address(sb.forward(20));
      sb.forward(3);
      var numTmp = sb.readUint8();
      if (Convert.bytesToHexStr(sb.branch(sb.ofst).forward(3)) == '6a7cc8') {
        tx.amount = BigInt.from(numTmp - 80);
      } else {
        tx.amount = Convert.bytesToBigInt(sb.forward(numTmp));
      }
    } else if (tx.method == 'transferFrom') {
      sb.advance(5);
      tx.from = Address(sb.forward(20));
      sb.advance(28);
      tx.to = Address(sb.forward(20));
      sb.advance(3);
      var numTmp = sb.readUint8();
      if (Convert.bytesToHexStr(sb.branch(sb.ofst).forward(3)) == '6a7cc8') {
        tx.amount = BigInt.from(numTmp - 80);
      } else {
        tx.amount = Convert.bytesToBigInt(sb.forward(numTmp));
      }
    } else {
      throw ArgumentError('Deformed transfer tx');
    }
    return tx;
  }
}

class OntidTxBuilder {
  static const ontidContract = '0000000000000000000000000000000000000003';

  OntidTxBuilder();

  Future<Transaction> buildRegisterOntidTx(String ontid, PublicKey pubkey,
      int gasPrice, int gasLimit, Address payer) async {
    var method = 'regIDWithPublicKey';
    var struct = Struct();
    struct.list.addAll([Convert.strToBytes(ontid), pubkey.hexEncoded]);

    var pb = VmParamsBuilder();
    pb.pushNativeCodeScript([struct]);

    var txb = TxBuilder();
    return txb.makeNativeContractTx(
        method, pb.buf.bytes, await Address.fromValue(ontidContract),
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);
  }

  Future<Transaction> buildGetDDOTx(String ontid) async {
    var method = 'getDDO';
    var struct = Struct();
    struct.list.add(Convert.strToBytes(ontid));

    var pb = VmParamsBuilder();
    pb.pushNativeCodeScript([struct]);

    var txb = TxBuilder();
    return txb.makeNativeContractTx(
        method, pb.buf.bytes, await Address.fromValue(ontidContract));
  }
}

class OepState {
  Address from;
  Address to;
  BigInt amount;

  OepState(this.from, this.to, this.amount);
}

class Oep4TxBuilder {
  Address contract;

  Oep4TxBuilder(this.contract);

  Future<Transaction> makeInitTx(
      int gasPrice, int gasLimit, Address payer) async {
    var b = TxBuilder();
    var fn = 'init';
    return b.makeInvokeTx(fn, [], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);
  }

  Future<Transaction> makeTransferTx(Address from, Address to, BigInt amount,
      int gasPrice, int gasLimit, Address payer) async {
    var b = TxBuilder();
    var fn = 'transfer';
    return b.makeInvokeTx(fn, [from, to, amount], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);
  }

  Future<Transaction> makeTransferMultiTx(
      List<OepState> states, int gasPrice, int gasLimit, Address payer) {
    var fn = 'transferMulti';
    var params = <dynamic>[];
    states.forEach((s) => params.add([s.from, s.to, s.amount]));

    var b = TxBuilder();
    return b.makeInvokeTx(fn, params, contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);
  }

  Future<Transaction> makeApproveTx(Address owner, Address spender,
      BigInt amount, int gasPrice, int gasLimit, Address payer) async {
    var fn = 'approve';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [owner, spender, amount], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);
  }

  Future<Transaction> makeTransferFromTx(
      Address spender,
      Address from,
      Address to,
      BigInt amount,
      int gasPrice,
      int gasLimit,
      Address payer) async {
    var fn = 'transferFrom';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [spender, from, to, amount], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: payer);
  }

  Future<Transaction> makeQueryAllowanceTx(
      Address owner, Address spender) async {
    var fn = 'allowance';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [owner, spender], contract);
  }

  Future<Transaction> makeQueryBalanceOfTx(Address addr) async {
    var fn = 'balanceOf';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [addr], contract);
  }

  Future<Transaction> makeQueryTotalSupplyTx() async {
    var fn = 'totalSupply';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [], contract);
  }

  Future<Transaction> makeQueryDecimalsTx() async {
    var fn = 'decimals';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [], contract);
  }

  Future<Transaction> makeQuerySymbolTx() async {
    var fn = 'symbol';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [], contract);
  }

  Future<Transaction> makeQueryNameTx() async {
    var fn = 'name';
    var b = TxBuilder();
    return b.makeInvokeTx(fn, [], contract);
  }
}
