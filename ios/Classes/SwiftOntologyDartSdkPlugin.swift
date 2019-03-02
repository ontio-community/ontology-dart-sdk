import Flutter
import UIKit

public class SwiftOntologyDartSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ontology_dart_sdk", binaryMessenger: registrar.messenger())
    let instance = SwiftOntologyDartSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let agents: [OpAgent] = [CryptoAgent(), CommonAgent()]
    for agent in agents {
      if agent.name == call.method {
        agent.process(args: call.arguments as! [Any], cb: result)
        return
      }
    }
    result(FlutterMethodNotImplemented)
  }
}
