import AVFoundation
import Cocoa
import CoreMedia
import FlutterMacOS
import ScreenCaptureKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    SystemAudioBridge.register(with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

final class SystemAudioBridge: NSObject, FlutterStreamHandler, SCStreamOutput, SCStreamDelegate {
  private var eventSink: FlutterEventSink?
  private var stream: SCStream?
  private let queue = DispatchQueue(label: "com.cloakly.system-audio")
  private var converter: AVAudioConverter?
  private var outputFormat: AVAudioFormat?

  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = SystemAudioBridge()
    let methods = FlutterMethodChannel(name: "cloakly/system_audio", binaryMessenger: messenger)
    methods.setMethodCallHandler { call, result in
      if call.method == "isSupported" {
        if #available(macOS 13.0, *) {
          result(true)
        } else {
          result(false)
        }
        return
      }
      if call.method == "platformHint" {
        result("會擷取電腦正在播放的聲音。第一次請在系統設定允許「螢幕錄製」。")
        return
      }
      result(FlutterMethodNotImplemented)
    }
    let events = FlutterEventChannel(
      name: "cloakly/system_audio/pcm", binaryMessenger: messenger)
    events.setStreamHandler(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    if #available(macOS 13.0, *) {
      Task { await startCapture() }
    } else {
      events(
        FlutterError(
          code: "unsupported", message: "需要 macOS 13 以上才能擷取系統聲音。", details: nil))
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if #available(macOS 13.0, *) {
      Task { await stopCapture() }
    }
    eventSink = nil
    return nil
  }

  @available(macOS 13.0, *)
  private func startCapture() async {
    do {
      let content = try await SCShareableContent.excludingDesktopWindows(
        false, onScreenWindowsOnly: true)
      guard let display = content.displays.first else {
        emitError("找不到可用顯示器")
        return
      }
      let filter = SCContentFilter(display: display, excludingWindows: [])
      let config = SCStreamConfiguration()
      config.capturesAudio = true
      config.sampleRate = 48000
      config.channelCount = 1
      let stream = SCStream(filter: filter, configuration: config, delegate: self)
      try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: queue)
      try await stream.startCapture()
      self.stream = stream
    } catch {
      emitError(error.localizedDescription)
    }
  }

  @available(macOS 13.0, *)
  private func stopCapture() async {
    try? await stream?.stopCapture()
    stream = nil
  }

  func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard type == .audio, eventSink != nil else { return }
    guard let pcm = convert(sampleBuffer) else { return }
    let data = FlutterStandardTypedData(bytes: pcm)
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(data)
    }
  }

  private func convert(_ sampleBuffer: CMSampleBuffer) -> Data? {
    guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
      let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)
    else {
      return nil
    }
    var asbd = asbdPtr.pointee
    guard let inputFormat = AVAudioFormat(streamDescription: &asbd),
      let inputBuffer = sampleBufferToPCM(sampleBuffer, format: inputFormat)
    else {
      return nil
    }
    if outputFormat == nil {
      outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)
    }
    guard let outputFormat = outputFormat else { return nil }
    if converter == nil {
      converter = AVAudioConverter(from: inputFormat, to: outputFormat)
    }
    guard let converter = converter else { return nil }
    let ratio = outputFormat.sampleRate / inputFormat.sampleRate
    let outFrames = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio + 16)
    guard
      let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outFrames)
    else {
      return nil
    }
    var error: NSError?
    var consumed = false
    converter.convert(to: output, error: &error) { _, status in
      if consumed {
        status.pointee = .endOfStream
        return nil
      }
      consumed = true
      status.pointee = .haveData
      return inputBuffer
    }
    guard error == nil, let channels = output.int16ChannelData else { return nil }
    let byteCount = Int(output.frameLength) * MemoryLayout<Int16>.size
    return Data(bytes: channels[0], count: byteCount)
  }

  private func sampleBufferToPCM(_ sampleBuffer: CMSampleBuffer, format: AVAudioFormat)
    -> AVAudioPCMBuffer?
  {
    guard let block = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
    var length = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    guard
      CMBlockBufferGetDataPointer(
        block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length,
        dataPointerOut: &dataPointer) == noErr,
      let dataPointer = dataPointer
    else {
      return nil
    }
    let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
    guard bytesPerFrame > 0 else { return nil }
    let frames = AVAudioFrameCount(length / bytesPerFrame)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
      return nil
    }
    buffer.frameLength = frames
    if let dest = buffer.audioBufferList.pointee.mBuffers.mData {
      memcpy(dest, dataPointer, length)
    }
    return buffer
  }

  private func emitError(_ message: String) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(
        FlutterError(code: "system_audio", message: message, details: nil))
    }
  }
}
