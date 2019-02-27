//
//  Curve.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/26.
//

import Foundation
import OpenSSL

public enum Curve: CustomStringConvertible {
  case p224, p256, p384, p521, sm2p256v1, ed25519

  var label: String {
    switch self {
    case .p224: return "P-224"
    case .p256: return "P-256"
    case .p384: return "P-384"
    case .p521: return "P-521"
    case .sm2p256v1: return "sm2p256v1"
    case .ed25519: return "ed25519"
    }
  }

  var value: Int {
    switch self {
    case .p224: return 1
    case .p256: return 2
    case .p384: return 3
    case .p521: return 4
    case .sm2p256v1: return 20
    case .ed25519: return 25
    }
  }

  public var description: String {
    return label
  }

  /// see https://www.ietf.org/rfc/rfc5480.txt section 2.1.1.1. Named Curve
  ///
  /// for NID_X9_62_prime256v1 see:
  /// https://stackoverflow.com/questions/41950056/openssl1-1-0-b-is-not-support-secp256r1openssl-ecparam-list-curves
  var preset: Int32 {
    switch self {
    case .p224: return NID_secp224r1
    case .p256: return NID_X9_62_prime256v1
    case .p384: return NID_secp384r1
    case .p521: return NID_secp521r1
    case .sm2p256v1: return NID_sm2
    case .ed25519: return NID_ED25519
    }
  }

  public static func from(_ label: String) throws -> Curve {
    switch label {
    case "P-224": return .p224
    case "P-256": return .p256
    case "P-384": return .p384
    case "P-521": return .p521
    case "sm2p256v1": return .sm2p256v1
    case "ed25519": return .ed25519
    default:
      throw CurveError.invalidLabel
    }
  }

  public static func from(_ value: Int) throws -> Curve {
    switch value {
    case 1: return .p224
    case 2: return .p256
    case 3: return .p384
    case 4: return .p521
    case 20: return .sm2p256v1
    case 25: return .ed25519
    default:
      throw CurveError.invalidValue
    }
  }
}

public enum CurveError: Error {
  case invalidLabel
  case invalidValue
}
