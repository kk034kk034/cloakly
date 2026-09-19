#include "system_audio_linux.h"

#include <cstring>

static FlMethodChannel* g_system_audio_channel = nullptr;

static void cloakly_system_audio_call(FlMethodChannel* /*channel*/,
                                      FlMethodCall* method_call,
                                      gpointer /*user_data*/) {
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (g_strcmp0(method, "isSupported") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(FALSE)));
  } else if (g_strcmp0(method, "platformHint") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_string(
            "Linux 版尚未接 PulseAudio monitor。請用 Windows 或 macOS 聽耳機會議裡的對方。")));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

void cloakly_register_system_audio(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_system_audio_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "cloakly/system_audio", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      g_system_audio_channel, cloakly_system_audio_call, nullptr, nullptr);
}
