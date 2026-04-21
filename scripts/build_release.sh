#!/usr/bin/env bash
# =============================================================================
# Briluxforge — Release Build Script
# Section 7.4 of CLAUDE.md: every release build uses --obfuscate.
# Run from the project root: bash scripts/build_release.sh [windows|macos|linux|all]
# =============================================================================

set -euo pipefail

PLATFORM="${1:-all}"
DEBUG_INFO_DIR="build/debug-info"

echo "==> Regenerating code (Riverpod + Drift + JSON)..."
dart run build_runner build --delete-conflicting-outputs

build_platform() {
  local platform="$1"
  echo ""
  echo "==> Building release for $platform..."
  flutter build "$platform" \
    --release \
    --obfuscate \
    --split-debug-info="$DEBUG_INFO_DIR/$platform"
  echo "    Done: build/$platform/release/"
}

case "$PLATFORM" in
  windows)
    build_platform windows
    ;;
  macos)
    build_platform macos
    ;;
  linux)
    build_platform linux
    ;;
  all)
    echo "Building all platforms..."
    # Build only the current host platform if cross-compilation isn't configured.
    # On Windows CI: only windows. On macOS CI: macos + linux via Docker.
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
      build_platform windows
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      build_platform macos
    else
      build_platform linux
    fi
    ;;
  *)
    echo "Usage: $0 [windows|macos|linux|all]"
    exit 1
    ;;
esac

echo ""
echo "==> Release build complete."
echo "    Debug symbols (DO NOT SHIP) are in: $DEBUG_INFO_DIR/"
echo "    Verify $DEBUG_INFO_DIR/ is in .gitignore before committing."
