import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'demo_log.dart';

/// 使用系统 **ffplay** 打开 RTSP（统信上比嵌入 GStreamer 插件稳定；需安装 ffmpeg）。
class RtspFfplayTile extends StatefulWidget {
  const RtspFfplayTile({
    super.key,
    required this.title,
    required this.rtspUrl,
  });

  final String title;
  final String rtspUrl;

  @override
  State<RtspFfplayTile> createState() => _RtspFfplayTileState();
}

class _RtspFfplayTileState extends State<RtspFfplayTile> {
  String? _lastError;

  @override
  void initState() {
    super.initState();
    unawaited(DemoLog.append(
      '[video]',
      'ffplay tile init title=${widget.title} url=${DemoLog.maskRtspUrl(widget.rtspUrl)}',
    ));
  }

  Future<void> _openFfplay() async {
    setState(() => _lastError = null);
    final url = widget.rtspUrl;
    await DemoLog.append('[ffplay]', 'start title=${widget.title} url=${DemoLog.maskRtspUrl(url)}');

    try {
      final exe = await _resolveFfplayPath();
      if (exe == null) {
        const msg = '未找到 ffplay，请安装：sudo apt install ffmpeg';
        setState(() => _lastError = msg);
        await DemoLog.append('[ffplay]', 'error: $msg');
        return;
      }

      final proc = await Process.start(exe, [
        '-window_title',
        widget.title,
        '-rtsp_transport',
        'tcp',
        url,
      ], mode: ProcessStartMode.detached);

      await DemoLog.append('[ffplay]', 'spawned pid=${proc.pid} exe=$exe');
    } catch (e, st) {
      final msg = '$e';
      setState(() => _lastError = msg);
      await DemoLog.append('[ffplay]', 'exception: $msg\n$st');
    }
  }

  /// 常见路径与 PATH 搜索。
  static Future<String?> _resolveFfplayPath() async {
    const candidates = ['/usr/bin/ffplay', '/usr/local/bin/ffplay'];
    for (final p in candidates) {
      if (await File(p).exists()) return p;
    }
    final which = await Process.run('which', ['ffplay']);
    if (which.exitCode == 0) {
      final path = which.stdout.toString().trim().split('\n').first.trim();
      if (path.isNotEmpty) return path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SelectableText(
              widget.rtspUrl,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openFfplay,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('用 ffplay 打开（独立窗口）'),
            ),
            const SizedBox(height: 8),
            Text(
              '说明：嵌入 GStreamer 在部分统信环境会在启动阶段触发 GLib 崩溃，'
              '故演示改为调用系统 ffplay（与您此前可播 RTSP 的环境一致）。',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            if (_lastError != null) ...[
              const SizedBox(height: 8),
              Text(
                _lastError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
