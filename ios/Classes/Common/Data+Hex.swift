//
//  Data+Hex.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/26.
//

import Foundation

/// ref https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
public extension Data {
  struct HexOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    static let upperCase = HexOptions(rawValue: 1 << 0)
  }

  var hexEncoded: String {
    return hex()
  }

  func hex(options: HexOptions = []) -> String {
    let hexDigits = Array((options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
    var chars: [unichar] = []
    chars.reserveCapacity(2 * count)
    for byte in self {
      chars.append(hexDigits[Int(byte / 16)])
      chars.append(hexDigits[Int(byte % 16)])
    }
    return String(utf16CodeUnits: chars, count: chars.count)
  }

  /// ref https://codereview.stackexchange.com/questions/135424/hex-string-to-bytes-nsdata
  static func from(hex: String) -> Data? {
    // Convert 0 ... 9, a ... f, A ...F to their decimal value,
    // return nil for all other input characters
    func decodeNibble(u: UInt16) -> UInt8? {
      switch u {
      case 0x30 ... 0x39:
        return UInt8(u - 0x30)
      case 0x41 ... 0x46:
        return UInt8(u - 0x41 + 10)
      case 0x61 ... 0x66:
        return UInt8(u - 0x61 + 10)
      default:
        return nil
      }
    }

    let utf16 = hex.utf16
    guard let data = NSMutableData(capacity: utf16.count / 2) else {
      return nil
    }

    var i = utf16.startIndex
    while i != utf16.endIndex {
      guard let hi = decodeNibble(u: utf16[i]), let lo = decodeNibble(u: utf16[utf16.index(i, offsetBy: 1)])
      else {
        return nil
      }
      var value = hi << 4 + lo
      data.append(&value, length: 1)
      i = utf16.index(i, offsetBy: 2)
    }

    return data as Data
  }
}
