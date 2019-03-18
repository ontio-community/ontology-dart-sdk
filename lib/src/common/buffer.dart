import 'dart:typed_data';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'bridge.dart';
import 'package:ontology_dart_sdk/common.dart';

class Buffer {
  Uint8List _buf;
  int _writePos = 0;
  ByteData _view;

  Uint8List get bytes {
    return _buf.sublist(0, _writePos);
  }

  _init(size) {
    _buf = Uint8List(size);
    _view = ByteData.view(_buf.buffer);
  }

  Buffer({int size = 32}) {
    _init(32);
  }

  Buffer.fromBytes(Uint8List bytes) {
    _init(32);
    bytes.forEach((b) => addUint8(b));
  }

  Buffer.fromHexStr(String str) {
    _init(32);
    Convert.hexStrToBytes(str).forEach((b) => addUint8(b));
  }

  grow() {
    if (_writePos == _buf.length - 1) {
      var newBuf = Uint8List(_buf.length * 2);
      _buf.asMap().forEach((k, v) => newBuf[k] = v);
      _buf = newBuf;
      _view = ByteData.view(_buf.buffer);
    }
  }

  addUint8(int v) {
    grow();
    _view.setUint8(_writePos, v);
    _writePos += 1;
  }

  addUint16({int v, bool bigEndian = true}) {
    grow();
    _view.setUint16(_writePos, v, bigEndian ? Endian.big : Endian.little);
    _writePos += 2;
  }

  addUint32({int v, bool bigEndian = true}) {
    grow();
    _view.setUint32(_writePos, v, bigEndian ? Endian.big : Endian.little);
    _writePos += 4;
  }

  addUint64({int v, bool bigEndian = true}) {
    grow();
    _view.setUint64(_writePos, v, bigEndian ? Endian.big : Endian.little);
    _writePos += 8;
  }

  addInt8(int v) {
    grow();
    _view.setInt8(_writePos, v);
    _writePos += 1;
  }

  addInt16({int v, bool bigEndian = true}) {
    grow();
    _view.setInt16(_writePos, v, bigEndian ? Endian.big : Endian.little);
    _writePos += 2;
  }

  addInt32({int v, bool bigEndian = true}) {
    grow();
    _view.setInt32(_writePos, v, bigEndian ? Endian.big : Endian.little);
    _writePos += 4;
  }

  addInt64({int v, bool bigEndian = true}) {
    grow();
    _view.setInt64(_writePos, v, bigEndian ? Endian.big : Endian.little);
    _writePos += 8;
  }

  appendBytes(Uint8List bytes) {
    bytes.forEach((b) => addUint8(b));
  }

  int readUint8(int ofst) {
    return _view.getUint8(ofst);
  }

  int readUint16({int ofst, bool bigEndian = true}) {
    return _view.getUint16(ofst, bigEndian ? Endian.big : Endian.little);
  }

  int readUint32({int ofst, bool bigEndian = true}) {
    return _view.getUint32(ofst, bigEndian ? Endian.big : Endian.little);
  }

  int readUint64({int ofst, bool bigEndian = true}) {
    return _view.getUint64(ofst, bigEndian ? Endian.big : Endian.little);
  }

  String get utf8string {
    if (_writePos == 0) return null;
    return Utf8Decoder().convert(_buf.sublist(0, _writePos));
  }

  static Future<Buffer> random(int count) async {
    var bytes = await invokeCommon('buffer.random', [count]);
    return Buffer.fromBytes(bytes);
  }
}

class BufferReader {
  Buffer buf;
  int ofst;

  BufferReader(Buffer buf, {int ofst = 0})
      : buf = buf,
        ofst = ofst;

  BufferReader.fromBytes({@required Uint8List bytes, int ofst = 0})
      : buf = Buffer.fromBytes(bytes),
        ofst = ofst;

  int readUint8() {
    int v = buf.readUint8(ofst);
    ofst += 1;
    return v;
  }

  int readUint16LE() {
    int v = buf.readUint16(ofst: ofst, bigEndian: false);
    ofst += 2;
    return v;
  }

  int readUint32LE() {
    int v = buf.readUint32(ofst: ofst, bigEndian: false);
    ofst += 4;
    return v;
  }

  int readUint64LE() {
    int v = buf.readUint64(ofst: ofst, bigEndian: false);
    ofst += 8;
    return v;
  }

  Uint8List forward(int cnt) {
    Uint8List sub = buf._buf.sublist(ofst, ofst + cnt);
    ofst += cnt;
    return sub;
  }

  advance(int cnt) {
    ofst += cnt;
  }

  BufferReader branch(int ofst) {
    return BufferReader(buf, ofst: ofst);
  }

  bool get isEnd {
    assert(ofst <= buf._buf.lengthInBytes);
    return ofst == buf._buf.lengthInBytes;
  }
}
