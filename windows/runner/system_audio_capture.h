#ifndef RUNNER_SYSTEM_AUDIO_CAPTURE_H_
#define RUNNER_SYSTEM_AUDIO_CAPTURE_H_

#include <windows.h>

#include <flutter/binary_messenger.h>

void RegisterSystemAudio(flutter::BinaryMessenger* messenger, HWND hwnd);
bool SystemAudioHandleMessage(HWND hwnd, UINT message, WPARAM wparam,
                              LPARAM lparam);
void ShutdownSystemAudio();

#endif  // RUNNER_SYSTEM_AUDIO_CAPTURE_H_
