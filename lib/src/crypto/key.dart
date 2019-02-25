import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../constant.dart';
import 'curve.dart';
import 'key_type.dart';

class Key {
  KeyType algorithm;
  KeyParameters parameters;
  Uint8List raw;

  Key({@required Uint8List raw, KeyType algorithm, KeyParameters parameters})
      : raw = raw,
        algorithm = algorithm,
        parameters = parameters {
    if (algorithm == null) {
      this.algorithm = KeyType.from(Constant.defaultAlgorithm['algorithm']);
    }
    if (parameters == null) {
      this.parameters = KeyParameters.fromCurve(
          Constant.defaultAlgorithm['parameters']['curve']);
    }
  }
}

class KeyParameters {
  Curve curve;

  KeyParameters(Curve curve) : curve = curve;

  KeyParameters.fromCurve(String curve) : curve = Curve.fromLabel(curve);

  KeyParameters.fromJson(Map<String, dynamic> json)
      : this.fromCurve(json['curve']);

  Map<String, dynamic> toJson() => {'curve': curve.label};
}
