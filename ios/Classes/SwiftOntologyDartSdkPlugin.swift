import Flutter
import UIKit
import GMP
import Base58
import OpenSSL
import Scrypt

public class SwiftOntologyDartSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ontology_dart_sdk", binaryMessenger: registrar.messenger())
    let instance = SwiftOntologyDartSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_: FlutterMethodCall, result: @escaping FlutterResult) {
    var m = mpz_t()
    __gmpz_init(&m)
    print(m)
    print(b58enc)
    result("iOS " + UIDevice.current.systemVersion)
  }
}
