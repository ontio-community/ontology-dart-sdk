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
      let data = args[1] as! FlutterStandardTypedData
      let sigSchema = try! SignatureScheme.from(args[2] as! String)
      let res = try! Hash.compute(data: data.data, algo: sigSchema.hashAlgo)
      cb(FlutterStandardTypedData(bytes: res))
    case "hash.sha256ripemd160":
      let data = args[1] as! FlutterStandardTypedData
      let res = _Hash.sha256ripemd160(data.data)
      cb(res)
    case "base58.encode":
      let data = args[1] as! FlutterStandardTypedData
      cb(Base58.encode(data: data.data))
    case "base58.decode":
      let base58 = args[1] as! String
      let res = Base58.decode(base58: base58)!
      cb(FlutterStandardTypedData(bytes: res))
    case "ecdsa.pubkeyXY":
      let raw = args[1] as! FlutterStandardTypedData
      let curveLabel = args[2] as! String
      let curve = try! Curve.from(curveLabel)
      let pkey = Ecdsa.pkey(pub: raw.data, curve: curve.preset)
      let (x, y) = pkey.pubxy
      let ret = [x.toHex(), y.toHex()]
      cb(ret)
    case "ecdsa.sig":
      let msg = args[1] as! FlutterStandardTypedData
      let pri = args[2] as! FlutterStandardTypedData
      let curveLabel = args[3] as! String
      let schema = args[4] as! Int
      let curve = try! Curve.from(curveLabel)
      let pkey = Ecdsa.pkey(pri: pri.data, curve: curve.preset)
      let sig = try! pkey.sign(msg: msg.data, scheme: SignatureScheme(rawValue: schema)!)
      cb(sig.bytes)
    case "eddsa.sig":
      let msg = args[1] as! FlutterStandardTypedData
      let pri = args[2] as! FlutterStandardTypedData
      let pub = Eddsa.pub(pri: pri.data)
      let sig = Eddsa.sign(msg: msg.data, pub: pub, pri: pri.data)
      cb(sig.bytes)
    case "ecdsa.pub":
      let pri = args[1] as! FlutterStandardTypedData
      let curveLabel = args[2] as! String
      let mode = args[3] as! Int
      let curve = try! Curve.from(curveLabel)
      var pubMode = PKey.PubMode.uncompress
      switch mode {
      case 1: pubMode = .compress
      case 2: pubMode = .mix
      default:
        pubMode = .uncompress
      }
      let pkey = Ecdsa.pkey(pri: pri.data, curve: curve.preset)
      let pub = pkey.pub(mode: pubMode)
      cb(pub)
    case "eddsa.pub":
      let pri = args[1] as! FlutterStandardTypedData
      let pub = Eddsa.pub(pri: pri.data)
      cb(pub)
    case "ecdsa.verify":
      let msg = args[1] as! FlutterStandardTypedData
      let sig = args[2] as! FlutterStandardTypedData
      let pub = args[3] as! FlutterStandardTypedData
      let curveLabel = args[4] as! String
      let pkey = try! Ecdsa.pkey(pub: pub.data, curve: Curve.from(curveLabel).preset)
      let sigInst = try! Signature.from(raw: sig.data)
      let ok = try! pkey.verify(msg: msg.data, sig: sigInst)
      cb(ok)
    case "eddsa.verify":
      let msg = args[1] as! FlutterStandardTypedData
      let sig = args[2] as! FlutterStandardTypedData
      let pub = args[3] as! FlutterStandardTypedData
      let sigInst = try! Signature.from(raw: sig.data)
      let ok = Eddsa.verify(msg: msg.data, sig: sigInst, pub: pub.data)
      cb(ok)
    case "prikey.fromMnemonic":
      let mn = args[1] as! String
      let path = args[2] as! String
      let mnemonic = mn.trimmingCharacters(in: .whitespacesAndNewlines)
      let seed = Mnemonic.seed(mnemonic: mnemonic.components(separatedBy: " "))
      let keychain = HDKeychain(seed: seed)
      let privateKey = try! keychain.derivedKey(path: path)
      cb(privateKey.raw)
    default:
      cb(FlutterMethodNotImplemented)
    }
  }
}
