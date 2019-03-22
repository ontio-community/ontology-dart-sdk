import '../test_case.dart';
import 'package:ontology_dart_sdk/network.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/wallet.dart';
import 'package:ontology_dart_sdk/core.dart';
import 'package:ontology_dart_sdk/smart_contract.dart';
import '../common/wallet.dart';

WebsocketRpc rpc;
Wallet w;

PrivateKey prikey1;
PublicKey pubkey1;
Address addr1;

PrivateKey prikey2;
Address addr2;

int gasPrice = 0;
int gasLimit = 20000;

var isSetupDone = false;
Future<void> setup() async {
  if (isSetupDone) return;

  var w = wallet4test();
  prikey1 = await w.accounts[0].decrypt('password', params: w.scrypt);
  addr1 = await Address.fromBase58(w.accounts[0].address);

  prikey2 = await w.accounts[1].decrypt('123456', params: w.scrypt);
  addr2 = await Address.fromBase58(w.accounts[1].address);

  rpc = WebsocketRpc('ws://127.0.0.1:20335');
  rpc.connect();

  isSetupDone = true;
}

var testCases = [
  TestCase('testTransferOnt', () async {
    await setup();
    var from = addr1;
    var to = await Address.fromBase58('AL9PtS6F8nue5MwxhzXCKaTpRb3yhtsix5');

    var ob = OntAssetTxBuilder();
    var tx = await ob.makeTransferTx(
        'ONT', from, to, BigInt.from(300), gasPrice, gasLimit, from);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testTransferOng', () async {
    await setup();
    var from = addr1;
    var to = await Address.fromBase58('AL9PtS6F8nue5MwxhzXCKaTpRb3yhtsix5');

    var ob = OntAssetTxBuilder();
    var tx = await ob.makeTransferTx(
        'ONG', from, to, BigInt.from(170), gasPrice, gasLimit, from);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testTransferWithSm2Account', () async {
    await setup();
    var from = addr2;
    var to = addr1;

    var ob = OntAssetTxBuilder();
    var tx = await ob.makeTransferTx(
        'ONT', from, to, BigInt.from(100), gasPrice, gasLimit, from);

    var txb = TxBuilder();
    await txb.sign(tx, prikey2, schema: SignatureSchema.sm2Sm3);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testWithdrawOng', () async {
    await setup();
    var from = addr1;
    var to = addr1;

    var ob = OntAssetTxBuilder();
    var tx = await ob.makeWithdrawOngTx(
        from, to, BigInt.from(1000000000), gasPrice, gasLimit, from);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
];
