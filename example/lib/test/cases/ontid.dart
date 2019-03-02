import '../test_case.dart';
import 'package:ontology_dart_sdk/network.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/wallet.dart';
import 'package:ontology_dart_sdk/neocore.dart';
import '../common/wallet.dart';

WebsocketRpc rpc;
Wallet w;

PrivateKey prikey1;
PublicKey pubkey1;
Address addr1;

PrivateKey prikey2;
PublicKey pubkey2;
Address addr2;

String ontid;

int gasPrice = 0;
int gasLimit = 20000;

var isSetupDone = false;
Future<void> setup() async {
  if (isSetupDone) return;

  var w = wallet4test();
  prikey1 = await w.accounts[0].decrypt('password', params: w.scrypt);
  pubkey1 = await prikey1.getPublicKey();
  addr1 = await Address.fromBase58(w.accounts[0].address);

  prikey2 = await PrivateKey.random();
  pubkey2 = await prikey2.getPublicKey();
  addr2 = await Address.fromPubkey(pubkey2);

  ontid = 'did:ont:' + (await addr2.toBase58());

  rpc = WebsocketRpc('ws://127.0.0.1:20335');
  rpc.connect();

  isSetupDone = true;
}

var testCases = [
  TestCase('testRegisterOntId', () async {
    await setup();
    var b = OntidTxBuilder();
    var tx =
        await b.buildRegisterOntidTx(ontid, pubkey1, gasPrice, gasLimit, addr1);

    var txb = TxBuilder();
    await txb.sign(tx, prikey1);

    var res = await rpc.sendRawTx(await tx.serialize(), preExec: false);
    assert(res != null);
  }),
  TestCase('testGetDDO', () async {
    await setup();
    var b = OntidTxBuilder();
    var tx = await b.buildGetDDOTx(ontid);
    var res = await rpc.sendRawTx(await tx.serialize());
    assert(res != null);
  }),
];
