import AVFoundation
import Flutter
import Foundation

enum AudioEncodeBridge {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "cloakly/audio_encode", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "encodeWavToM4a" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let inputPath = args["inputPath"] as? String,
        let outputPath = args["outputPath"] as? String
      else {
        result(
          FlutterError(code: "bad_args", message: "缺少路徑", details: nil))
        return
      }
      encodeWavToM4a(inputPath: inputPath, outputPath: outputPath, result: result)
    }
  }

  private static func encodeWavToM4a(
    inputPath: String,
    outputPath: String,
    result: @escaping FlutterResult
  ) {
    let inputURL = URL(fileURLWithPath: inputPath)
    let outputURL = URL(fileURLWithPath: outputPath)
    try? FileManager.default.removeItem(at: outputURL)

    let asset = AVURLAsset(url: inputURL)
    guard
      let session = AVAssetExportSession(
        asset: asset, presetName: AVAssetExportPresetAppleM4A)
    else {
      result(
        FlutterError(code: "encode_failed", message: "無法建立 AAC 編碼器", details: nil))
      return
    }
    session.outputURL = outputURL
    session.outputFileType = .m4a
    session.exportAsynchronously {
      DispatchQueue.main.async {
        if session.status == .completed {
          result(outputPath)
        } else {
          let message = session.error?.localizedDescription ?? "AAC 編碼失敗"
          result(
            FlutterError(code: "encode_failed", message: message, details: nil))
        }
      }
    }
  }
}
