#!/bin/bash
set -e

# horpkg-tree/build.sh

VERSION="2.2.1"
ARCH=${1:-arm64-v8a}

if [ "$ARCH" = "arm64-v8a" ]; then
    OHOS_ARCH="aarch64"
else
    echo "❌ Error: This script is currently configured for arm64-v8a builds."
    exit 1
fi

echo "========================================"
echo "Building tree for $ARCH ($OHOS_ARCH)"
echo "========================================"

# --- SDK Setup ---
SDK_URL="https://github.com/SwimmingTiger/third_party_llvm-project/releases/download/15.0.4-ohos-cli-5.1.0-2/ohos-command-line-tools-5.1.0-2-for-debian-12-arm64.tar.xz"
SDK_ARCHIVE="ohos-command-line-tools.tar.xz"
TOOL_DIR="/tmp/command-line-tools"

if [ ! -d "${TOOL_DIR}/sdk" ]; then
    echo "📥 Downloading HarmonyOS command line tools..."
    wget -q --show-progress -O "${SDK_ARCHIVE}" "${SDK_URL}"
    echo "📦 Extracting tools..."
    mkdir -p "${TOOL_DIR}"
    tar -xf "${SDK_ARCHIVE}" -C "${TOOL_DIR}" --strip-components=1
    rm "${SDK_ARCHIVE}"
fi
export OHOS_SDK_HOME="${TOOL_DIR}/sdk/default/openharmony"
echo "✅ SDK is ready at ${OHOS_SDK_HOME}"

# --- Build Process ---
export CC="$OHOS_SDK_HOME/native/llvm/bin/$OHOS_ARCH-unknown-linux-ohos-clang"
export CFLAGS="-O3 -static -std=c11 -pedantic -Wall -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -DLINUX"
export LDFLAGS="-static"

BUILD_DIR="build-$ARCH"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

SOURCE_URL="https://github.com/Old-Man-Programmer/tree/archive/refs/tags/${VERSION}.tar.gz"
SOURCE_ARCHIVE="${VERSION}.tar.gz"
echo "📥 Downloading source code..."
wget -q --show-progress -O "${SOURCE_ARCHIVE}" "${SOURCE_URL}"

echo "📦 Extracting source..."
tar xzf "${SOURCE_ARCHIVE}"
cd "tree-${VERSION}"

echo "🛠️ Building..."
make

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
echo "✅ Build complete!"
echo "========================================"