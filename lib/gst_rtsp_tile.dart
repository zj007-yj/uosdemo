import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gstreamer_player/flutter_gstreamer_player.dart';

import 'demo_log.dart';

/// 单路 RTSP，GStreamer 管道（TCP + H264/H265 可切换）。
class GstRtspTile extends StatefulWidget {
  const GstRtspTile({
    super.key,
    required this.title,
    required this.rtspUrl,
  });

  final String title;
  final String rtspUrl;

  @override
  State<GstRtspTile> createState() => _GstRtspTileState();
}

class _GstRtspTileState extends State<GstRtspTile> {
  bool _preferH265 = false;

  String _pipeline(String url, {required bool preferH265}) {
    final depay = preferH265
        ? 'rtph265depay ! h265parse'
        : 'rtph264depay ! h264parse';
    return '''
rtspsrc location="$url" protocols=tcp latency=200 drop-on-latency=true !
$depay !
decodebin !
videoconvert !
video/x-raw,format=RGBA !
appsink name=sink
''';
  }

  @override
  void initState() {
    super.initState();
    unawaited(DemoLog.append(
      '[video]',
      'tile init title=${widget.title} url=${DemoLog.maskRtspUrl(widget.rtspUrl)}',
    ));
  }

  @override
  void didUpdateWidget(covariant GstRtspTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rtspUrl != widget.rtspUrl ||
        oldWidget.title != widget.title) {
      unawaited(DemoLog.append(
        '[video]',
        'tile props title=${widget.title} url=${DemoLog.maskRtspUrl(widget.rtspUrl)}',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.rtspUrl;
    final pipeline = _pipeline(url, preferH265: _preferH265);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            title: Text(widget.title),
            subtitle: Text(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: TextButton(
              onPressed: () {
                setState(() => _preferH265 = !_preferH265);
                unawaited(DemoLog.append(
                  '[video]',
                  'user toggle codec -> ${_preferH265 ? "H265" : "H264"} '
                  'title=${widget.title}',
                ));
              },
              child: Text(_preferH265 ? 'H265→H264' : 'H264→H265'),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: GstPlayer(
                key: ValueKey<String>('$url|$_preferH265'),
                pipeline: pipeline,
                onDiagnostic: (msg) => unawaited(
                  DemoLog.append('[GstPlayer]', '${widget.title}: $msg'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
