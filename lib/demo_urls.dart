/// 演示用固定地址（勿提交到公开仓库）。
/// 192.168.3.104 的 RTSP 需带路径 `/0`。
class DemoUrls {
  static const String user = 'admin';
  static const String pass = 'yanjing123';

  /// 拼接：rtsp://admin:yanjing123@192.168.3.104/0
  static const String rtsp104 =
      'rtsp://$user:$pass@192.168.3.104/0';

  /// 119 未说明子路径；若设备不是 `/0`，只改这一行即可。
  static const String rtsp119 =
      'rtsp://$user:$pass@192.168.3.119';
}
