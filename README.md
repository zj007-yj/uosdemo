# uos_demo

在 **统信 UOS / Linux 桌面** 上用 **GStreamer** 同时预览两路 RTSP（避免 libmpv 在该环境下常见问题）。

仓库：<https://github.com/qq4833887/uos_demo>

```bash
git clone https://github.com/qq4833887/uos_demo.git
cd uos_demo
```

固定地址（可按需改 `lib/demo_urls.dart`）：

- `192.168.3.104`：`rtsp://admin:yanjing123@192.168.3.104/0`
- `192.168.3.119`：默认同样使用路径 `/0`；若设备路径不同，只改 `DemoUrls.rtsp119`。

## 目标机依赖（UOS / Debian 系）

构建或运行前请安装 GStreamer 开发包与常用插件（名称因发行版略有差异）：

```bash
sudo apt-get update
sudo apt-get install -y \
  libgtk-3-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-libav
```

## GitHub Actions（ARM64）

CI 使用 **`ubuntu-24.04-arm`** 原生编译 **linux/arm64** `bundle`，与 **ARM64 统信 UOS / 麒麟** 等机器架构一致。

推送到 `main` / `master` 后，在 Actions 里下载工件 **`uos-demo-linux-arm64-bundle`**，解压后进入 `bundle` 目录：

```bash
chmod +x uos_demo
./uos_demo
```

运行机仍需安装上文中的 GStreamer 运行时包（`gstreamer1.0-plugins-good` 等），无需安装 Flutter。

## 运行（本机有 Flutter SDK）

```bash
flutter pub get
flutter run -d linux
```

## 本机构建发布包

```bash
flutter build linux --release
```

ARM64 本机输出目录：`build/linux/arm64/release/bundle/`。x86_64 本机则为 `build/linux/x64/release/bundle/`。

## 说明

- 界面每路提供 **H264 / H265** 切换；若花屏或无画面，点对应按钮试另一种编码。
- 在非 Linux 上执行会提示仅支持 Linux，便于在 Windows 上只做代码编辑与 `flutter analyze`。
