#!/bin/bash
set -e

# Tree build script for Horpkg
# Usage: ./build.sh [arm64-v8a|x86_64]

# 版本号更新为 Termony 项目中使用的 2.2.1
VERSION="2.2.1"
ARCH=${1:-arm64-v8a}

# 根据架构确定目标平台
if [ "$ARCH" = "arm64-v8a" ]; then
    OHOS_ARCH="aarch64"
elif [ "$ARCH" = "x86_64" ]; then
    OHOS_ARCH="x86_64"
else
    echo "❌ Error: Unsupported architecture: $ARCH"
    echo "Usage: $0 [arm64-v8a|x86_64]"
    exit 1
fi

echo "========================================"
echo "Building tree for $ARCH ($OHOS_ARCH)"
echo "========================================"

# 检查环境变量
if [ -z "$OHOS_SDK_HOME" ]; then
    echo "❌ Error: OHOS_SDK_HOME not set"
    exit 1
fi

# 设置编译环境，参考 termony 流程
export CC="$OHOS_SDK_HOME/native/llvm/bin/$OHOS_ARCH-unknown-linux-ohos-clang"
export CFLAGS="-O3 -static -std=c11 -pedantic -Wall -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -DLINUX"
export LDFLAGS="-static"

# 创建构建目录
BUILD_DIR="build-$ARCH"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 下载源码 - 已更新为 Termony 项目中使用的有效 GitHub 链接
SOURCE_URL="https://github.com/Old-Man-Programmer/tree/archive/refs/tags/${VERSION}.tar.gz"
SOURCE_ARCHIVE="${VERSION}.tar.gz"

if [ ! -f "${SOURCE_ARCHIVE}" ]; then
    echo "📥 Downloading ${SOURCE_ARCHIVE}..."
    wget -q --show-progress -O "${SOURCE_ARCHIVE}" "${SOURCE_URL}"
fi

# 解压
echo "📦 Extracting..."
tar xzf "${SOURCE_ARCHIVE}"
cd "tree-${VERSION}"

# 编译
echo "🛠️ Building..."
make

# 创建安装目录结构
INSTALL_DIR="../install"
FINAL_INSTALL_DIR="../final_install"

mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/share/man"

# 安装
echo "⚙️ Installing..."
make install MANDIR="$INSTALL_DIR/share/man" DESTDIR="$INSTALL_DIR/bin"

# 整理文件结构以匹配 HNP 打包需求
rm -rf "$FINAL_INSTALL_DIR"
mkdir -p "$FINAL_INSTALL_DIR/bin"
mkdir -p "$FINAL_INSTALL_DIR/share/man/man1"
mv "$INSTALL_DIR/bin/bin/tree" "$FINAL_INSTALL_DIR/bin/"
mv "$INSTALL_DIR/share/man/man1/tree.1" "$FINAL_INSTALL_DIR/share/man/man1/"

# 创建 HNP 包
echo "🎁 Creating HNP package..."
cd "$FINAL_INSTALL_DIR"

# 创建 hnp.json
cat > hnp.json << EOF
{
    "type": "hnp-config",
    "name": "tree",
    "version": "${VERSION}",
    "install": {}
}
EOF

# 打包
HNP_FILE="../../tree-${VERSION}-${ARCH}.hnp"
zip -r "$HNP_FILE" .

# 生成校验和
cd ../../
sha256sum "tree-${VERSION}-${ARCH}.hnp" > "tree-${VERSION}-${ARCH}.hnp.sha256"

echo "========================================"
echo "✅ Build complete!"
echo "Package: $(pwd)/tree-${VERSION}-${ARCH}.hnp"
echo "SHA256:  $(pwd)/tree-${VERSION}-${ARCH}.hnp.sha256"
echo "========================================"