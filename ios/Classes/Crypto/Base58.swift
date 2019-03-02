//
//  Base58.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation
import Base58

/// ref https://github.com/pixelspark/base58

public func encryptSHA256(_ digest: UnsafeMutableRawPointer?, _ data: UnsafeRawPointer?, _ size: Int) -> Bool {
  if let data = data, let digest = digest {
    let d = Data(bytes: data, count: size)
    let dd = _Hash.sha256(d)

    dd.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
      memcpy(digest, UnsafeRawPointer(bytes), dd.count)
    }
    return true
  }
  return false
}

// Set the sha256 implementation at initialization time
let setSHA256Implementation: Void = {
  b58_sha256_impl = encryptSHA256
}()

public final class Base58 {
  public static func encode(data: Data) -> String {
    let count = data.count
    var mult = 2
    while true {
      var enc = Data(repeating: 0, count: count * mult)

      let s = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> String? in
        var size = enc.count
        let success = enc.withUnsafeMutableBytes { ptr -> Bool in
          b58enc(UnsafeMutablePointer<Int8>(ptr), &size, bytes, count)
        }

        if success {
          return String(data: enc.subdata(in: 0 ..< (size - 1)), encoding: .utf8)!
        } else {
          return nil
        }
      }

      if let s = s {
        return s
      }

      mult += 1
    }
  }

  public static func decode(base58: String) -> Data? {
    let source = base58.data(using: .utf8)!

    var bin = [UInt8](repeating: 0, count: source.count)

    var size = bin.count
    let success = source.withUnsafeBytes { (sourceBytes: UnsafePointer<CChar>) -> Bool in
      if b58tobin(&bin, &size, sourceBytes, source.count) {
        return true
      }
      return false
    }

    if success {
      return Data(bytes: bin[(bin.count - size) ..< bin.count])
    }
    return nil
  }
}
