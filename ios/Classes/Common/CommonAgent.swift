//
//  CommonAgent.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/27.
//

import Foundation

public class CommonAgent: OpAgent {
  let name = "common"

  public func process(args: [Any], cb: FlutterResult) {
    let op = args[0] as! String
    switch op {
    case "buffer.random":
      let cnt = args[1] as! Int
      var buf = Data(count: cnt)
      let res = buf.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, cnt, $0)
      }
      assert(res == errSecSuccess)
      cb(buf)
    default:
      cb(FlutterMethodNotImplemented)
    }
  }
}
