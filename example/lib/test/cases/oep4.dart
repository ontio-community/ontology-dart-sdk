import '../test_case.dart';
import 'package:ontology_dart_sdk/network.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/wallet.dart';
import 'package:ontology_dart_sdk/neocore.dart';
import 'package:ontology_dart_sdk/common.dart';
import '../common/wallet.dart';
import '../common/oep4.dart';

WebsocketRpc rpc;
Wallet w;

PrivateKey prikey1;
PublicKey pubkey1;
Address addr1;

PrivateKey prikey2;
PublicKey pubkey2;
Address addr2;

int gasPrice = 0;
int gasLimit = 30000000;

var isSetupDone = false;
Future<void> setup() async {
  if (isSetupDone) return;

  var w = wallet4test();
  prikey1 = await w.accounts[0].decrypt('password', params: w.scrypt);
  pubkey1 = await prikey1.getPublicKey();
  addr1 = await Address.fromPubkey(pubkey1);

  prikey2 = await w.accounts[1].decrypt('123456', params: w.scrypt);
  pubkey2 = await prikey2.getPublicKey();
  addr2 = await Address.fromPubkey(pubkey2);

  rpc = WebsocketRpc('ws://127.0.0.1:20335');
  rpc.connect();

  await deployContract();

  isSetupDone = true;
}

Future<void> deployContract() async {
  var b = TxBuilder();
  var tx = await b.makeDeployCodeTx(oep4avm(), 'name', '1.0', 'alice', 'email',
      'desc', true, gasPrice, gasLimit, addr1);

  await b.sign(tx, prikey1);
  await rpc.sendRawTx(await tx.serialize(), preExec: false);
}

var testCases = [
  TestCase('testOep4Init', () async {
    await setup();
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeInitTx(gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    return res != null;
  }),
  TestCase('testOep4QueryName', () async {
    await setup();
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeQueryNameTx();
    var res = await rpc.sendRawTx(await tx.serialize());
    return Convert.hexStrToStr(res['Result']) == 'MyToken';
  }),
  TestCase('testOep4QuerySymbol', () async {
    await setup();
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeQuerySymbolTx();
    var res = await rpc.sendRawTx(await tx.serialize());
    return Convert.hexStrToStr(res['Result']) == 'MYT';
  }),
  TestCase('testOep4QueryDecimals', () async {
    await setup();
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeQueryDecimalsTx();
    var res = await rpc.sendRawTx(await tx.serialize());
    return Convert.hexStrToBigInt(res['Result']) == BigInt.from(8);
  }),
  TestCase('testOep4QueryTotalSupply', () async {
    await setup();
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeQueryTotalSupplyTx();
    var res = await rpc.sendRawTx(await tx.serialize());
    return Convert.hexStrToBigInt(res['Result']) ==
        (BigInt.from(1000000000) * BigInt.from(100000000));
  }),
  TestCase('testOep4QueryBalance', () async {
    await setup();
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeQueryBalanceOfTx(addr1);
    var res = await rpc.sendRawTx(await tx.serialize());
    return res != null;
  }),
  TestCase('testOep4Transfer', () async {
    var from = addr1;
    var to = addr2;

    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeTransferTx(
        from, to, BigInt.from(10000), gasPrice, gasLimit, from);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    return res != null;
  }),
  TestCase('testOep4Approvel', () async {
    var owner = addr1;
    var spender = addr2;

    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeApproveTx(
        owner, spender, BigInt.from(10000), gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    return res != null;
  }),
  TestCase('testOep4QueryAlloance', () async {
    await setup();
    var owner = addr1;
    var spender = addr2;
    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeQueryAllowanceTx(owner, spender);
    var res = await rpc.sendRawTx(await tx.serialize());
    return res != null;
  }),
  TestCase('testOep4TransferFrom', () async {
    var owner = addr1;
    var spender = addr2;

    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b.makeTransferFromTx(
        spender, spender, owner, BigInt.from(10000), gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    return res != null;
  }),
  TestCase('testOep4TransferMulti', () async {
    var prikey3 = await PrivateKey.random();
    var pubkey3 = await prikey3.getPublicKey();
    var addr3 = await Address.fromPubkey(pubkey3);

    var state1 = OepState(addr1, addr2, BigInt.from(200));
    var state2 = OepState(addr1, addr3, BigInt.from(300));

    var b = Oep4TxBuilder(await Address.fromValue(codehash));
    var tx = await b
        .makeTransferMultiTx([state1, state2], gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);
    await txb.addSig(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    return res != null;
  }),
];
