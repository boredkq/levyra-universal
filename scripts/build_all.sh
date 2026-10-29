#!/usr/bin/env bash
set -e

echo "=== Levyra Music: Universal Cross-Platform Build Script ==="

# Auto-scaffold native harnesses if running in a fresh workspace
if [ ! -f "android/app/build.gradle" ] || [ ! -d "ios/Runner.xcodeproj" ]; then
  echo "Scaffolding native platform harnesses..."
  flutter create --org com.luc4n3x --project-name levyra_universal .
  python3 scripts/configure_platforms.py
fi

TARGET=${1:-"all"}

case "$TARGET" in
  android)
    echo "Building Android APK..."
    flutter build apk --release --split-per-abi
    ;;
  ios)
    echo "Building iOS IPA (for AltStore / TrollStore / Sideloadly)..."
    flutter build ios --release --no-codesign
    cd build/ios/iphoneos
    mkdir -p Payload
    cp -r Runner.app Payload/
    zip -r -y LevyraMusic-iOS.ipa Payload
    echo "iOS IPA generated at build/ios/iphoneos/LevyraMusic-iOS.ipa"
    ;;
  macos)
    echo "Building macOS Desktop..."
    flutter config --enable-macos-desktop
    flutter build macos --release
    ;;
  windows)
    echo "Building Windows Desktop..."
    flutter config --enable-windows-desktop
    flutter build windows --release
    ;;
  linux)
    echo "Building Linux Desktop..."
    flutter config --enable-linux-desktop
    flutter build linux --release
    ;;
  all)
    echo "Building all desktop and mobile targets supported on this host..."
    OS="$(uname -s)"
    case "$OS" in
      Darwin*)
        flutter config --enable-macos-desktop
        flutter build macos --release || true
        flutter build apk --release || true
        ;;
      Linux*)
        flutter config --enable-linux-desktop
        flutter build linux --release || true
        flutter build apk --release || true
        ;;
      CYGWIN*|MINGW*|MSYS*)
        flutter config --enable-windows-desktop
        flutter build windows --release || true
        flutter build apk --release || true
        ;;
    esac
    ;;
  *)
    echo "Usage: $0 [android|ios|macos|windows|linux|all]"
    exit 1
    ;;
esac

echo "Build process finished."
