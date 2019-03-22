import 'dart:math';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/constant.dart';
import 'package:ontology_dart_sdk/core.dart';
import 'package:ontology_dart_sdk/common.dart';

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
