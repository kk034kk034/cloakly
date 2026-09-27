import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AudioEncodeBridge") {
      AudioEncodeBridge.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceIdBridge") {
      let channel = FlutterMethodChannel(
        name: "cloakly/device", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "getDeviceId" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let id = UIDevice.current.identifierForVendor?.uuidString, !id.isEmpty else {
          result(
            FlutterError(
              code: "device_id_unavailable", message: "無法讀取這支手機的識別", details: nil))
          return
        }
        result("ios:\(id)")
      }
    }
  }
}
