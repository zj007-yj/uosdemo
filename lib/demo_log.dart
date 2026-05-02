import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 运行期诊断日志：固定 **.txt** 扩展名，便于目标机用各种方式打开。
/// 按顺序尝试可写路径（HOME 异常、只读目录、无用户目录等仍可尽量落盘）。
class DemoLog {
  DemoLog._();

  static const String _fileName = 'video_debug.txt';

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

  static Future<File?> _resolveWritableLogFile() async {
    final home = Platform.environment['HOME'] ?? '';
    final tmp = Platform.environment['TMPDIR'] ?? '';
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    final candidates = <String>[
      if (home.isNotEmpty) '$home/.cache/uos_demo/$_fileName',
      if (tmp.isNotEmpty) '$tmp/uos_demo_$_fileName',
      '/tmp/uos_demo_$_fileName',
      '${Directory.current.path}/$_fileName',
      '$exeDir/$_fileName',
    ];

    for (final path in candidates) {
      try {
        final f = File(path);
        await f.parent.create(recursive: true);
        final sink = f.openWrite(mode: FileMode.append);
        await sink.close();
        return f;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Future<void> init() async {
    try {
      _file = await _resolveWritableLogFile();
      pathForUi = _file?.path;
      if (_file == null) {
        debugPrint('DemoLog: 无法找到可写路径保存 $_fileName');
        return;
      }
      await append('[app]', 'startup exe=${Platform.resolvedExecutable}');
      await append('[app]', 'cwd=${Directory.current.path}');
      await append(
        '[app]',
        'env HOME=${Platform.environment['HOME']} TMPDIR=${Platform.environment['TMPDIR']}',
      );
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
}
