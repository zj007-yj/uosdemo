import 'dart:io';

import 'package:flutter/material.dart';

import 'demo_urls.dart';
import 'gst_rtsp_tile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        title: const Text('UOS RTSP 双路演示 (GStreamer)'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final tiles = <Widget>[
              Expanded(
                child: GstRtspTile(
                  title: '摄像头 192.168.3.104（路径 /0）',
                  rtspUrl: DemoUrls.rtsp104,
                ),
              ),
              Expanded(
                child: GstRtspTile(
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
