#!/usr/bin/env bash
# 在 Ubuntu 20.04 / arm64 环境内构建，使产物链接较旧的 glibc/libstdc++，
# 便于统信 UOS 等较旧系统运行（避免 GLIBC_2.34 / GLIBCXX_3.4.29 一类错误）。
set -eux
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl git unzip xz-utils zip \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

git config --global --add safe.directory /workspace

git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
export PATH="/opt/flutter/bin:${PATH}"

flutter config --no-analytics
flutter config --enable-linux-desktop
flutter precache --linux

cd /workspace
flutter pub get
flutter build linux --release
