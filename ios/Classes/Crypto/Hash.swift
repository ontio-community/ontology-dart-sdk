//
//  Hash.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation
import OpenSSL

public final class Hash {
  public static func compute(data: Data, algo: OpaquePointer) throws -> Data {
    let nsData = data as NSData
    let ctx = EVP_MD_CTX_new()

    if ctx == nil {
      throw HashError.internalErr
    }

    if 1 != EVP_DigestInit_ex(ctx, algo, nil) {
      throw HashError.internalErr
    }

    if 1 != EVP_DigestUpdate(ctx, nsData.bytes, nsData.length) {
      throw HashError.internalErr
    }

    let digest_len = Int(EVP_MD_size(algo))
    var digest = [UInt8](repeating: 0, count: digest_len)

    if 1 != EVP_DigestFinal_ex(ctx, &digest, nil) {
      throw HashError.internalErr
    }

    return Data(bytes: &digest, count: digest_len)
  }
}

public enum HashError: Error {
  case internalErr
}
