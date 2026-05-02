import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GstPlayerTextureController {
  static const MethodChannel _channel =
      MethodChannel('flutter_gstreamer_player');

  /// 使用可空类型：未完成 [initialize] 前不得读取 id（修复上游 late int + isInitialized 实现错误）。
  int? textureId;
  static int _id = 0;

  bool get isInitialized => textureId != null;

  Future<int> initialize(String pipeline) async {
    GstPlayerTextureController._id = GstPlayerTextureController._id + 1;

    final result = await _channel.invokeMethod<dynamic>('PlayerRegisterTexture', {
      'pipeline': pipeline,
      'playerId': GstPlayerTextureController._id,
    });
    if (result is! int) {
      throw StateError('PlayerRegisterTexture expected int, got $result');
    }
    textureId = result;

    return textureId!;
  }

  Future<void> dispose() async {
    final id = textureId;
    textureId = null;
    if (id == null) return;
    await _channel.invokeMethod<void>('dispose', {'textureId': id});
  }
}

class GstPlayer extends StatefulWidget {
  const GstPlayer({
    Key? key,
    required this.pipeline,
    this.onDiagnostic,
  }) : super(key: key);

  final String pipeline;

  /// 初始化失败或调试信息（便于宿主写入日志文件）。
  final void Function(String message)? onDiagnostic;

  @override
  State<GstPlayer> createState() => _GstPlayerState();
}

class _GstPlayerState extends State<GstPlayer> {
  final GstPlayerTextureController _controller = GstPlayerTextureController();
  Object? _lastInitError;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeController());
  }

  @override
  void didUpdateWidget(GstPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pipeline != oldWidget.pipeline) {
      unawaited(_initializeController());
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _initializeController() async {
    setState(() => _lastInitError = null);
    try {
      await _controller.dispose();
      await _controller.initialize(widget.pipeline);
      widget.onDiagnostic?.call('texture ok id=${_controller.textureId}');
      if (mounted) setState(() {});
    } catch (e, st) {
      widget.onDiagnostic?.call('init failed: $e\n$st');
      if (mounted) {
        setState(() => _lastInitError = '$e\n$st');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    switch (platform) {
      case TargetPlatform.linux:
      case TargetPlatform.android:
        if (_lastInitError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'GStreamer 初始化失败:\n$_lastInitError',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!_controller.isInitialized) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Texture(textureId: _controller.textureId!);
      case TargetPlatform.iOS:
        if (!_controller.isInitialized) {
          return const SizedBox.shrink();
        }
        final viewType = _controller.textureId.toString();
        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: const <String, dynamic>{},
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }
}
