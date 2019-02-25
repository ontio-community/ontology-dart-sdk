//
//  OpAgent.swift
//  ontology_dart_sdk
//
//  Created by hsiaosiyuan on 2019/2/25.
//

import Foundation
import Flutter

protocol OpAgent {
  var name: String { get }
  func process(args: [Any], cb: FlutterResult)
}
