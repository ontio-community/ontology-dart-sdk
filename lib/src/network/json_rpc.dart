import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/common.dart';
import 'package:ontology_dart_sdk/smart_contract.dart';

class JsonRpc {
  String url;

  JsonRpc(this.url);

  Map<String, dynamic> _makeReqBody(String method, {List<dynamic> params}) {
    return {
      'jsonrpc': '2.0',
      'method': method,
      'params': params ?? [],
      'id': Uuid().v1()
    };
  }

  Future<Map<String, dynamic>> _req(String method,
      {List<dynamic> params}) async {
    var body = _makeReqBody(method, params: params);
    var resp = await http.post(url, body: jsonEncode(body));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("server error: ${resp.statusCode}");
    }
    return jsonDecode(resp.body);
  }

  Future<Map<String, dynamic>> getNodeCount() async {
    return _req('getconnectioncount');
  }

  Future<Map<String, dynamic>> getBalance(Address address) async {
    return _req('getbalance', params: [await address.toBase58()]);
  }

  Future<dynamic> sendRawTx(Uint8List rawTx, {bool preExec = true}) async {
    var data = Convert.bytesToHexStr(rawTx);
    var params = <dynamic>[data];
    if (preExec) params.add(1);
    return _req('sendrawtransaction', params: params);
  }

  Future<dynamic> getRawTx(String txHash, {bool json = true}) async {
    var params = <dynamic>[txHash];
    if (json) params.add(1);
    return _req('getrawtransaction', params: params);
  }

  Future<Map<String, dynamic>> getBlockHeight() async {
    return _req('getblockcount');
  }

  Future<Map<String, dynamic>> getBlockCount() async {
    return _req('getblockcount');
  }

  /// value string|int the hash or height of the block
  Future<dynamic> getBlock(dynamic value, {bool json = true}) async {
    var params = <dynamic>[value];
    if (json) params.add(1);
    return _req('getblock', params: params);
  }

  Future<dynamic> getContract(String hash, {bool json = true}) async {
    var params = <dynamic>[hash];
    if (json) params.add(1);
    return _req('getcontractstate', params: params);
  }

  Future<dynamic> getSmartCodeEvent(String hash) async {
    return _req('getsmartcodeevent', params: [hash]);
  }

  Future<dynamic> getBlockHeightByTxHash(String hash) async {
    return _req('getblockheightbytxhash', params: [hash]);
  }

  Future<dynamic> getStorage(String hash, String key) async {
    return _req('getstorage', params: [hash, key]);
  }

  Future<dynamic> getMerkleProof(String hash) async {
    return _req('getmerkleproof', params: [hash]);
  }

  Future<dynamic> getAllowance(String asset, Address from, Address to) async {
    if (asset != 'ont' || asset != 'ont') throw Exception('invalid params');
    return _req('getallowance',
        params: [asset, await from.toBase58(), await to.toBase58()]);
  }

  Future<dynamic> getUnclaimedOng(Address addr) async {
    var from = await Address.fromValue(OntAssetTxBuilder.ontContract);
    return getAllowance('ong', from, addr);
  }
}
