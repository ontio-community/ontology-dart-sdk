//
//  Signature.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/26.
//

import Foundation
import OpenSSL

let kDefaultSm2Id = "1234567812345678".data(using: .utf8)!

public class Signature {
  public let r: Data
  public let s: Data
  public let algorithm: SignatureScheme

  public init(r: Data, s: Data, scheme: SignatureScheme) {
    self.r = r
    self.s = s
    algorithm = scheme
  }

  public var bytes: Data {
    var buf = Data()
    buf.append(UInt8(algorithm.value))
    if algorithm == .sm2Sm3 {
      buf.append(kDefaultSm2Id)
      buf.append(UInt8(0))
    }
    buf.append(r)
    buf.append(s)
    return buf
  }

  public var hexEncoded: String {
    return bytes.hexEncoded
  }

  public static func from(raw: Data) throws -> Signature {
    let buf = raw
    let algo = SignatureScheme(rawValue: Int(buf[0]))!
    var rs = buf.subdata(in: 1 ..< buf.count)
    if algo == .sm2Sm3 {
      guard let idx = rs.firstIndex(of: 0) else {
        throw SignatureError.deformedSm2Sig
      }
      if !rs.subdata(in: 0 ..< idx).elementsEqual(kDefaultSm2Id) {
        throw SignatureError.deformedSm2Sig
      }
      rs = rs.subdata(in: (idx + 1) ..< rs.count)
    }
    let r = rs.subdata(in: 0 ..< 32)
    let s = rs.subdata(in: 32 ..< rs.count)
    return Signature(r: r, s: s, scheme: algo)
  }

  public static func from(hex: String) throws -> Signature {
    let raw = Data.from(hex: hex)!
    return try from(raw: raw)
  }
}

public enum SignatureError: Error {
  case deformedSm2Sig
}

public final class Eddsa {
  public static func pub(pri: Data) -> Data {
    var pub = Data(count: 32)
    pri.withUnsafeBytes { (priPtr: UnsafePointer<UInt8>) -> Void in
      pub.withUnsafeMutableBytes { (pubPtr: UnsafeMutablePointer<UInt8>) -> Void in
        ED25519_public_from_private(pubPtr, priPtr)
      }
    }
    return pub
  }

  public static func sign(msg: Data, pub: Data, pri: Data) -> Signature {
    var sig = Data(count: 64)
    msg.withUnsafeBytes { (msgPtr: UnsafePointer<UInt8>) -> Void in
      pub.withUnsafeBytes { (pubPtr: UnsafePointer<UInt8>) -> Void in
        pri.withUnsafeBytes { (priPtr: UnsafePointer<UInt8>) -> Void in
          sig.withUnsafeMutableBytes { (sigPtr: UnsafeMutablePointer<UInt8>) -> Void in
            ED25519_sign(sigPtr, msgPtr, msg.count, pubPtr, priPtr)
          }
        }
      }
    }
    let r = sig.subdata(in: 0 ..< 32)
    let s = sig.subdata(in: 32 ..< sig.count)
    return Signature(r: r, s: s, scheme: SignatureScheme.eddsaSha512)
  }

  public static func verify(msg: Data, sig: Signature, pub: Data) -> Bool {
    var ok: Int32 = 0
    var sr = Data()
    sr.append(sig.r)
    sr.append(sig.s)
    msg.withUnsafeBytes { (msgPtr: UnsafePointer<UInt8>) -> Void in
      sr.withUnsafeBytes { (sigPtr: UnsafePointer<UInt8>) -> Void in
        pub.withUnsafeBytes { (pubPtr: UnsafePointer<UInt8>) -> Void in
          ok = ED25519_verify(msgPtr, msg.count, sigPtr, pubPtr)
        }
      }
    }
    return ok == 1
  }
}

/// Wrapper of BIGNUM*
public final class BN: Equatable, Comparable {
  public fileprivate(set) var raw: OpaquePointer?

  public init(raw: OpaquePointer?) {
    self.raw = raw
  }

  public func toHex() -> String {
    let hexCStr = BN_bn2hex(raw)
    let hexStr = String(cString: hexCStr!)
    CRYPTO_free(hexCStr, #file, #line)
    return hexStr
  }

  public static func cmp(_ a: BN, _ b: BN) -> Int {
    return Int(BN_cmp(a.raw, b.raw))
  }

  public static func == (_ a: BN, _ b: BN) -> Bool {
    return BN.cmp(a, b) == 0 ? true : false
  }

  public static func < (_ a: BN, _ b: BN) -> Bool {
    return BN.cmp(a, b) < 0 ? true : false
  }
}

/// Wrapper of EVP_PKEY*
public final class PKey {
  public fileprivate(set) var raw: OpaquePointer?

  public init(raw: OpaquePointer?) {
    self.raw = raw
  }

