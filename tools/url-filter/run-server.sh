#!/bin/bash
# Prototype: runs Apple's example lookup (PIR) server on this Mac with the
# ShortformBeGone block list, for the system URL filter.
#
# One-time setup (downloads and builds Apple's open-source code into build/pir):
#   tools/url-filter/run-server.sh --build
# Then:
#   tools/url-filter/run-server.sh
#
# The phone must be on the same network as this Mac and able to reach
# http://<this Mac>.local:8080. Apple's example server is not for production.

set -euo pipefail
cd "$(dirname "$0")/../.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
PIR="$PWD/build/pir"
DATA="$PIR/data"
BUNDLE_ID="agentsee.ShortformBeGone"
PORT="${PORT:-8080}"

if [ "${1:-}" = "--build" ]; then
  mkdir -p "$PIR"; cd "$PIR"
  [ -d pir-service-example ] || git clone --depth 1 https://github.com/apple/pir-service-example.git
  [ -d swift-homomorphic-encryption ] || git clone --depth 1 https://github.com/apple/swift-homomorphic-encryption.git
  (cd pir-service-example && swift build -c release --product PIRService)
  (cd swift-homomorphic-encryption && swift build -c release --product PIRProcessDatabase)
  exit 0
fi

SERVICE="$PIR/pir-service-example/.build/release/PIRService"
PROCESS="$PIR/swift-homomorphic-encryption/.build/release/PIRProcessDatabase"
[ -x "$SERVICE" ] && [ -x "$PROCESS" ] || { echo "Run '$0 --build' first." >&2; exit 2; }

mkdir -p "$DATA"
# The block list, from the same rules the app uses.
xcrun --sdk macosx swiftc -O Shared/FilterRules.swift Shared/URLFilterData.swift tools/url-filter/main.swift -o "$PIR/make-database"
"$PIR/make-database" > "$DATA/input.txtpb"
echo "Block list: $(grep -c keyword "$DATA/input.txtpb") entries"

cat > "$DATA/url-config.json" <<JSON
{
  "inputDatabase": "input.txtpb",
  "outputDatabase": "url-SHARD_ID.bin",
  "outputPirParameters": "url-SHARD_ID.params.txtpb",
  "rlweParameters": "n_4096_logq_27_28_28_logt_5",
  "sharding": { "entryCountPerShard": 50000 },
  "trialsPerShard": 5,
  "databaseType": "keyword"
}
JSON
cat > "$DATA/service-config.json" <<JSON
{
  "tokens": ["AAAA"],
  "usecases": [
    { "fileStem": "url", "shardCount": 1, "name": "$BUNDLE_ID.url.filtering" }
  ]
}
JSON

cd "$DATA"
rm -f url-*.bin url-*.params.txtpb
"$PROCESS" url-config.json
echo "Serving on http://$(scutil --get LocalHostName).local:$PORT  (Ctrl+C to stop)"
exec "$SERVICE" --hostname 0.0.0.0 --port "$PORT" service-config.json
