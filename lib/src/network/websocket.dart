import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import 'package:ontology_dart_sdk/common.dart';
import 'package:ontology_dart_sdk/crypto.dart';
import 'package:ontology_dart_sdk/smart_contract.dart';

enum WebsocketRpcState { connected, reconnecting, closed }

class Pending {
  String id;
  Completer<dynamic> deferred;

  Pending() {
    id = Uuid().v1();
    deferred = Completer();
  }
}

class WebsocketRpc {
  String url;
  IOWebSocketChannel channel;
  WebsocketRpcState state = WebsocketRpcState.closed;
  var reconnectTimes = 3;
  var reconnectCurTimes = 1;
  var reconnectDelay = 5;

  var pendings = Map<String, Pending>();
  var waitNotifyPendings = Map<String, Pending>();

  WebsocketRpc(this.url);

  connect() {
    try {
      state = WebsocketRpcState.connected;
      var ping = Duration(seconds: 30);
      channel = IOWebSocketChannel.connect(url, pingInterval: ping);
      channel.stream.listen((msg) {
        _onMsg(msg);
      }, onError: (err) {
        close();
      }, onDone: () {
        state = WebsocketRpcState.closed;
        _reconnect();
      });
    } catch (e) {
      state = WebsocketRpcState.closed;
    }
  }

  _reconnect() {
    if (state != WebsocketRpcState.closed || reconnectTimes == 0) return;

    state = WebsocketRpcState.reconnecting;
    var delay = Duration(seconds: reconnectCurTimes * reconnectDelay);
    reconnectCurTimes += 1;
    reconnectTimes -= 1;
    Future.delayed(delay, () => connect());
  }

  close() {
    if (channel != null) channel.sink.close();
  }

  _send(Uint8List data) {
    channel.sink.add(data);
  }

  _onMsg(dynamic msg) {
    try {
      var resp = jsonDecode(msg);
      var id = resp['Id'];
      if (id != null) {
        var pending = pendings[id];
        if (pending != null) {
          if (resp['Error'] != 0) {
            pending.deferred.completeError(resp);
          } else {
            pending.deferred.complete(resp['Result']);
          }
          pendings.remove(id);
        }
        return;
      }
      var action = resp['Action'];
      if (action != null) {
        if (action == 'Notify') {
          var txHash = resp['Result']['TxHash'];
          var pending = waitNotifyPendings[txHash];
          if (pending != null) {
            pending.deferred.complete(resp);
            waitNotifyPendings.remove(txHash);
          }
        }
      }
    } catch (e) {}
  }

  Future<dynamic> send(Map<String, dynamic> data) async {
    var pending = Pending();
    data['Id'] = pending.id;
    pendings[pending.id] = pending;
    var raw = Convert.strToBytes(jsonEncode(data));
    _send(raw);
    return pending.deferred.future;
  }

  Future<dynamic> sendRawTx(Uint8List rawTx, {bool preExec = true}) async {
    var data = {
      'Action': 'sendrawtransaction',
      'Version': '1.0.0',
      'Data': Convert.bytesToHexStr(rawTx)
    };
    if (preExec) {
      data['PreExec'] = '1';
      return send(data);
    }
    var txHash = await send(data);
    var pending = Pending();
    waitNotifyPendings[txHash] = pending;
    return pending.deferred.future;
  }

  Future<dynamic> getNetworkId() async {
    var data = {'Action': 'getnetworkid', 'Version': '1.0.0'};
    return send(data);
  }

  Future<dynamic> getVersion() async {
    var data = {'Action': 'getversion', 'Version': '1.0.0'};
    return send(data);
  }

  Future<dynamic> getMempoolTxState(String txHash) async {
    var data = {
      'Action': 'getmempooltxstate',
      'Version': '1.0.1',
      'Hash': txHash,
    };
    return send(data);
  }

  Future<dynamic> getMempoolTxCount() async {
    var data = {'Action': 'getmempooltxcount', 'Version': '1.0.0'};
    return send(data);
  }

  Future<dynamic> getGrantOng(Address address) async {
    var data = {
      'Action': 'getgrantong',
      'Version': '1.0.0',
      'Addr': await address.toBase58()
    };
    return send(data);
  }