  deinit {
    if let ptr = raw {
      EVP_PKEY_free(ptr)
      raw = nil
    }
  }

  public enum PubMode {
    case uncompress, compress, mix
  }

  public func pub(mode: PubMode) -> Data {
    let eckey = EVP_PKEY_get0_EC_KEY(raw)
    let pubpnt = EC_KEY_get0_public_key(eckey)

    var form: point_conversion_form_t
    switch mode {
    case .uncompress: form = POINT_CONVERSION_UNCOMPRESSED
    case .compress: form = POINT_CONVERSION_COMPRESSED
    case .mix: form = POINT_CONVERSION_HYBRID
    }

    var group = EC_GROUP_dup(EC_KEY_get0_group(eckey))
    defer {
      EC_GROUP_free(group)
    }

    var pbuf: UnsafeMutablePointer<UInt8>?
    let len = EC_POINT_point2buf(group, pubpnt, form, &pbuf, nil)
    return Data(bytesNoCopy: pbuf!, count: len, deallocator: .free)
  }

  public var pubxy: (x: BN, y: BN) {
    let eckey = EVP_PKEY_get0_EC_KEY(raw)
    let pubpnt = EC_KEY_get0_public_key(eckey)
    let group = EC_GROUP_dup(EC_KEY_get0_group(eckey))
    let x = BN_new()
    let y = BN_new()
    EC_POINT_get_affine_coordinates_GFp(group, pubpnt, x, y, nil)
    return (BN(raw: x), BN(raw: y))
  }

  public func pri() -> Data {
    let eckey = EVP_PKEY_get0_EC_KEY(raw)
    let k = EC_KEY_get0_private_key(eckey)
    let len = (BN_num_bits(k) + 7) / 8
    let ret = NSMutableData()
    ret.length = Int(len)
    BN_bn2bin(k, ret.mutableBytes.assumingMemoryBound(to: UInt8.self))
    return ret as Data
  }

  public func sign(msg: Data, scheme: SignatureScheme) throws -> Signature {
    let msg = msg as NSData

    var mdctx = EVP_MD_CTX_new()
    defer {
      EVP_MD_CTX_free(mdctx)
    }

    let isSm2 = scheme == .sm2Sm3
    var pkctx: OpaquePointer?
    defer {
      if let ptr = pkctx {
        EVP_PKEY_CTX_free(ptr)
      }
    }

    if isSm2 {
      EVP_PKEY_set_alias_type(raw, EVP_PKEY_SM2)

      pkctx = EVP_PKEY_CTX_new(raw, nil)

      kDefaultSm2Id.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Void in
        EVP_PKEY_CTX_ctrl(pkctx, -1, -1, EVP_PKEY_CTRL_SET1_ID, Int32(kDefaultSm2Id.count), UnsafeMutableRawPointer(mutating: ptr))
      }

      EVP_MD_CTX_set_pkey_ctx(mdctx, pkctx)
    }

    if 1 != EVP_DigestSignInit(mdctx, nil, scheme.hashAlgo, nil, raw) {
      throw PKeyError.signInit
    }

    if 1 != EVP_DigestUpdate(mdctx, msg.bytes, msg.length) {
      throw PKeyError.signUpdate
    }

    var sigbuf = NSMutableData()
    sigbuf.length = Int(EVP_PKEY_size(raw))
    var siglen = sigbuf.length
    if 1 != EVP_DigestSignFinal(mdctx, sigbuf.mutableBytes.assumingMemoryBound(to: UInt8.self), &siglen) {
      throw PKeyError.signFinal
    }

    var sigbufptr: UnsafePointer<UInt8>? = sigbuf.bytes.assumingMemoryBound(to: UInt8.self)
    var sig = d2i_ECDSA_SIG(nil, &sigbufptr, Int(siglen))
    defer {
      ECDSA_SIG_free(sig)
    }

    let r = ECDSA_SIG_get0_r(sig)
    let s = ECDSA_SIG_get0_s(sig)
    let rlen = (BN_num_bits(r) + 7) / 8
    let slen = (BN_num_bits(s) + 7) / 8

