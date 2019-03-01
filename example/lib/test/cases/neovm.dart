import 'dart:typed_data';
import 'package:collection/collection.dart';
import '../test_case.dart';
import 'package:ontology_dart_sdk/network.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/wallet.dart';
import 'package:ontology_dart_sdk/neocore.dart';
import 'package:ontology_dart_sdk/common.dart';
import '../common/wallet.dart';
import '../common/neovm.dart';

WebsocketRpc rpc;
Wallet w;

PrivateKey prikey1;
PublicKey pubkey1;
Address addr1;

PrivateKey prikey2;
PublicKey pubkey2;
Address addr2;

AbiFile abiFile;
Address contract;

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

  abiFile = abi();
  contract = await Address.fromValue(abiFile.contractHash);

  await deployContract();

  isSetupDone = true;
}

Future<void> deployContract() async {
  var b = TxBuilder();
  var tx = await b.makeDeployCodeTx(testavm(), 'name', '1.0', 'alice', 'email',
      'desc', true, gasPrice, gasLimit, addr1);

  await b.sign(tx, prikey1);
  await rpc.sendRawTx(await tx.serialize(), preExec: false);
}

var testCases = [
  TestCase('testNeovmName', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx('name', [], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize());
    assert(Convert.hexStrToStr(res['Result']) == 'name');
  }),
  TestCase('testNeovmHello', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx('hello', ['world'], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize());
    assert(Convert.hexStrToStr(res['Result']) == 'world');
  }),
  TestCase('testNeovmTrue', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx('testTrue', [], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize());
    assert(res['Result'] == '01');
  }),
  TestCase('testNeovmFalse', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx('testFalse', [], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize());
    assert(res['Result'] == '00');
  }),
  TestCase('testNeovmList', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx(
        'testHello',
        [
          false,
          300,
          Uint8List.fromList([1, 2, 3]),
          'string',
          contract
        ],
        contract,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        payer: addr1);

    await b.sign(tx, prikey1);
    var res = await rpc.sendRawTx(await tx.serialize());
    var list = res['Result'];
    assert(list[0] == '00');
    assert(Convert.hexStrToBigInt(list[1]) == BigInt.from(300));
    assert(ListEquality()
        .equals(Convert.hexStrToBytes(list[2]), Uint8List.fromList([1, 2, 3])));
    assert(Convert.hexStrToStr(list[3]) == 'string');
    assert(contract.hexEncoded == list[4]);
  }),
  TestCase('testNeovmStruct', () async {
    await setup();
    var b = TxBuilder();
    var struct = Struct();
    struct.list.addAll([100, 'claimid']);
    var tx = await b.makeInvokeTx('testStructList', [struct], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);
    var res = await rpc.sendRawTx(await tx.serialize());
    // assert(res['Result'] == '00');
  }),
  TestCase('testNeovmSetMap', () async {
    await setup();
    var b = TxBuilder();
    Map<String, dynamic> map = {'key': 'value'};
    var tx = await b.makeInvokeTx('testMap', [map], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);
    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testNeovmGetMap', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx('testGetMap', ['key'], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);
    var res = await rpc.sendRawTx(await tx.serialize());
    assert(Convert.hexStrToStr(res['Result']) == 'value');
  }),
  TestCase('testNeovmSetMapInMap', () async {
    await setup();
    var b = TxBuilder();
    Map<String, dynamic> map = {
      'key': {'key': 'value'}
    };
    var tx = await b.makeInvokeTx('testMapInMap', [map], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);
    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testNeovmGetMapInMap', () async {
    await setup();
    var b = TxBuilder();
    var tx = await b.makeInvokeTx('testGetMapInMap', ['key'], contract,
        gasPrice: gasPrice, gasLimit: gasLimit, payer: addr1);
    await b.sign(tx, prikey1);
    var res = await rpc.sendRawTx(await tx.serialize());
    assert(Convert.hexStrToStr(res['Result']) == 'value');
  }),
];
