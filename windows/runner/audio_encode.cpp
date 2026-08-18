#include "audio_encode.h"

#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <objbase.h>
#include <windows.h>

#include <fstream>
#include <memory>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")

namespace {

template <typename T>
void SafeRelease(T** value) {
  if (value && *value) {
    (*value)->Release();
    *value = nullptr;
  }
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }
  const int size = MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
  std::wstring out(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, out.data(), size);
  return out;
}

void EncodeWavToM4a(const std::string& input_path, const std::string& output_path) {
  std::ifstream input(input_path, std::ios::binary);
  if (!input) {
    throw std::runtime_error("找不到 wav");
  }
  std::vector<char> header(44);
  input.read(header.data(), 44);
  if (input.gcount() < 44) {
    throw std::runtime_error("wav 檔不完整");
  }

  HRESULT hr = MFStartup(MF_VERSION);
  if (FAILED(hr)) {
    throw std::runtime_error("MFStartup 失敗");
  }

  IMFSinkWriter* writer = nullptr;
  IMFMediaType* out_type = nullptr;
  IMFMediaType* in_type = nullptr;
  DWORD stream_index = 0;

  const std::wstring wide_out = Utf8ToWide(output_path);
  DeleteFileW(wide_out.c_str());
  hr = MFCreateSinkWriterFromURL(wide_out.c_str(), nullptr, nullptr, &writer);
  if (SUCCEEDED(hr)) {
    hr = MFCreateMediaType(&out_type);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_AAC);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, 1);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, 16000);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, 6000);
  }
  if (SUCCEEDED(hr)) {
    hr = writer->AddStream(out_type, &stream_index);
  }
  if (SUCCEEDED(hr)) {
    hr = MFCreateMediaType(&in_type);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, 1);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, 16000);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetUINT32(MF_MT_AUDIO_BLOCK_ALIGNMENT, 2);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, 32000);
  }
  if (SUCCEEDED(hr)) {
    hr = in_type->SetUINT32(MF_MT_ALL_SAMPLES_INDEPENDENT, TRUE);
  }
  if (SUCCEEDED(hr)) {
    hr = writer->SetInputMediaType(stream_index, in_type, nullptr);
  }
  if (SUCCEEDED(hr)) {
    hr = writer->BeginWriting();
  }

  LONGLONG time_100ns = 0;
  std::vector<char> chunk(32 * 1024);
  while (SUCCEEDED(hr)) {
    input.read(chunk.data(), static_cast<std::streamsize>(chunk.size()));
    const std::streamsize read = input.gcount();
    if (read <= 0) {
      break;
    }
    const DWORD bytes = static_cast<DWORD>(read - (read % 2));
    if (bytes == 0) {
      break;
    }

    IMFMediaBuffer* buffer = nullptr;
    IMFSample* sample = nullptr;
    BYTE* data = nullptr;
    hr = MFCreateMemoryBuffer(bytes, &buffer);
    if (SUCCEEDED(hr)) {
      hr = buffer->Lock(&data, nullptr, nullptr);
    }
    if (SUCCEEDED(hr)) {
      memcpy(data, chunk.data(), bytes);
      buffer->Unlock();
      hr = buffer->SetCurrentLength(bytes);
    }
    if (SUCCEEDED(hr)) {
      hr = MFCreateSample(&sample);
    }
    if (SUCCEEDED(hr)) {
      hr = sample->AddBuffer(buffer);
    }
    if (SUCCEEDED(hr)) {
      const DWORD frames = bytes / 2;
      const LONGLONG duration = (static_cast<LONGLONG>(frames) * 10000000LL) / 16000;
      sample->SetSampleTime(time_100ns);
      sample->SetSampleDuration(duration);
      time_100ns += duration;
      hr = writer->WriteSample(stream_index, sample);
    }
    SafeRelease(&sample);
    SafeRelease(&buffer);
  }

  if (SUCCEEDED(hr)) {
    hr = writer->Finalize();
  }

  SafeRelease(&in_type);
  SafeRelease(&out_type);
  SafeRelease(&writer);
  MFShutdown();

  if (FAILED(hr)) {
    throw std::runtime_error("AAC 編碼失敗");
  }
}

}  // namespace

void RegisterAudioEncode(flutter::BinaryMessenger* messenger) {
  auto* methods = new flutter::MethodChannel<flutter::EncodableValue>(
      messenger, "cloakly/audio_encode",
      &flutter::StandardMethodCodec::GetInstance());
  methods->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "encodeWavToM4a") {
          result->NotImplemented();
          return;
        }
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args == nullptr) {
          result->Error("bad_args", "缺少路徑", nullptr);
          return;
        }
        auto input_it = args->find(flutter::EncodableValue("inputPath"));
        auto output_it = args->find(flutter::EncodableValue("outputPath"));
        if (input_it == args->end() || output_it == args->end()) {
          result->Error("bad_args", "缺少路徑", nullptr);
          return;
        }
        const auto* input = std::get_if<std::string>(&input_it->second);
        const auto* output = std::get_if<std::string>(&output_it->second);
        if (input == nullptr || output == nullptr) {
          result->Error("bad_args", "缺少路徑", nullptr);
          return;
        }

        auto* pending = result.release();
        std::thread([pending, input = *input, output = *output]() {
          CoInitializeEx(nullptr, COINIT_MULTITHREADED);
          try {
            EncodeWavToM4a(input, output);
            pending->Success(flutter::EncodableValue(output));
          } catch (const std::exception& error) {
            pending->Error("encode_failed", error.what(), nullptr);
          }
          CoUninitialize();
          delete pending;
        }).detach();
      });
}
