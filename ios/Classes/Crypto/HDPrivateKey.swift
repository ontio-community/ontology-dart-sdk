//
//  DeterministicKey.swift
//
//  Copyright © 2018 Kishikawa Katsumi
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public class HDPrivateKey {
  public let depth: UInt8
  public let fingerprint: UInt32
  public let childIndex: UInt32

  let raw: Data
  let chainCode: Data

  public init(privateKey: Data, chainCode: Data) {
    raw = privateKey
    self.chainCode = chainCode
    depth = 0
    fingerprint = 0
    childIndex = 0
  }

  public convenience init(seed: Data) {
    let hmac = _Hash.hmacsha512(seed, key: "Nist256p1 seed".data(using: .ascii)!)
    let privateKey = hmac[0 ..< 32]
    let chainCode = hmac[32 ..< 64]
    self.init(privateKey: privateKey, chainCode: chainCode)
  }

  init(privateKey: Data, chainCode: Data, depth: UInt8, fingerprint: UInt32, childIndex: UInt32) {
    raw = privateKey
    self.chainCode = chainCode
    self.depth = depth
    self.fingerprint = fingerprint
    self.childIndex = childIndex
  }

  private func computePublicKeyData() -> Data {
    return _Key.computePublicKey(fromPrivateKey: raw, compression: true)
  }

  public func derived(at index: UInt32, hardened: Bool = false) throws -> HDPrivateKey {
    // As we use explicit parameter "hardened", do not allow higher bit set.
    if (0x8000_0000 & index) != 0 {
      fatalError("invalid child index")
    }

    guard let derivedKey = _HDKey(privateKey: raw, publicKey: computePublicKeyData(), chainCode: chainCode, depth: depth, fingerprint: fingerprint, childIndex: childIndex).derived(at: index, hardened: hardened) else {
      throw DerivationError.derivationFailed
    }
    return HDPrivateKey(privateKey: derivedKey.privateKey!, chainCode: derivedKey.chainCode, depth: derivedKey.depth, fingerprint: derivedKey.fingerprint, childIndex: derivedKey.childIndex)
  }
}

public enum DerivationError: Error {
  case derivationFailed
}