  Future<dynamic> getGasPrice() async {
    var data = {
      'Action': 'getgasprice',
      'Version': '1.0.0',
    };
    return send(data);
  }

  Future<dynamic> getBlockTxsByHeight(int height) async {
    var data = {
      'Action': 'getblocktxsbyheight',
      'Version': '1.0.0',
      'Height': height.toString(),
    };
    return send(data);
  }

  Future<dynamic> getBlockHash(int height) async {
    var data = {
      'Action': 'getblockhash',
      'Version': '1.0.0',
      'Height': height.toString(),
    };
    return send(data);
  }

  Future<dynamic> getAllowance(String asset, Address from, Address to) async {
    var data = {
      'Action': 'getallowance',
      'Version': '1.0.0',
      'Asset': asset,
      'From': await from.toBase58(),
      'To': await to.toBase58()
    };
    return send(data);
  }

  Future<dynamic> getUnclaimedOng(Address addr) async {
    return getAllowance(
        'ong', await Address.fromValue(OntAssetTxBuilder.ontContract), addr);
  }

  Future<dynamic> getMerkleProof(String hash) async {
    var data = {
      'Action': 'getmerkleproof',
      'Version': '1.0.0',
      'Hash': hash,
    };
    return send(data);
  }

  Future<dynamic> getStorage(String codeHash, String key) async {
    var data = {
      'Action': 'getstorage',
      'Version': '1.0.0',
      'Hash': codeHash,
      'Key': key
    };
    return send(data);
  }

  Future<dynamic> getBlockHeightByTxHash(String txHash) async {
    var data = {
      'Action': 'getblockheightbytxhash',
      'Version': '1.0.0',
      'Hash': txHash,
    };
    return send(data);
  }

  Future<dynamic> getSmartCodeEventByHash(String hash) async {
    var data = {
      'Action': 'getsmartcodeeventbyhash',
      'Version': '1.0.0',
      'Hash': hash,
    };
    return send(data);
  }

  Future<dynamic> getSmartCodeEventByHeight(int height) async {
    var data = {
      'Action': 'getsmartcodeeventbyhash',
      'Version': '1.0.0',
      'Height': height.toString(),
    };
    return send(data);
  }

  Future<dynamic> getContract(String hash, {bool json = false}) async {
    var data = {
      'Action': 'getcontract',
      'Version': '1.0.0',
      'Hash': hash,
      'Raw': json ? '0' : '1'
    };
    return send(data);
  }

  Future<dynamic> getUnboundOng(Address address) async {
    var data = {
      'Action': 'getunboundong',
      'Version': '1.0.0',
      'Addr': await address.toBase58()
    };
    return send(data);
  }

  Future<dynamic> getBalance(Address address) async {
    var data = {
      'Action': 'getbalance',
      'Version': '1.0.0',
      'Addr': await address.toBase58()
    };
    return send(data);
  }

  Future<dynamic> getBlockByHash(String hash, {bool json = false}) async {
    var data = {
      'Action': 'getblockbyhash',
      'Version': '1.0.0',
      'Hash': hash,
      'Raw': json ? '0' : '1'
    };
    return send(data);
  }

  Future<dynamic> getBlockByHeight(int height, {bool json = false}) async {
    var data = {
      'Action': 'getblockbyheight',
      'Version': '1.0.0',
      'Height': height.toString(),
      'Raw': json ? '0' : '1'
    };
    return send(data);
  }

  Future<dynamic> getBlockHeight() async {
    var data = {
      'Action': 'getblockheight',
      'Version': '1.0.0',
    };
    return send(data);
  }

  Future<dynamic> getRawTransaction(String txHash, {bool json = false}) async {
    var data = {
      'Action': 'gettransaction',
      'Version': '1.0.0',
      'Hash': txHash,
      'Raw': json ? '0' : '1'
    };
    return send(data);
  }

  Future<dynamic> getNodeCount() async {
    var data = {
      'Action': 'getconnectioncount',
      'Version': '1.0.0',
    };
    return send(data);
  }
}
