//
//  CryptoAgent.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation

class CryptoAgent: OpAgent {
  let name = "crypto"

  func process(args: [Any], cb: (Any?) -> Void) {
    let op = args[0] as! String
    switch op {
    case "scrypt.encrypt":
      let password = args[1] as! FlutterStandardTypedData
      let salt = args[2] as! FlutterStandardTypedData
      let params = args[3] as! NSDictionary
      let res = try! Scrypt.encrypt(password: password.data, salt: salt.data, params: params)
      cb(FlutterStandardTypedData(bytes: res))
    case "aes256gcm.encrypt":
      let msg = args[1] as! FlutterStandardTypedData
      let key = args[2] as! FlutterStandardTypedData
      let iv = args[3] as! FlutterStandardTypedData
      let auth = args[4] as! FlutterStandardTypedData
      let res = try! AES.encrypt(msg: msg.data, key: key.data, iv: iv.data, auth: auth.data)
      cb(FlutterStandardTypedData(bytes: res))
    case "aes256gcm.decrypt":
      let encrypted = args[1] as! FlutterStandardTypedData
      let key = args[2] as! FlutterStandardTypedData
      let iv = args[3] as! FlutterStandardTypedData
      let auth = args[4] as! FlutterStandardTypedData
      let res = try! AES.decrypt(encrypted: encrypted.data, key: key.data, iv: iv.data, auth: auth.data)
      cb(FlutterStandardTypedData(bytes: res))
    case "hash.compute":
      let data = args[1] as! Data
      let sigSchema = try! SignatureScheme.from(args[2] as! String)
      let res = try! Hash.compute(data: data, algo: sigSchema.hashAlgo)
      cb(FlutterStandardTypedData(bytes: res))
    case "base58.encode":
      let data = args[1] as! FlutterStandardTypedData
      cb(Base58.encode(data: data.data))
    case "base58.decode":
      let base58 = args[1] as! String
      let res = Base58.decode(base58: base58)!
      cb(FlutterStandardTypedData(bytes: res))
    default:
      cb(FlutterMethodNotImplemented)
    }
  }
}
