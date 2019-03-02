//
//  SignatureScheme.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation
import OpenSSL

public enum SignatureScheme: Int {
  case ecdsaSha224, ecdsaSha256, ecdsaSha384, ecdsaSha512
  case ecdsaSha3_224, ecdsaSha3_256, ecdsaSha3_384, ecdsaSha3_512
  case ecdsaRipemd160, sm2Sm3, eddsaSha512

  var value: Int {
    return rawValue
  }

  var label: String {
    switch self {
    case .ecdsaSha224: return "SHA224withECDSA"
    case .ecdsaSha256: return "SHA256withECDSA"
    case .ecdsaSha384: return "SHA384withECDSA"
    case .ecdsaSha512: return "SHA512withECDSA"
    case .ecdsaSha3_224: return "SHA3-224withECDSA"
    case .ecdsaSha3_256: return "SHA3-256withECDSA"
    case .ecdsaSha3_384: return "SHA3-384withECDSA"
    case .ecdsaSha3_512: return "SHA3-512withECDSA"
    case .ecdsaRipemd160: return "RIPEMD160withECDSA"
    case .sm2Sm3: return "SM3withSM2"
    case .eddsaSha512: return "SHA512withEdDSA"
    }
  }

  var hashAlgo: OpaquePointer {
    switch self {
    case .ecdsaSha224: return EVP_sha224()
    case .ecdsaSha256: return EVP_sha256()
    case .ecdsaSha384: return EVP_sha384()
    case .ecdsaSha512: return EVP_sha512()
    case .ecdsaSha3_224: return EVP_sha3_224()
    case .ecdsaSha3_256: return EVP_sha3_256()
    case .ecdsaSha3_384: return EVP_sha3_384()
    case .ecdsaSha3_512: return EVP_sha3_512()
    case .ecdsaRipemd160: return EVP_ripemd160()
    case .sm2Sm3: return EVP_sm3()
    case .eddsaSha512: return EVP_sha512()
    }
  }

  public static func from(_ label: String) throws -> SignatureScheme {
    switch label {
    case "SHA224withECDSA": return .ecdsaSha224
    case "SHA256withECDSA": return .ecdsaSha256
    case "SHA384withECDSA": return .ecdsaSha384
    case "SHA512withECDSA": return .ecdsaSha512
    case "SHA3-224withECDSA": return .ecdsaSha3_224
    case "SHA3-256withECDSA": return .ecdsaSha3_256
    case "SHA3-384withECDSA": return .ecdsaSha3_384
    case "SHA3-512withECDSA": return .ecdsaSha3_512
    case "RIPEMD160withECDSA": return .ecdsaRipemd160
    case "SM3withSM2": return .sm2Sm3
    case "SHA512withEdDSA": return .eddsaSha512
    default:
      throw SignatureSchemeError.invalidLabel
    }
  }
}

public enum SignatureSchemeError: Error {
  case invalidLabel
}
