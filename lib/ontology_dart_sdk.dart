import 'dart:async';

import 'package:flutter/services.dart';

class OntologyDartSdk {
  static const MethodChannel _channel =
      const MethodChannel('ontology_dart_sdk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
