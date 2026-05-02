#include "gst_player.h"

#include "include/flutter_gstreamer_player/flutter_gstreamer_player_plugin.h"
#include "include/flutter_gstreamer_player/flutter_gstreamer_player_video_outlet.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <unordered_map>

#define FLUTTER_GSTREAMER_PLAYER_PLUGIN(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_gstreamer_player_plugin_get_type(), \
                              FlutterGstreamerPlayerPlugin))

struct _FlutterGstreamerPlayerPlugin {
  GObject parent_instance;
  FlMethodChannel* method_channel;
  FlTextureRegistrar* texture_registrar;
};

std::unordered_map<int32_t, VideoOutlet*> g_video_outlets;

G_DEFINE_TYPE(FlutterGstreamerPlayerPlugin, flutter_gstreamer_player_plugin,
              g_object_get_type())

// Called when a method call is received from Flutter.
static void flutter_gstreamer_player_plugin_handle_method_call(
    FlutterGstreamerPlayerPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    struct utsname uname_data = {};
    uname(&uname_data);
    g_autofree gchar* version =
        g_strdup_printf("Linux %s", uname_data.version);
    g_autoptr(FlValue) result = fl_value_new_string(version);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "PlayerRegisterTexture") == 0) {
    auto arguments = fl_method_call_get_args(method_call);
    auto pipeline =
        fl_value_get_string(fl_value_lookup_string(arguments, "pipeline"));
    int32_t player_id =
        fl_value_get_int(fl_value_lookup_string(arguments, "playerId"));
    auto [it, added] = g_video_outlets.try_emplace(player_id, nullptr);

    GstPlayer* gstPlayer = g_players->Get(player_id);

    if (added) {
      it->second = video_outlet_new();

      fl_texture_registrar_register_texture(self->texture_registrar,
                                              FL_TEXTURE(it->second));

      // 必须使用引擎分配的纹理 ID（Flutter 3.x），不能用指针强转。
      const int64_t flutter_texture_id =
          fl_texture_get_id(FL_TEXTURE(it->second));

      auto video_outlet_private =
          (VideoOutletPrivate*)video_outlet_get_instance_private(it->second);
      video_outlet_private->texture_id = flutter_texture_id;

      gstPlayer->onVideo([texture_registrar = self->texture_registrar,
                          video_outlet_ptr = it->second](
                             uint8_t* frame, uint32_t size, int32_t width,
                             int32_t height, int32_t stride) -> void {
        auto* priv = (VideoOutletPrivate*)video_outlet_get_instance_private(
            video_outlet_ptr);
        if (width <= 0 || height <= 0 || frame == nullptr) {
          return;
        }
        const size_t row = static_cast<size_t>(width) * 4;
        priv->rgba_storage.resize(row * static_cast<size_t>(height));
        const size_t src_stride = stride > 0
                                      ? static_cast<size_t>(stride)
                                      : row;
        for (int32_t y = 0; y < height; y++) {
          memcpy(priv->rgba_storage.data() + static_cast<size_t>(y) * row,
                 frame + static_cast<size_t>(y) * src_stride,
                 row);
        }
        priv->buffer = priv->rgba_storage.data();
        priv->video_width = width;
        priv->video_height = height;
        fl_texture_registrar_mark_texture_frame_available(
            texture_registrar, FL_TEXTURE(video_outlet_ptr));
      });
    }

    gstPlayer->play(pipeline);

    int64_t tid = 0;
    if (it->second != nullptr) {
      tid = fl_texture_get_id(FL_TEXTURE(it->second));
    }

    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_int(tid)));
  } else if (strcmp(method, "dispose") == 0) {
    auto arguments = fl_method_call_get_args(method_call);
    const int64_t texture_id =
        fl_value_get_int(fl_value_lookup_string(arguments, "textureId"));

    // 旧版 flutter_linux 可能没有 fl_texture_registrar_lookup_texture，
    // 用本地 map + fl_texture_get_id 匹配即可。
    for (auto iter = g_video_outlets.begin(); iter != g_video_outlets.end();) {
      VideoOutlet* outlet = iter->second;
      if (outlet != nullptr &&
          fl_texture_get_id(FL_TEXTURE(outlet)) == texture_id) {
        fl_texture_registrar_unregister_texture(self->texture_registrar,
                                                FL_TEXTURE(outlet));
        const int32_t pid = iter->first;
        g_object_unref(outlet);
        iter = g_video_outlets.erase(iter);
        g_players->Dispose(pid);
        break;
      }
      ++iter;
    }

    g_autoptr(FlValue) ok = fl_value_new_bool(true);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(ok));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void flutter_gstreamer_player_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_gstreamer_player_plugin_parent_class)->dispose(object);
}

static void flutter_gstreamer_player_plugin_class_init(
    FlutterGstreamerPlayerPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_gstreamer_player_plugin_dispose;
}

static void flutter_gstreamer_player_plugin_init(
    FlutterGstreamerPlayerPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterGstreamerPlayerPlugin* plugin =
      FLUTTER_GSTREAMER_PLAYER_PLUGIN(user_data);
  flutter_gstreamer_player_plugin_handle_method_call(plugin, method_call);
}

void flutter_gstreamer_player_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  FlutterGstreamerPlayerPlugin* plugin = FLUTTER_GSTREAMER_PLAYER_PLUGIN(
      g_object_new(flutter_gstreamer_player_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_gstreamer_player", FL_METHOD_CODEC(codec));

  plugin->texture_registrar =
      fl_plugin_registrar_get_texture_registrar(registrar);

  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
