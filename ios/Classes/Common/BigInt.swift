//
//  BigInt.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation

import Foundation
import GMP

public class BigIntAgent: OpAgent {
  let name = "bigint"

  public func process(args: [Any], cb: FlutterResult) {
    let op = args[0] as! String
    switch op {
    case "strToInt":
      let val = args[1] as! String
      let bn = BigInt(val)
      cb(bn.int64)
    case "strToBytes":
      let val = args[1] as! String
      let bn = BigInt(val)
      cb(bn.bytes)
    case "abs":
      let val = args[1] as! String
      let bn = BigInt(val)
      cb(BigInt.abs(bn).description)
    case "neg":
      let val = args[1] as! String
      let bn = BigInt(val)
      cb(BigInt.neg(bn).description)
    case "add":
      let a = args[1] as! String
      let b = args[2] as! String
      cb(BigInt.add(BigInt(a), BigInt(b)).description)
    case "sub":
      let a = args[1] as! String
      let b = args[2] as! String
      cb(BigInt.sub(BigInt(a), BigInt(b)).description)
    case "cmp":
      let a = args[1] as! String
      let b = args[2] as! String
      cb(BigInt.cmp(BigInt(a), BigInt(b)).description)
    case "mul":
      let a = args[1] as! String
      let b = args[2] as! String
      cb(BigInt.mul(BigInt(a), BigInt(b)).description)
    case "div":
      let a = args[1] as! String
      let b = args[2] as! String
      cb(BigInt.div(BigInt(a), BigInt(b)).description)
    case "bytesToStr":
      let val = args[1] as! FlutterStandardTypedData
      cb(BigInt(val.data).description)
    default:
      cb(FlutterMethodNotImplemented)
    }
  }
}

// ref https://github.com/NeoTeo/SwiftGMP/blob/master/GMPInteger.swift
public class BigInt: CustomStringConvertible, Codable {
  public private(set) var m: mpz_t

  public init() {
    m = mpz_t()
    __gmpz_init(&m)
  }

  public convenience init(_ x: Int) {
    self.init()

    let y = CLong(x)
    if Int(y) == x {
      __gmpz_set_si(&m, y)
    } else {
      var negative = false
      var nx = x
      if x < 0 {
        nx = -x
        negative = true
      }

      __gmpz_import(&m, 1, 0, 8, 0, 0, &nx)
      if negative {
        __gmpz_neg(&m, &m)
      }
    }
  }

  public convenience init(_ buffer: [UInt8]) {
    self.init(0)
    var b = buffer
    if !buffer.isEmpty {
      __gmpz_import(&m, size_t(buffer.count), 1, 1, 1, 0, &b)
    }
  }

  public convenience init(_ buffer: Data) {
    self.init(0)
    var b = buffer
    b.withUnsafeMutableBytes { __gmpz_import(&m, size_t(buffer.count), 1, 1, 1, 0, $0) }
  }

  public convenience init(_ str: String) {
    self.init()
    __gmpz_set_str(&m, (str as NSString).utf8String, 10)
  }

  public required convenience init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    self.init(str)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(toString(base: 10))
  }

  deinit {
    __gmpz_clear(&m)
  }

  public func toString(base: Int) -> String {
    let p = __gmpz_get_str(nil, CInt(base), &m)
    let s = String(cString: p!)
    return s
  }

  public var description: String {
    return toString(base: 10)
  }

  public var sign: Int {
    if m._mp_size < 0 {
      return -1
    }
    return Int(m._mp_size)
  }

  public var bitLen: Int {
    if sign == 0 {
      return 0
    }
    return Int(__gmpz_sizeinbase(&m, 2))
  }

  public var int64: Int? {
    if __gmpz_fits_slong_p(&m) != 0 {
      return Int(__gmpz_get_si(&m))
    }

    if bitLen > 64 { return nil }

    var newInt64 = Int()
    __gmpz_export(&newInt64, nil, -1, 8, 0, 0, &m)
    if sign < 0 {
      newInt64 = -newInt64
    }
    return newInt64
  }

  public var bytes: Data {
    let size = 1
    let bitsPerWord = size * 8
    let count = 1 + ((bitLen + bitsPerWord - 1) / bitsPerWord)
    var b = [UInt8](repeating: UInt8(0), count: count)
    __gmpz_export(&b, nil, -1, size, 0, 0, &m)
    return Data(bytes: b)
  }

  public static func abs(_ x: BigInt) -> BigInt {
    let a = x
    let c = BigInt() // self
    __gmpz_abs(&c.m, &a.m)
    return c
  }

  public static func neg(_ x: BigInt) -> BigInt {
    let a = x
    let c = BigInt() // self
    __gmpz_neg(&c.m, &a.m)
    return c
  }

  public static func add(_ x: BigInt, _ y: BigInt) -> BigInt {
    let a = x
    let b = y
    let c = BigInt() // self
    __gmpz_add(&c.m, &a.m, &b.m)
    return c
  }

  public static func sub(_ x: BigInt, _ y: BigInt) -> BigInt {
    let a = x
    let b = y
    let c = BigInt() // self
    __gmpz_sub(&c.m, &a.m, &b.m)
    return c
  }

  // Cmp compares x and y and returns:
  //
  //   -1 if x <  y
  //    0 if x == y
  //   +1 if x >  y
  public static func cmp(_ number: BigInt, _ y: BigInt) -> Int {
    let xl = number // self
    let yl = y
    var r = Int(__gmpz_cmp(&xl.m, &yl.m))
    if r < 0 {
      r = -1
    } else if r > 0 {
      r = 1
    }
    return r
  }

  public static func mul(_ x: BigInt, _ y: BigInt) -> BigInt {
    let a = x
    let b = y
    let c = BigInt() // self
    __gmpz_mul(&c.m, &a.m, &b.m)
    return c
  }

  public static func div(_ x: BigInt, _ y: BigInt) -> BigInt {
    let xl = x
    let yl = y
    let zl = BigInt() // self

    switch yl.sign {
    case 1:
      __gmpz_fdiv_q(&zl.m, &xl.m, &yl.m)
    case -1:
      __gmpz_cdiv_q(&zl.m, &xl.m, &yl.m)
    default:
      fatalError("Division by zero")
    }
    return zl
  }
}

extension BigInt: Equatable, Comparable {
  public static func + (_ a: BigInt, _ b: BigInt) -> BigInt {
    return BigInt.add(a, b)
  }

  public static func - (_ a: BigInt, _ b: BigInt) -> BigInt {
    return BigInt.sub(a, b)
  }

  public static func * (_ a: BigInt, _ b: BigInt) -> BigInt {
    return BigInt.mul(a, b)
  }

  public static func / (_ a: BigInt, _ b: BigInt) -> BigInt {
    return BigInt.div(a, b)
  }

  public static func == (_ a: BigInt, _ b: BigInt) -> Bool {
    return BigInt.cmp(a, b) == 0 ? true : false
  }

  public static func < (_ a: BigInt, _ b: BigInt) -> Bool {
    return BigInt.cmp(a, b) < 0 ? true : false
  }
}
