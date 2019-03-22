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

PrivateKey prikey;
PublicKey pubkey;
Account acc;
Address addr;

String ontid;

int gasPrice = 0;
int gasLimit = 20000;

JsonRpc jsonRpc;

var isSetupDone = false;
Future<void> setup() async {
  if (isSetupDone) return;

  w = wallet4test();
  prikey1 = await w.accounts[0].decrypt('password', params: w.scrypt);
  pubkey1 = await prikey1.getPublicKey();
  addr1 = await Address.fromBase58(w.accounts[0].address);

  prikey = await PrivateKey.random();
  pubkey = await prikey.getPublicKey();
  acc = await Account.create('password', prikey: prikey);
  addr = await Address.fromBase58(acc.address);

  ontid = 'did:ont:' + (await addr.toBase58());

  rpc = WebsocketRpc('ws://127.0.0.1:20335');
  rpc.connect();

  jsonRpc = JsonRpc('http://127.0.0.1:20336');
  isSetupDone = true;
}

var testCases = [
  TestCase('testWsRpcGetNodeCount', () async {
    await setup();
    var res = await rpc.getNodeCount();
    assert(res != null);
  }),
  TestCase('testWsRpcBlockHeight', () async {
    await setup();
    var res = await rpc.getBlockHeight();
    assert(res != null);
  }),
  TestCase('testWsRpcGetBalance', () async {
    await setup();
    var res = await rpc.getBalance(addr1);
    assert(res != null);
  }),
  TestCase('testWsRpcUnclaimedOng', () async {
    await setup();
    var addr = await Address.fromBase58('ASSxYHNSsh4FdF2iNvHdh3Np2sgWU21hfp');
    var res = await rpc.getUnclaimedOng(addr);
    assert(res != null);
  }),
  TestCase('testWsRpcSendRawTx', () async {
    await setup();
    var b = OntidTxBuilder();
    var tx =
        await b.buildRegisterOntidTx(ontid, pubkey1, gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize());
    assert(res != null);
  }),
  TestCase('testWsRpcSendRawTxWait', () async {
    await setup();
    var b = OntidTxBuilder();
    var tx =
        await b.buildRegisterOntidTx(ontid, pubkey1, gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testJsonRpcGetNodeCount', () async {
    var res = await jsonRpc.getNodeCount();
    assert(res != null);
  }),
];
