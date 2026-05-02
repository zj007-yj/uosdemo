import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 运行期诊断日志（默认写入用户目录，避免 bundle 只读路径）。
class DemoLog {
  DemoLog._();

  static File? _file;
  static String? pathForUi;

  /// 日志中的 RTSP 地址打码（仍保留 host 与 path 便于排查）。
  static String maskRtspUrl(String url) {
    try {
      final u = Uri.parse(url);
      if (u.scheme != 'rtsp') return url;
      final user = u.userInfo.isEmpty ? '' : '${u.userInfo.split(':').first}:***@';
      return 'rtsp://$user${u.host}${u.hasPort ? ':${u.port}' : ''}${u.path}';
    } catch (_) {
      return '(unparseable url)';
    }
  }

  static Future<void> init() async {
    try {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final dir = Directory('$home/.cache/uos_demo');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _file = File('${dir.path}/video_debug.log');
      } else {
        _file = File('video_debug.log');
      }
      pathForUi = _file!.path;
      await append('[app]', 'startup exe=${Platform.resolvedExecutable}');
      await append('[app]', 'cwd=${Directory.current.path} HOME=$home');
      await append('[app]', 'log=$pathForUi');
    } catch (e, st) {
      debugPrint('DemoLog.init failed: $e\n$st');
    }
  }

  static Future<void> append(String tag, String message) async {
    try {
      final f = _file;
      if (f == null) return;
      final ts = DateTime.now().toIso8601String();
      await f.writeAsString('$ts $tag $message\n',
          mode: FileMode.append, flush: true);
    } catch (e) {
      debugPrint('DemoLog.append: $e');
    }
  }

  static void logFlutterError(FlutterErrorDetails details) {
    final msg =
        '${details.exceptionAsString()} ${details.stack ?? ''}'.trim();
    unawaited(append('[FlutterError]', msg));
  }

  static bool logPlatformError(Object error, StackTrace stack) {
    unawaited(append('[platformError]', '$error\n$stack'));
    return true;
  }
}
