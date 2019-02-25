import 'dart:typed_data';
import 'package:flutter/services.dart';

final methodChannel = const MethodChannel('ontology_dart_sdk');

Future<dynamic> invokeBigInt(String op, List<dynamic> args) async {
  List<dynamic> params = [op];
  params.addAll(args);
  return methodChannel.invokeMethod('bigint', params);
}

class BigInt {
  String value;

  BigInt(String x) : value = x;

  BigInt.fromInt(int x) : this(x.toString());

  Future<int> toInt() async {
    return invokeBigInt('strToInt', [value]);
  }

  Future<Uint8List> toBytes() async {
    return invokeBigInt('strToBytes', [value]);
  }

  Future<BigInt> abs() async {
    return BigInt(await invokeBigInt('abs', [value]));
  }

  Future<BigInt> neg() async {
    return BigInt(await invokeBigInt('neg', [value]));
  }

  Future<BigInt> add(BigInt x) async {
    return BigInt(await invokeBigInt('add', [value, x.value]));
  }

  Future<BigInt> sub(BigInt x) async {
    return BigInt(await invokeBigInt('sub', [value, x.value]));
  }

  Future<int> cmp(BigInt x) async {
    return await invokeBigInt('cmp', [value, x.value]);
  }

  Future<BigInt> mul(BigInt x) async {
    return BigInt(await invokeBigInt('mul', [value, x.value]));
  }

  Future<BigInt> div(BigInt x) async {
    return BigInt(await invokeBigInt('div', [value, x.value]));
  }

  static Future<BigInt> fromBytes(Uint8List bytes) async {
    return BigInt(await invokeBigInt('bytesToStr', [bytes]));
  }
}
