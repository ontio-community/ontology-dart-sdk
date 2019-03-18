import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/core.dart';

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
