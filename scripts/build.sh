#!/bin/sh
# Build game: {love|web|linux|windows|macos|all}
set -eu

GAME_NAME="SuperGame"
LOVE_VERSION="11.5"
BUILD_DIR="build"
BIN_DIR="bin"
MAC_TEMPLATE_DIR="packaging/macos"
LOVE_FILE="${BUILD_DIR}/${GAME_NAME}.love"
WEB_DIR="${BUILD_DIR}/web"
APPIMAGE="${BUILD_DIR}/love-${LOVE_VERSION}-x86_64.AppImage"
WIN_EXE="${BUILD_DIR}/love-${LOVE_VERSION}-win64.exe"
MAC_ZIP="${BUILD_DIR}/love-${LOVE_VERSION}-macos.zip"
MAC_APP_BUNDLE="${BUILD_DIR}/${GAME_NAME}.app"

build_love() {
    echo "Building $LOVE_FILE..."
    mkdir -p "$BUILD_DIR" "$BIN_DIR"
    zip -9 -r "$LOVE_FILE" main.lua conf.lua src/ vendor/ assets/
}

build_web() {
    echo "Building Web export..."
    mkdir -p "$WEB_DIR"
    npx love.js -t "$GAME_NAME" "$LOVE_FILE" "$WEB_DIR/" -c
    zip -9 -r "$BIN_DIR/${GAME_NAME}_web.zip" "$WEB_DIR"
}

build_linux() {
    echo "Building Linux AppImage export..."
    if [ ! -f "$APPIMAGE" ]; then
        echo "Downloading Linux AppImage..."
        curl -L "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage" -o "$APPIMAGE"
        chmod +x "$APPIMAGE"
    fi
    "$APPIMAGE" --appimage-extract
    cat squashfs-root/bin/love "$LOVE_FILE" > "$BIN_DIR/${GAME_NAME}-linux"
    chmod +x "$BIN_DIR/${GAME_NAME}-linux"
}

build_windows() {
    echo "Building Windows export..."
    if [ ! -f "$WIN_EXE" ]; then
        echo "Downloading Windows Executable..."
        curl -L "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-win64.exe" -o "$WIN_EXE"
    fi
    cat "$WIN_EXE" "$LOVE_FILE" > "$BIN_DIR/${GAME_NAME}.exe"
}

build_macos() {
    echo "Building macOS export..."
    if [ ! -f "$MAC_ZIP" ]; then
        echo "Downloading macOS app..."
        curl -L "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-macos.zip" -o "$MAC_ZIP"
    fi
    unzip -q -o "$MAC_ZIP" -d "$BUILD_DIR"
    mv "${BUILD_DIR}/love.app" "$MAC_APP_BUNDLE"
    cp "$LOVE_FILE" "${MAC_APP_BUNDLE}/Contents/Resources/"
    if [ -f "${MAC_TEMPLATE_DIR}/Info.plist" ]; then
        cp "${MAC_TEMPLATE_DIR}/Info.plist" "${MAC_APP_BUNDLE}/Contents/Info.plist"
    else
        echo "WARNING: Custom Info.plist not found in ${MAC_TEMPLATE_DIR}."
        exit 1
    fi
    zip -ryq "$BIN_DIR/${GAME_NAME}_macos.zip" "$MAC_APP_BUNDLE"
}

build_all() {
    build_web
    build_linux
    build_windows
    build_macos
}

case "${1:-}" in
    love)  build_love ;;
    web|linux|windows|macos|all)
        build_love
        build_"$1"
        ;;
    *)
        echo "Usage: $0 {love|web|linux|windows|macos|all}"
        exit 1
        ;;
esac
