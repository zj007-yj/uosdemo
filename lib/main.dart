import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'build_info.dart';
import 'demo_log.dart';
import 'demo_urls.dart';
import 'rtsp_tile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoLog.init();
  FlutterError.onError = (FlutterErrorDetails details) {
    DemoLog.logFlutterError(details);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(
      DemoLog.append('[platformError]', '$error\n$stack'),
    );
    return false;
  };
  runApp(const UosRtspDemoApp());
}

class UosRtspDemoApp extends StatelessWidget {
  const UosRtspDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UOS RTSP Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  void _showAbout(BuildContext context) {
    unawaited(DemoLog.append('[ui]', 'opened about'));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('关于 / 版本'),
        content: SelectableText(
          '构建提交 GIT_SHA：\n$kGitSha\n\n'
          '若此处为 local-dev，说明是本机调试构建；'
          'CI 制品应显示 GitHub 提交哈希。\n\n'
          '请确认已安装 ffplay：\n'
          'sudo apt install ffmpeg',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showLogHelp(BuildContext context) {
    final path = DemoLog.pathForUi ?? '(未初始化)';
    unawaited(DemoLog.append('[ui]', 'opened log help dialog'));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('诊断日志'),
        content: SingleChildScrollView(
          child: SelectableText(
            '日志文件（.txt，可复制路径）：\n$path\n\n'
            '说明：\n'
            '• 固定扩展名 .txt，便于记事本或打包回传。\n'
            '• 启动时按顺序尝试可写目录，实际路径以上方为准。\n'
            '• 启动、ffplay 异常会写入该文件。\n',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isLinux) {
      return Scaffold(
        appBar: AppBar(title: const Text('UOS RTSP Demo')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '本演示仅面向 Linux 桌面（统信 UOS 等）。\n'
              '请在目标机或 ARM64/x64 Linux 上执行：\n'
              'flutter run -d linux\n'
              '或构建 bundle 后运行可执行文件。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('UOS RTSP（ffplay）'),
        actions: [
          IconButton(
            tooltip: '版本 / ffplay 依赖',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
          IconButton(
            tooltip: '日志路径',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => _showLogHelp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final tiles = <Widget>[
              Expanded(
                child: RtspFfplayTile(
                  title: '摄像头 192.168.3.104（路径 /0）',
                  rtspUrl: DemoUrls.rtsp104,
                ),
              ),
              Expanded(
                child: RtspFfplayTile(
                  title: '摄像头 192.168.3.119',
                  rtspUrl: DemoUrls.rtsp119,
                ),
              ),
            ];
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tiles,
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: tiles,
            );
          },
        ),
      ),
    );
  }
}
