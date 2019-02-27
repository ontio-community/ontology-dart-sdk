import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../crypto/address.dart';
import '../neocore/script.dart';

class AbiParameterType {
  static AbiParameterType byteArray = AbiParameterType("ByteArray", 0x00);
  static AbiParameterType boolean = AbiParameterType("Boolean", 0x01);
  static AbiParameterType integer = AbiParameterType("Integer", 0x02);
  static AbiParameterType interface = AbiParameterType("Interface", 0x40);
  static AbiParameterType array = AbiParameterType("Array", 0x80);
  static AbiParameterType struct = AbiParameterType("Struct", 0x81);
  static AbiParameterType map = AbiParameterType("Map", 0x82);

  String name;
  int value;

  AbiParameterType(String name, int value)
      : name = name,
        value = value;

  static AbiParameterType from(String name) {
    switch (name) {
      case 'ByteArray':
        return byteArray;
      case 'Boolean':
        return boolean;
      case 'Integer':
        return integer;
      case 'Interface':
        return interface;
      case 'Array':
        return array;
      case 'Struct':
        return struct;
      case 'Map':
        return map;
      default:
        throw ArgumentError('Unsupported type: ' + name);
    }
  }
}

class AbiParameter {
  String name;
  AbiParameterType type;
  dynamic value;

  AbiParameter(String name, AbiParameterType type, dynamic value)
      : name = name,
        type = type,
        value = value;

  AbiParameter.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        type = AbiParameterType.from(json['type']),
        value = json['value'];

  Map<String, dynamic> toJson() =>
      {'name': name, 'type': type.name, 'value': value};
}

class AbiFunction {
  String name;
  List<AbiParameter> parameters = [];
  String returnType;

  AbiFunction(
      {@required String name,
      @required List<AbiParameter> parameters,
      String returnType = 'any'})
      : name = name,
        parameters = parameters,
        returnType = returnType;

  AbiFunction.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    returnType = json['returnType'];
    parameters = (json['parameters'] as List<dynamic>)
        .map((p) => AbiParameter.fromJson(p));
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'returnType': returnType, 'parameters': parameters};
}

class AbiInfo {
  String hash;
  String entryPoint;
  List<AbiFunction> functions = [];

  AbiInfo(String hash, String entryPoint)
      : hash = hash,
        entryPoint = entryPoint;

  AbiFunction getFunction(String name) {
    for (var fn in functions) {
      if (fn.name == name) return fn;
    }
    return null;
  }

  AbiInfo.fromJson(Map<String, dynamic> json) {
    hash = json['hash'];
    entryPoint = json['entryPoint'];
    functions = (json['functions'] as List<dynamic>)
        .map((p) => AbiFunction.fromJson(p));
  }

  Map<String, dynamic> toJson() =>
      {'hash': hash, 'entryPoint': entryPoint, 'functions': functions};
}

class AbiFile {
  String contractHash;
  AbiInfo abi;

  AbiFile(String contractHash, AbiInfo abi)
      : contractHash = contractHash,
        abi = abi;

  AbiFile.fromJson(Map<String, dynamic> json) {
    contractHash = json['contractHash'];
    abi = AbiInfo.fromJson(json['abi']);
  }

  Map<String, dynamic> toJson() => {'contractHash': contractHash, 'abi': abi};
}

class VmParamsBuilder extends ScriptBuilder {
  pushCodeParamScript(dynamic obj) {
    if (obj is String) {
      pushHexStr(obj);
    } else if (obj is Uint8List) {
      pushHex(obj);
    } else if (obj is bool) {
      pushBool(obj);
    } else if (obj is int) {
      pushInt(obj);
    } else if (obj is BigInt) {
      pushBigInt(obj);
    } else if (obj is Address) {
      pushAddress(obj);
    } else if (obj is Struct) {
      obj.list.forEach((x) {
        pushCodeParamScript(x);
        pushOpcode(OpCode.dupfromaltstack);
        pushOpcode(OpCode.swap);
        pushOpcode(OpCode.append);
      });
    } else {
      throw ArgumentError('Unsupported param type: ' + obj.runtimeType);
    }
  }

  pushNativeCodeScript(List<dynamic> objs) {
    for (var obj in objs) {
      if (obj is String) {
        pushHexStr(obj);
      } else if (obj is Uint8List) {
        pushHex(obj);
      } else if (obj is bool) {
        pushBool(obj);
      } else if (obj is int) {
        pushInt(obj);
      } else if (obj is BigInt) {
        pushBigInt(obj);
      } else if (obj is Struct) {
        pushInt(0);
        pushOpcode(OpCode.newstruct);
        pushOpcode(OpCode.toaltstack);
        for (var item in obj.list) {
          pushCodeParamScript(item);
          pushOpcode(OpCode.dupfromaltstack);
          pushOpcode(OpCode.swap);
          pushOpcode(OpCode.append);
        }
        pushOpcode(OpCode.fromaltstack);
      } else if (obj is List<Struct>) {
        pushInt(0);
        pushOpcode(OpCode.newstruct);
        pushOpcode(OpCode.toaltstack);
        for (var item in obj) {
          pushCodeParamScript(item);
        }
        pushOpcode(OpCode.fromaltstack);
        pushInt(obj.length);
        pushOpcode(OpCode.pack);
      } else if (obj is List<dynamic>) {
        pushCodeParamScript(obj);
        pushInt(obj.length);
        pushOpcode(OpCode.pack);
      } else {
        throw ArgumentError('Unsupported param type: ' + obj.runtimeType);
      }
    }
  }

  pushParam(dynamic param) {
    if (param is Uint8List) {
      pushHex(param);
    } else if (param is String) {
      pushStr(param);
    } else if (param is bool) {
      pushBool(param);
      pushOpcode(OpCode.push0);
      pushOpcode(OpCode.boolor);
    } else if (param is Map<String, dynamic>) {
      pushMap(param);
    } else if (param is List<dynamic>) {
      for (var item in param) {
        pushParam(item);
      }
      pushInt(param.length);
      pushOpcode(OpCode.pack);
    } else if (param is int) {
      pushInt(param);
      pushOpcode(OpCode.push0);
      pushOpcode(OpCode.add);
    } else if (param is BigInt) {
      pushBigInt(param);
      pushOpcode(OpCode.push0);
      pushOpcode(OpCode.add);
    } else {
      throw ArgumentError('Unsupported param type: ' + param.runtimeType);
    }
  }

  pushMap(Map<String, dynamic> map) {
    pushOpcode(OpCode.newmap);
    pushOpcode(OpCode.toaltstack);
    for (var kv in map.entries) {
      pushOpcode(OpCode.dupfromaltstack);
      pushStr(kv.key);
      pushParam(kv.value);
      pushOpcode(OpCode.setitem);
    }
    pushOpcode(OpCode.fromaltstack);
  }
}
