//
//  Scrypt.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation
import Flutter
import Scrypt

public final class Scrypt {
  public static func encryptAgent(password: Any, salt: Any, params: Any) -> FlutterStandardTypedData {
    let password = password as! FlutterStandardTypedData
    let salt = salt as! FlutterStandardTypedData
    let params = params as! NSDictionary
    let res = try! encrypt(password: password.data, salt: salt.data, params: params)
    return FlutterStandardTypedData(bytes: res)
  }

  public static func encrypt(
    password: Data,
    salt: Data,
    params: NSDictionary
  ) throws -> Data {
    let n = params["n"] as! Int
    let r = params["r"] as! Int
    let p = params["p"] as! Int
    let dkLen = params["dkLen"] as! Int
    var buf = [UInt8](repeating: 0, count: dkLen)
    let pass = password as NSData
    let salt = salt as NSData
    let ret = libscrypt_scrypt(
      pass.bytes.assumingMemoryBound(to: UInt8.self),
      pass.length,
      salt.bytes.assumingMemoryBound(to: UInt8.self),
      salt.length,
      UInt64(n),
      UInt32(r),
      UInt32(p),
      &buf,
      dkLen
    )
    if ret != 0 {
      throw ScryptError.fail2Encrypt
    }
    return Data(bytes: buf)
  }
}

public enum ScryptError: Error {
  case fail2Encrypt
}
