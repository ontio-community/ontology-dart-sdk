import 'package:flutter/services.dart';

final methodChannel = const MethodChannel('ontology_dart_sdk');

Future<dynamic> invokeCommon(String op, List<dynamic> args) async {
  List<dynamic> params = [op];
  params.addAll(args);
  return methodChannel.invokeMethod('common', params);
}
