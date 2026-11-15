#!/bin/bash
# Makes the App Store screenshots by running the UI tests on the simulators
# whose sizes App Store Connect asks for. Output: AppStore/screenshots/<device>/
# Usage: tools/screenshots.sh ["iPhone 18 Pro Max" "iPad Pro 13-inch (M5)" ...]

set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [ "$#" -eq 0 ]; then
  set -- "iPhone 18 Pro Max" "iPad Pro 13-inch (M5)"
fi

for device in "$@"; do
  out="$PWD/AppStore/screenshots/$device"
  rm -rf "$out"; mkdir -p "$out"
  echo "== $device"
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" > /dev/null
  # A clean status bar: 9:41, full battery and signal.
  xcrun simctl status_bar "$device" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
  TEST_RUNNER_SCREENSHOT_DIR="$out" xcodebuild -quiet \
    -project ShortformBeGone.xcodeproj -scheme ShortformBeGone \
    -destination "platform=iOS Simulator,name=$device" \
    -derivedDataPath build/dd -only-testing:ShortformBeGoneUITests test
  xcrun simctl status_bar "$device" clear || true
  ls "$out"
done
