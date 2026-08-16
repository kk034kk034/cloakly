#include "system_audio_capture.h"

#include <audioclient.h>
#include <mmdeviceapi.h>
#include <mmreg.h>
#include <windows.h>

#include <atomic>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

namespace {

constexpr UINT kPcmMessage = WM_APP + 0xC1;
constexpr int kTargetRate = 16000;

struct PcmPacket {
  std::vector<uint8_t> bytes;
};

class SystemAudioHost {
 public:
  void SetHwnd(HWND hwnd) { hwnd_ = hwnd; }

  void SetSink(
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
    std::lock_guard<std::mutex> lock(mutex_);
    sink_ = std::move(sink);
  }

  void ClearSink() {
    std::lock_guard<std::mutex> lock(mutex_);
    sink_.reset();
  }

  void EmitOnUi(std::vector<uint8_t> bytes) {
    if (hwnd_ == nullptr || bytes.empty()) {
      return;
    }
    auto* packet = new PcmPacket();
    packet->bytes = std::move(bytes);
    if (!PostMessage(hwnd_, kPcmMessage, 0, reinterpret_cast<LPARAM>(packet))) {
      delete packet;
    }
  }

  void Deliver(PcmPacket* packet) {
    std::unique_ptr<PcmPacket> owned(packet);
    std::lock_guard<std::mutex> lock(mutex_);
    if (sink_ && owned) {
      sink_->Success(flutter::EncodableValue(owned->bytes));
    }
  }

  bool Start() {
    if (running_.exchange(true)) {
      return true;
    }
    thread_ = std::thread([this]() { CaptureLoop(); });
    return true;
  }

  void Stop() {
    if (!running_.exchange(false)) {
      return;
    }
    if (thread_.joinable()) {
      thread_.join();
    }
  }

 private:
  void CaptureLoop() {
    if (FAILED(CoInitializeEx(nullptr, COINIT_MULTITHREADED))) {
      running_ = false;
      return;
    }

    IMMDeviceEnumerator* enumerator = nullptr;
    IMMDevice* device = nullptr;
    IAudioClient* client = nullptr;
    IAudioCaptureClient* capture = nullptr;
    WAVEFORMATEX* format = nullptr;

    HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                                  CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
    if (SUCCEEDED(hr)) {
      hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
    }
    if (SUCCEEDED(hr)) {
      hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                            reinterpret_cast<void**>(&client));
    }
    if (SUCCEEDED(hr)) {
      hr = client->GetMixFormat(&format);
    }
    if (SUCCEEDED(hr)) {
      hr = client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                              AUDCLNT_STREAMFLAGS_LOOPBACK, 10000000, 0,
                              format, nullptr);
    }
    if (SUCCEEDED(hr)) {
      hr = client->GetService(__uuidof(IAudioCaptureClient),
                              reinterpret_cast<void**>(&capture));
    }
    if (SUCCEEDED(hr)) {
      hr = client->Start();
    }
    if (FAILED(hr) || format == nullptr || capture == nullptr) {
      if (client) {
        client->Stop();
      }
      if (format) {
        CoTaskMemFree(format);
      }
      if (capture) {
        capture->Release();
      }
      if (client) {
        client->Release();
      }
      if (device) {
        device->Release();
      }
      if (enumerator) {
        enumerator->Release();
      }
      CoUninitialize();
      running_ = false;
      return;
    }

    const int channels = static_cast<int>(format->nChannels);
    const int in_rate = static_cast<int>(format->nSamplesPerSec);
    const bool is_float = IsFloat(format);
    const int bits = format->wBitsPerSample;
    double resample_pos = 0.0;
    float prev_sample = 0.0f;

    while (running_) {
      Sleep(15);
      UINT32 packet_frames = 0;
      hr = capture->GetNextPacketSize(&packet_frames);
      if (FAILED(hr)) {
        break;
      }
      while (packet_frames > 0 && running_) {
        BYTE* data = nullptr;
        UINT32 frames = 0;
        DWORD flags = 0;
        hr = capture->GetBuffer(&data, &frames, &flags, nullptr, nullptr);
        if (FAILED(hr)) {
          break;
        }
        if (!(flags & AUDCLNT_BUFFERFLAGS_SILENT) && data != nullptr &&
            frames > 0) {
          std::vector<float> mono;
          mono.reserve(frames);
          for (UINT32 i = 0; i < frames; ++i) {
            float sample = 0.0f;
            if (is_float) {
              const float* fdata = reinterpret_cast<const float*>(data);
              if (channels <= 1) {
                sample = fdata[i];
              } else {
                sample = 0.5f * (fdata[i * channels] + fdata[i * channels + 1]);
              }
            } else if (bits == 16) {
              const int16_t* sdata = reinterpret_cast<const int16_t*>(data);
              if (channels <= 1) {
                sample = sdata[i] / 32768.0f;
              } else {
                sample = 0.5f *
                         (sdata[i * channels] + sdata[i * channels + 1]) /
                         32768.0f;
              }
            }
            mono.push_back(sample);
          }
          std::vector<uint8_t> pcm =
              ResampleTo16k(mono, in_rate, &resample_pos, &prev_sample);
          if (!pcm.empty()) {
            EmitOnUi(std::move(pcm));
          }
        }
        capture->ReleaseBuffer(frames);
        hr = capture->GetNextPacketSize(&packet_frames);
        if (FAILED(hr)) {
          break;
        }
      }
    }

