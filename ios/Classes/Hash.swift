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

  public static func compute(msg: String, algo: OpaquePointer) throws -> Data {
    return try compute(data: msg.data(using: .utf8)!, algo: algo)
  }

  public static func sha256(data: Data) throws -> Data {
    return try compute(data: data, algo: EVP_sha256())
  }

  public static func sha256sha256(data: Data) throws -> Data {
    return try sha256(data: sha256(data: data))
  }
}

public enum HashError: Error {
  case internalErr
}
