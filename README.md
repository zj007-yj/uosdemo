# uos_demo

在 **统信 UOS / Linux 桌面** 上用 **GStreamer** 同时预览两路 RTSP（避免 libmpv 在该环境下常见问题）。

仓库：<https://github.com/zj007-yj/uosdemo>

```bash
git clone https://github.com/zj007-yj/uosdemo.git
cd uosdemo
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

CI 在 **Ubuntu 20.04 / linux/arm64** 容器内编译（宿主机用 QEMU 仿真），使二进制链接 **较旧的 glibc / libstdc++**，减轻在旧版统信 UOS 上出现 **`GLIBC_2.34` / `GLIBCXX_3.4.xx` not found** 的情况。若在仍较旧的系统上运行失败，在目标机执行 `ldd --version` 核对 glibc 版本。

推送到 `main` / `master` 后，在 Actions 里下载工件 **`uos-demo-linux-arm64-bundle`**，解压后进入 `bundle` 目录：

```bash
chmod +x uos_demo
./uos_demo
```

运行机仍需安装上文中的 GStreamer **运行时**包（`gstreamer1.0-plugins-good` 等），无需安装 Flutter。

### 若仍提示找不到 GLIBC / GLIBCXX

说明 CI 产物的链接版本仍高于目标机系统库。可选：**在同一台 UOS 上安装 Flutter 源码构建**（与本机 glibc 完全一致），或在本机 Docker（与目标发行版一致的镜像）里执行仓库中的 `scripts/docker-build-linux-arm64.sh` 逻辑自定义构建。

### 关于 `LateInitializationError: textureId` / GLib 报错

pub.dev 上 **`flutter_gstreamer_player` 0.0.3** 在 Dart 层误用 `late int textureId`，首帧 `build` 会在异步初始化完成前访问未赋值字段，从而触发 **LateInitializationError**，并可能连带出现 GLib 断言与段错误。本仓库已将插件 **vendoring 到 `packages/flutter_gstreamer_player`** 并修正初始化与占位 UI；请重新拉代码并 **重新打 CI 包** 后再在 UOS 上运行。

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

## 诊断日志（排查无画面）

- 日志为 **纯文本 `.txt`**，默认文件名 **`video_debug.txt`**，便于目标机记事本打开或随工单回传。
- 启动时按顺序尝试写入（第一个可写即采用）：`$HOME/.cache/uos_demo/` → `$TMPDIR/` → **`/tmp/uos_demo_video_debug.txt`** → **当前工作目录** → **可执行文件所在目录**（同名 `video_debug.txt` 或带前缀文件见上）。
- 实际路径以程序内 **文档图标** 对话框为准；`$HOME` 未设置或目录只读时会自动落到 `/tmp` 或 bundle 旁。
- 记录内容：启动路径、每路视频 tile 初始化、切换 H264/H265、Dart/Flutter 未捕获异常。
- RTSP 在日志里会 **打码**（隐藏密码），仍保留主机与路径。
- 界面右上角 **文档图标** 可查看日志绝对路径与 **GST_DEBUG** 用法（GStreamer 原生层需在终端带环境变量运行，例如 `GST_DEBUG=2 ./uos_demo`）。

## 说明

- 界面每路提供 **H264 / H265** 切换；若花屏或无画面，点对应按钮试另一种编码。
- 在非 Linux 上执行会提示仅支持 Linux，便于在 Windows 上只做代码编辑与 `flutter analyze`。