    client->Stop();
    CoTaskMemFree(format);
    capture->Release();
    client->Release();
    device->Release();
    enumerator->Release();
    CoUninitialize();
  }

  static bool IsFloat(const WAVEFORMATEX* format) {
    if (format->wFormatTag == WAVE_FORMAT_IEEE_FLOAT) {
      return true;
    }
    if (format->wFormatTag == WAVE_FORMAT_EXTENSIBLE) {
      const auto* ext =
          reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(format);
      const GUID kFloat = {
          0x00000003,
          0x0000,
          0x0010,
          {0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}};
      return memcmp(&ext->SubFormat, &kFloat, sizeof(GUID)) == 0;
    }
    return false;
  }

  static std::vector<uint8_t> ResampleTo16k(const std::vector<float>& mono,
                                            int in_rate, double* pos,
                                            float* prev) {
    std::vector<uint8_t> out;
    if (mono.empty() || in_rate <= 0) {
      return out;
    }
    const double step = static_cast<double>(in_rate) / kTargetRate;
    size_t index = 0;
    float previous = *prev;
    double cursor = *pos;
    auto sample_at = [&](double at) -> float {
      if (at <= 0) {
        return previous;
      }
      const size_t i = static_cast<size_t>(at);
      if (i >= mono.size()) {
        return mono.back();
      }
      const float a = (i == 0) ? previous : mono[i - 1];
      const float b = mono[i];
      const float t = static_cast<float>(at - static_cast<double>(i));
      return a + (b - a) * t;
    };
    while (cursor < static_cast<double>(mono.size())) {
      const float value = sample_at(cursor);
      int scaled = static_cast<int>(value * 32767.0f);
      if (scaled > 32767) {
        scaled = 32767;
      }
      if (scaled < -32768) {
        scaled = -32768;
      }
      const int16_t s = static_cast<int16_t>(scaled);
      out.push_back(static_cast<uint8_t>(s & 0xff));
      out.push_back(static_cast<uint8_t>((s >> 8) & 0xff));
      cursor += step;
      ++index;
    }
    *prev = mono.back();
    *pos = cursor - static_cast<double>(mono.size());
    (void)index;
    return out;
  }

  HWND hwnd_ = nullptr;
  std::mutex mutex_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::atomic<bool> running_{false};
  std::thread thread_;
};

SystemAudioHost* g_host = nullptr;

}  // namespace

void RegisterSystemAudio(flutter::BinaryMessenger* messenger, HWND hwnd) {
  if (g_host == nullptr) {
    g_host = new SystemAudioHost();
  }
  g_host->SetHwnd(hwnd);

  auto* methods = new flutter::MethodChannel<flutter::EncodableValue>(
      messenger, "cloakly/system_audio",
      &flutter::StandardMethodCodec::GetInstance());
  methods->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "isSupported") {
          result->Success(flutter::EncodableValue(true));
          return;
        }
        if (call.method_name() == "platformHint") {
          result->Success(flutter::EncodableValue(
              "會擷取耳機／喇叭正在播放的聲音（Teams、Meet、Zoom 的對方）。"));
          return;
        }
        result->NotImplemented();
      });

  auto* events = new flutter::EventChannel<flutter::EncodableValue>(
      messenger, "cloakly/system_audio/pcm",
      &flutter::StandardMethodCodec::GetInstance());
  events->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [](const flutter::EncodableValue* /*arguments*/,
             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
                 sink)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            g_host->SetSink(std::move(sink));
            g_host->Start();
            return nullptr;
          },
          [](const flutter::EncodableValue* /*arguments*/)
              -> std::unique_ptr<
                  flutter::StreamHandlerError<flutter::EncodableValue>> {
            g_host->Stop();
            g_host->ClearSink();
            return nullptr;
          }));
}

bool SystemAudioHandleMessage(HWND /*hwnd*/, UINT message, WPARAM /*wparam*/,
                              LPARAM lparam) {
  if (message != kPcmMessage || g_host == nullptr) {
    return false;
  }
  g_host->Deliver(reinterpret_cast<PcmPacket*>(lparam));
  return true;
}

void ShutdownSystemAudio() {
  if (g_host == nullptr) {
    return;
  }
  g_host->Stop();
  g_host->ClearSink();
}