    var rbuf = Data(count: Int(rlen))
    rbuf.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) -> Void in
      BN_bn2bin(r, ptr)
    }

    var sbuf = Data(count: Int(slen))
    sbuf.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) -> Void in
      BN_bn2bin(s, ptr)
    }

    return Signature(r: rbuf, s: sbuf, scheme: scheme)
  }

  public func verify(msg: Data, sig: Signature) throws -> Bool {
    let msg = msg as NSData

    var r = sig.r.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> OpaquePointer in
      BN_bin2bn(ptr, Int32(sig.r.count), nil)
    }

    var s = sig.s.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> OpaquePointer in
      BN_bin2bn(ptr, Int32(sig.s.count), nil)
    }

    var si = ECDSA_SIG_new()
    defer {
      ECDSA_SIG_free(si)
    }

    ECDSA_SIG_set0(si, r, s)

    var sigdlen = EVP_PKEY_size(raw)
    var sigd = malloc(Int(sigdlen))
    defer {
      free(sigd)
    }

    var sigdptr = sigd?.assumingMemoryBound(to: UInt8.self)
    sigdlen = i2d_ECDSA_SIG(si, &sigdptr)

    var mdctx = EVP_MD_CTX_new()
    defer {
      EVP_MD_CTX_free(mdctx)
    }

    let isSm2 = sig.algorithm == .sm2Sm3
    var pkctx: OpaquePointer?
    defer {
      if let ptr = pkctx {
        EVP_PKEY_CTX_free(ptr)
      }
    }

    if isSm2 {
      EVP_PKEY_set_alias_type(raw, EVP_PKEY_SM2)

      pkctx = EVP_PKEY_CTX_new(raw, nil)

      kDefaultSm2Id.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Void in
        EVP_PKEY_CTX_ctrl(pkctx, -1, -1, EVP_PKEY_CTRL_SET1_ID, Int32(kDefaultSm2Id.count), UnsafeMutableRawPointer(mutating: ptr))
      }

      EVP_MD_CTX_set_pkey_ctx(mdctx, pkctx)
    }

    if 1 != EVP_DigestVerifyInit(mdctx, nil, sig.algorithm.hashAlgo, nil, raw) {
      throw PKeyError.verifyInit
    }

    if 1 != EVP_DigestUpdate(mdctx, msg.bytes, msg.length) {
      throw PKeyError.verifyUpdate
    }

    return EVP_DigestVerifyFinal(mdctx, sigd?.assumingMemoryBound(to: UInt8.self), Int(sigdlen)) == 1
  }
}

public enum PKeyError: Error {
  case signInit, signUpdate, signFinal, verifyInit, verifyUpdate, verifyFinal
}

public final class Ecdsa {
  /// Creates EVP_PKEY from raw private key
  ///
  /// - Parameter data: raw private key
  /// - Returns: PKey
  public static func pkey(pri: Data, curve: Int32) -> PKey {
    var ok = false
    var ret = PKey(raw: nil)

    var eckey = EC_KEY_new_by_curve_name(curve)
    defer {
      if !ok {
        EC_KEY_free(eckey)
      }
    }

    let group = EC_KEY_get0_group(eckey)
    EC_GROUP_set_asn1_flag(group, OPENSSL_EC_NAMED_CURVE)

    var pribn = pri.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> OpaquePointer in
      BN_bin2bn(ptr, Int32(pri.count), nil)
    }
    defer {
      BN_free(pribn)
    }

    if 1 != EC_KEY_set_private_key(eckey, pribn) {
      return ret
    }

    var pubpnt = EC_POINT_new(group)
    defer {
      EC_POINT_free(pubpnt)
    }

    if 1 != EC_POINT_mul(group, pubpnt, pribn, nil, nil, nil) {
      return ret
    }

    if 1 != EC_KEY_set_public_key(eckey, pubpnt) {
      return ret
    }

    var pkey = EVP_PKEY_new()
    defer {
      if !ok {
        EVP_PKEY_free(pkey)
      }
    }

    if 1 != EC_KEY_check_key(eckey) || 1 != EVP_PKEY_assign(pkey, EVP_PKEY_EC, UnsafeMutableRawPointer(eckey)) {
      return ret
    }

    ok = true
    ret.raw = pkey
    return ret
  }

  /// Creates EVP_PKEY from raw public key
  ///
  /// - Parameter data: raw public key
  /// - Returns: PKey
  public static func pkey(pub: Data, curve: Int32) -> PKey {
    var ok = false
    var ret = PKey(raw: nil)

    var eckey = EC_KEY_new_by_curve_name(curve)
    defer {
      if !ok {
        EC_KEY_free(eckey)
      }
    }

    let group = EC_KEY_get0_group(eckey)
    EC_GROUP_set_asn1_flag(group, OPENSSL_EC_NAMED_CURVE)

    var pubpnt = EC_POINT_new(group)
    pub.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Void in
      EC_POINT_oct2point(group, pubpnt, ptr, pub.count, nil)
    }
    defer {
      EC_POINT_free(pubpnt)
    }

    if 1 != EC_KEY_set_public_key(eckey, pubpnt) {
      return ret
    }

    var pkey = EVP_PKEY_new()
    defer {
      if !ok {
        EVP_PKEY_free(pkey)
      }
    }

    if 1 != EC_KEY_check_key(eckey) || 1 != EVP_PKEY_assign(pkey, EVP_PKEY_EC, UnsafeMutableRawPointer(eckey)) {
      return ret
    }

    ok = true
    ret.raw = pkey
    return ret
  }
}
