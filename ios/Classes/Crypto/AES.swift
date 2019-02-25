//
//  AES.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation
import OpenSSL

public final class AES {
  public static func encryptAgent(
    msg: Any, key: Any, iv: Any, auth: Any
  ) -> FlutterStandardTypedData {
    let msg = msg as! FlutterStandardTypedData
    let key = key as! FlutterStandardTypedData
    let iv = iv as! FlutterStandardTypedData
    let auth = auth as! FlutterStandardTypedData
    let res = try! encrypt(msg: msg.data, key: key.data, iv: iv.data, auth: auth.data)
    return FlutterStandardTypedData(bytes: res)
  }

  public static func decryptAgent(
    encrypted: Any, key: Any, iv: Any, auth: Any
  ) -> FlutterStandardTypedData {
    let encrypted = encrypted as! FlutterStandardTypedData
    let key = key as! FlutterStandardTypedData
    let iv = iv as! FlutterStandardTypedData
    let auth = auth as! FlutterStandardTypedData
    let res = try! decrypt(encrypted: encrypted.data, key: key.data, iv: iv.data, auth: auth.data)
    return FlutterStandardTypedData(bytes: res)
  }

  public static func encrypt(msg: Data, key: Data, iv: Data, auth: Data) throws -> Data {
    let msg = msg as NSData
    let key = key as NSData
    let iv = iv as NSData
    let auth = auth as NSData

    var ctx = EVP_CIPHER_CTX_new()
    defer {
      EVP_CIPHER_CTX_free(ctx)
    }

    if 1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), nil, nil, nil) {
      throw Aes256GcmError.EncInitErr
    }

    if 1 != EVP_EncryptInit_ex(ctx, nil, nil, key.bytes.assumingMemoryBound(to: UInt8.self), iv.bytes.assumingMemoryBound(to: UInt8.self)) {
      throw Aes256GcmError.EncInitErr
    }

    var ciphertextLen = msg.length + Int(EVP_CIPHER_block_size(EVP_aes_256_gcm()))
    let ciphertext = NSMutableData()
    ciphertext.length = ciphertextLen

    var len: Int32 = 0
    if 1 != EVP_EncryptUpdate(ctx, nil, &len, auth.bytes.assumingMemoryBound(to: UInt8.self), Int32(auth.length)) {
      throw Aes256GcmError.EncAuthErr
    }

    if 1 != EVP_EncryptUpdate(
      ctx,
      ciphertext.mutableBytes.assumingMemoryBound(to: UInt8.self),
      &len,
      msg.bytes.assumingMemoryBound(to: UInt8.self),
      Int32(msg.length)
    ) {
      throw Aes256GcmError.EncUpdateErr
    }
    ciphertextLen = Int(len)

    if 1 != EVP_EncryptFinal_ex(ctx, ciphertext.mutableBytes.assumingMemoryBound(to: UInt8.self).advanced(by: Int(len)), &len) {
      throw Aes256GcmError.EncFinalErr
    }
    ciphertextLen += Int(len)
    ciphertext.length = ciphertextLen

    let tag = NSMutableData()
    tag.length = 16

    if 1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag.mutableBytes) {
      throw Aes256GcmError.EncTagErr
    }

    var ret = Data()
    ret.append(ciphertext as Data)
    ret.append(tag as Data)

    return ret
  }

  public static func decrypt(encrypted: Data, key: Data, iv: Data, auth: Data) throws -> Data {
    let cipher = encrypted.subdata(in: 0 ..< encrypted.count - 16) as NSData
    let tag = encrypted.subdata(in: encrypted.count - 16 ..< encrypted.count) as NSData
    let key = key as NSData
    let iv = iv as NSData
    let auth = auth as NSData

    var ctx = EVP_CIPHER_CTX_new()
    defer {
      EVP_CIPHER_CTX_free(ctx)
    }

    if 1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nil, nil, nil) {
      throw Aes256GcmError.DecInitErr
    }

    if 1 != EVP_DecryptInit_ex(ctx, nil, nil, key.bytes.assumingMemoryBound(to: UInt8.self), iv.bytes.assumingMemoryBound(to: UInt8.self)) {
      throw Aes256GcmError.DecInitErr
    }

    var len: Int32 = 0
    if 1 != EVP_DecryptUpdate(ctx, nil, &len, auth.bytes.assumingMemoryBound(to: UInt8.self), Int32(auth.length)) {
      throw Aes256GcmError.DecAuthErr
    }

    let plaintext = NSMutableData()
    plaintext.length = encrypted.count

    if 1 != EVP_DecryptUpdate(
      ctx,
      plaintext.mutableBytes.assumingMemoryBound(to: UInt8.self),
      &len,
      cipher.bytes.assumingMemoryBound(to: UInt8.self),
      Int32(cipher.length)
    ) {
      throw Aes256GcmError.DecUpdateErr
    }

    plaintext.length = Int(len)

    if 1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, UnsafeMutableRawPointer(mutating: tag.bytes)) {
      throw Aes256GcmError.DecTagErr
    }

    if 1 != EVP_DecryptFinal_ex(ctx, plaintext.mutableBytes.assumingMemoryBound(to: UInt8.self).advanced(by: Int(len)), &len) {
      throw Aes256GcmError.DecFinalErr
    }

    return plaintext as Data
  }
}

public enum Aes256GcmError: Error {
  case EncInitErr, EncAuthErr, EncUpdateErr, EncFinalErr, EncTagErr
  case DecInitErr, DecAuthErr, DecUpdateErr, DecFinalErr, DecTagErr
}
