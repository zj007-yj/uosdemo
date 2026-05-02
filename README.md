# uos_demo

在 **统信 UOS / Linux 桌面** 上演示两路 **RTSP**：点击按钮用系统自带的 **`ffplay`**（FFmpeg）打开独立播放窗口。

此前嵌入 **GStreamer / Flutter 纹理插件** 在部分统信环境下会在启动阶段触发 **GLib 崩溃与段错误**，且与 Flutter Linux 版本强相关；为「拷过去就能用」，本仓库 **不再嵌入该插件**，改为调用你已验证可播 RTSP 的 **ffplay** 链路。

仓库：<https://github.com/zj007-yj/uosdemo>

```bash
git clone https://github.com/zj007-yj/uosdemo.git
cd uosdemo
```

固定地址（可按需改 `lib/demo_urls.dart`）：

- `192.168.3.104`：`rtsp://admin:yanjing123@192.168.3.104/0`
- `192.168.3.119`：默认路径 `/0`，不对则只改 `DemoUrls.rtsp119`。

## 目标机依赖（运行 bundle）

只需 **GTK 运行时**（一般桌面已有）和 **ffmpeg（含 ffplay）**：

```bash
sudo apt-get update
sudo apt-get install -y ffmpeg
```

无需安装 GStreamer 开发包或 Flutter。

## 核对是否为新打的包

应用内 **ⓘ 关于** 中显示 **`GIT_SHA`**。CI 构建会写入当前 Git 提交；若为 `local-dev` 表示本机 `flutter build` 未带 `--dart-define`。

## GitHub Actions（ARM64）

CI 在 **Ubuntu 20.04 / linux/arm64** 容器内编译（宿主机 QEMU），产物兼容较旧 glibc。下载 **`uos-demo-linux-arm64-bundle`** 后：

```bash
chmod +x uos_demo
./uos_demo
```

构建参数含 `--dart-define=GIT_SHA=...`，便于与崩溃日志对照版本。

### 若仍提示找不到 GLIBC / GLIBCXX

在同一台 UOS 上用 Flutter 源码构建，或在「与目标系统一致」的 Docker 镜像里执行 `scripts/docker-build-linux-arm64.sh`。

## 本机运行 / 打包

```bash
flutter pub get
flutter run -d linux
flutter build linux --release --dart-define=GIT_SHA=$(git rev-parse --short HEAD)
```

## 诊断日志

仍写入 **`video_debug.txt`**（路径规则见程序内「日志」按钮）。RTSP 在日志中会打码。

## 说明

- 每路 **独立 ffplay 窗口**；关闭播放器窗口不影响主程序。
- 在非 Linux 上打开工程仅用于编辑；运行界面仅在 Linux 可用。
