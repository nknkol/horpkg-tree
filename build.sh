#!/bin/bash
set -e

# horpkg-tree/build.sh for Cross-Compilation

VERSION="2.2.1"
ARCH=${1:-arm64-v8a}

if [ "$ARCH" = "arm64-v8a" ]; then
    OHOS_ARCH="aarch64"
else
    echo "❌ Error: This build script is configured for arm64-v8a cross-compilation."
    exit 1
fi

echo "========================================"
echo "Cross-Compiling tree for $ARCH ($OHOS_ARCH)"
echo "========================================"

# 检查 OHOS_SDK_HOME 是否由 CI 环境提供
if [ -z "$OHOS_SDK_HOME" ]; then
    echo "❌ Error: OHOS_SDK_HOME is not set. This script should be run in the CI environment."
    exit 1
fi
echo "✅ Using SDK from: ${OHOS_SDK_HOME}"

# 设置交叉编译工具链
export CC="$OHOS_SDK_HOME/native/llvm/bin/$OHOS_ARCH-unknown-linux-ohos-clang"
export CFLAGS="-O3 -static -std=c11 -pedantic -Wall -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -DLINUX"
export LDFLAGS="-static"

# 创建构建目录
BUILD_DIR="build-$ARCH"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 下载源码
SOURCE_URL="https://github.com/Old-Man-Programmer/tree/archive/refs/tags/${VERSION}.tar.gz"
SOURCE_ARCHIVE="${VERSION}.tar.gz"
echo "📥 Downloading source code..."
wget -q --show-progress -O "${SOURCE_ARCHIVE}" "${SOURCE_URL}"

# 解压
echo "📦 Extracting source..."
tar xzf "${SOURCE_ARCHIVE}"
cd "tree-${VERSION}"

# 编译
echo "🛠️ Building with cross-compiler..."
make

# ...后续安装和打包步骤保持不变...

INSTALL_DIR="../install"
FINAL_INSTALL_DIR="../final_install"
mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/share/man"

echo "⚙️ Installing..."
make install MANDIR="$INSTALL_DIR/share/man" DESTDIR="$INSTALL_DIR/bin"

rm -rf "$FINAL_INSTALL_DIR"
mkdir -p "$FINAL_INSTALL_DIR/bin" "$FINAL_INSTALL_DIR/share/man/man1"
mv "$INSTALL_DIR/bin/bin/tree" "$FINAL_INSTALL_DIR/bin/"
mv "$INSTALL_DIR/share/man/man1/tree.1" "$FINAL_INSTALL_DIR/share/man/man1/"

echo "🎁 Creating HNP package..."
cd "$FINAL_INSTALL_DIR"
cat > hnp.json << EOF
{ "type": "hnp-config", "name": "tree", "version": "${VERSION}", "install": {} }
EOF
zip -r "../../tree-${VERSION}-${ARCH}.hnp" .

cd ../../
sha256sum "tree-${VERSION}-${ARCH}.hnp" > "tree-${VERSION}-${ARCH}.hnp.sha256"

echo "========================================"
echo "✅ Cross-compilation complete!"
echo "========================================"