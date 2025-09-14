#!/usr/bin/env bash
set -euo pipefail

# Build EarxAudioEngine for iOS device + simulator, Debug + Release,
# stage libs into platform-suffixed folders, and optionally create XCFrameworks.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJ_DIR="$ROOT_DIR/build-ios"
SCHEME="EarxAudioEngine"
XCODEPROJ="$PROJ_DIR/Earx.xcodeproj"

usage() {
  cat <<EOF
Usage: $0 [--no-xcframework] [Debug|Release|all]

Builds static libs for:
  - iOS Device (iphoneos, arm64)
  - iOS Simulator (iphonesimulator, arm64/x86_64)
and stages outputs into:
  build-ios/<CONFIG>-iphoneos/libEarxAudioEngine.a
  build-ios/<CONFIG>-iphonesimulator/libEarxAudioEngine.a

Then creates XCFrameworks at:
  build-ios/xcframeworks/<CONFIG>/EarxAudioEngine.xcframework

Examples:
  $0               # build Debug + Release, create XCFrameworks
  $0 Debug         # build Debug only
  $0 --no-xcframework Release  # build Release only, skip XCFramework
EOF
}

CREATE_XCFRAMEWORK=1
CONFIGS=()

for arg in "$@"; do
  case "${arg}" in
    --no-xcframework) CREATE_XCFRAMEWORK=0 ;;
    -h|--help) usage; exit 0 ;;
    Debug|Release|all) CONFIGS+=("$arg") ;;
    *) echo "Unknown arg: $arg" >&2; usage; exit 1 ;;
  esac
done

if [ ${#CONFIGS[@]} -eq 0 ]; then
  CONFIGS=(all)
fi

if [[ "${CONFIGS[*]}" == *all* ]]; then
  CONFIGS=(Debug Release)
fi

cmake_generate() {
  if [ ! -d "$PROJ_DIR" ] || [ ! -f "$XCODEPROJ/project.pbxproj" ]; then
    echo "[+] Generating Xcode project via CMake"
    cmake -S "$ROOT_DIR" -B "$PROJ_DIR" -G Xcode
  fi
}

build_one() {
  local config="$1"

  echo "[+] Building $SCHEME ($config) for iOS device"
  xcodebuild -project "$XCODEPROJ" -scheme "$SCHEME" -configuration "$config" \
    -destination 'generic/platform=iOS' build >/dev/null

  # Source output (CMake/Xcode default may be non-suffixed). Prefer non-suffixed, fallback to suffixed.
  local src_ios="$PROJ_DIR/$config/libEarxAudioEngine.a"
  if [ ! -f "$src_ios" ]; then
    src_ios="$PROJ_DIR/$config-iphoneos/libEarxAudioEngine.a"
  fi
  mkdir -p "$PROJ_DIR/$config-iphoneos"
  cp -f "$src_ios" "$PROJ_DIR/$config-iphoneos/libEarxAudioEngine.a"

  echo "[+] Building $SCHEME ($config) for iOS simulator"
  xcodebuild -project "$XCODEPROJ" -scheme "$SCHEME" -configuration "$config" \
    -destination 'generic/platform=iOS Simulator' build >/dev/null

  local src_sim="$PROJ_DIR/$config/libEarxAudioEngine.a"
  if [ ! -f "$src_sim" ]; then
    src_sim="$PROJ_DIR/$config-iphonesimulator/libEarxAudioEngine.a"
  fi
  mkdir -p "$PROJ_DIR/$config-iphonesimulator"
  cp -f "$src_sim" "$PROJ_DIR/$config-iphonesimulator/libEarxAudioEngine.a"

  if [ "$CREATE_XCFRAMEWORK" = "1" ]; then
    echo "[+] Creating XCFramework ($config)"
    local outdir="$PROJ_DIR/xcframeworks/$config"
    rm -rf "$outdir/EarxAudioEngine.xcframework"
    mkdir -p "$outdir"
    xcodebuild -create-xcframework \
      -library "$PROJ_DIR/$config-iphoneos/libEarxAudioEngine.a" -headers "$ROOT_DIR/Source" \
      -library "$PROJ_DIR/$config-iphonesimulator/libEarxAudioEngine.a" -headers "$ROOT_DIR/Source" \
      -output "$outdir/EarxAudioEngine.xcframework" >/dev/null
    echo "[+] XCFramework ready: $outdir/EarxAudioEngine.xcframework"
  fi
}

main() {
  cmake_generate
  for cfg in "${CONFIGS[@]}"; do
    build_one "$cfg"
  done
  echo "[✓] Done"
}

main "$@"

