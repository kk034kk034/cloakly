#include "audio_encode.h"

#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <objbase.h>
#include <windows.h>

#include <fstream>
#include <iomanip>
#include <cmath>
#include <memory>
#include <sstream>
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

std::string HrMessage(const char* step, HRESULT hr) {
  std::ostringstream out;
  out << step << " 失敗 (0x" << std::uppercase << std::hex << std::setw(8)
      << std::setfill('0') << static_cast<unsigned long>(hr) << ")";
  return out.str();
}

void ThrowIfFailed(HRESULT hr, const char* step) {
  if (FAILED(hr)) {
    throw std::runtime_error(HrMessage(step, hr));
  }
}

int16_t ReadPcm16(const char* data, size_t offset) {
  const auto lo = static_cast<unsigned char>(data[offset]);
  const auto hi = static_cast<unsigned char>(data[offset + 1]);
  return static_cast<int16_t>(lo | (hi << 8));
}

void AppendPcm16(std::vector<char>& out, int sample) {
  sample = std::max(-32768, std::min(32767, sample));
  out.push_back(static_cast<char>(sample & 0xFF));
  out.push_back(static_cast<char>((sample >> 8) & 0xFF));
}

std::vector<char> ReadPcmData(std::ifstream& input) {
  std::vector<char> pcm;
  std::vector<char> chunk(64 * 1024);
  while (input) {
    input.read(chunk.data(), static_cast<std::streamsize>(chunk.size()));
    const std::streamsize read = input.gcount();
    if (read > 0) {
      pcm.insert(pcm.end(), chunk.begin(), chunk.begin() + read);
    }
  }
  if (pcm.size() % 2 != 0) {
    pcm.pop_back();
  }
  return pcm;
}

std::vector<char> ResampleMonoPcm16(
    const std::vector<char>& input,
    int input_rate,
    int output_rate) {
  const size_t in_frames = input.size() / 2;
  if (in_frames == 0 || input_rate == output_rate) {
    return input;
  }
  const size_t out_frames = static_cast<size_t>(
      std::ceil(static_cast<double>(in_frames) * output_rate / input_rate));
  std::vector<char> out;
  out.reserve(out_frames * 2);

  for (size_t i = 0; i < out_frames; ++i) {
    const double src = static_cast<double>(i) * input_rate / output_rate;
    const size_t left = static_cast<size_t>(src);
    const size_t right = std::min(left + 1, in_frames - 1);
    const double t = src - left;
    const int16_t a = ReadPcm16(input.data(), left * 2);
    const int16_t b = ReadPcm16(input.data(), right * 2);
    const int sample = static_cast<int>(std::lround(a + (b - a) * t));
    AppendPcm16(out, sample);
  }
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
  const std::vector<char> pcm16k = ReadPcmData(input);
  if (pcm16k.empty()) {
    throw std::runtime_error("wav 沒有音訊資料");
  }
  const int input_sample_rate = 16000;
  const int encode_sample_rate = 44100;
  const std::vector<char> pcm = ResampleMonoPcm16(
      pcm16k, input_sample_rate, encode_sample_rate);

  HRESULT hr = MFStartup(MF_VERSION);
  ThrowIfFailed(hr, "MFStartup");

  IMFSinkWriter* writer = nullptr;
  IMFMediaType* out_type = nullptr;
  IMFMediaType* in_type = nullptr;
  DWORD stream_index = 0;

  const std::wstring wide_out = Utf8ToWide(output_path);
  DeleteFileW(wide_out.c_str());
  hr = MFCreateSinkWriterFromURL(wide_out.c_str(), nullptr, nullptr, &writer);
  ThrowIfFailed(hr, "建立 m4a writer");
  if (SUCCEEDED(hr)) {
    hr = MFCreateMediaType(&out_type);
  }
  ThrowIfFailed(hr, "建立 AAC 輸出格式");
  if (SUCCEEDED(hr)) {
    hr = out_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetGUID(MF_MT_SUBTYPE, MFAudioFormat_AAC);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AAC_PAYLOAD_TYPE, 0);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, 1);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, encode_sample_rate);
  }
  if (SUCCEEDED(hr)) {
    hr = out_type->SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, 12000);
  }
  if (SUCCEEDED(hr)) {
    hr = writer->AddStream(out_type, &stream_index);
  }
  ThrowIfFailed(hr, "設定 AAC 輸出格式");
  if (SUCCEEDED(hr)) {
    hr = MFCreateMediaType(&in_type);
  }
  ThrowIfFailed(hr, "建立 PCM 輸入格式");
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
    hr = in_type->SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, encode_sample_rate);
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
  ThrowIfFailed(hr, "設定 PCM 輸入格式");
  if (SUCCEEDED(hr)) {
    hr = writer->BeginWriting();
  }
  ThrowIfFailed(hr, "開始 AAC 編碼");

  LONGLONG time_100ns = 0;
  constexpr size_t chunk_size = 32 * 1024;
  for (size_t offset = 0; offset < pcm.size(); offset += chunk_size) {
    const size_t remaining = pcm.size() - offset;
    const size_t read = std::min(chunk_size, remaining);
    const DWORD bytes = static_cast<DWORD>(read - (read % 2));
    if (bytes == 0) break;

    IMFMediaBuffer* buffer = nullptr;
    IMFSample* sample = nullptr;
    BYTE* data = nullptr;
    hr = MFCreateMemoryBuffer(bytes, &buffer);
    ThrowIfFailed(hr, "建立音訊緩衝區");
    if (SUCCEEDED(hr)) {
      hr = buffer->Lock(&data, nullptr, nullptr);
    }
    ThrowIfFailed(hr, "鎖定音訊緩衝區");
    if (SUCCEEDED(hr)) {
      memcpy(data, pcm.data() + offset, bytes);
      buffer->Unlock();
      hr = buffer->SetCurrentLength(bytes);
    }
    ThrowIfFailed(hr, "寫入音訊緩衝區");
    if (SUCCEEDED(hr)) {
      hr = MFCreateSample(&sample);
    }
    ThrowIfFailed(hr, "建立音訊 sample");
    if (SUCCEEDED(hr)) {
      hr = sample->AddBuffer(buffer);
    }
    ThrowIfFailed(hr, "加入音訊 sample buffer");
    if (SUCCEEDED(hr)) {
      const DWORD frames = bytes / 2;
      const LONGLONG duration =
          (static_cast<LONGLONG>(frames) * 10000000LL) / encode_sample_rate;
      sample->SetSampleTime(time_100ns);
      sample->SetSampleDuration(duration);
      time_100ns += duration;
      hr = writer->WriteSample(stream_index, sample);
    }
    ThrowIfFailed(hr, "寫入 AAC sample");
    SafeRelease(&sample);
    SafeRelease(&buffer);
  }

  if (SUCCEEDED(hr)) {
    hr = writer->Finalize();
  }
  const HRESULT final_hr = hr;

  SafeRelease(&in_type);
  SafeRelease(&out_type);
  SafeRelease(&writer);
  MFShutdown();

  ThrowIfFailed(final_hr, "完成 AAC 編碼");
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
