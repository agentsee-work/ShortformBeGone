#!/bin/bash
# Checks every blocked app ID in the profile against the App Store.
# Usage: tools/verify-bundle-ids.sh [path/to/profile.mobileconfig]
# Uses only tools built into macOS (plutil, curl).

set -u
PROFILE="${1:-$(dirname "$0")/../Profile/no-shortform.mobileconfig}"
STOREFRONTS="us gb cn br"

if [ ! -f "$PROFILE" ]; then
  echo "Profile not found: $PROFILE" >&2
  exit 2
fi

ids=$(plutil -extract PayloadContent.0.blockedAppBundleIDs xml1 -o - "$PROFILE" \
  | sed -n 's|.*<string>\(.*\)</string>.*|\1|p')
if [ -z "$ids" ]; then
  echo "No blockedAppBundleIDs found in $PROFILE" >&2
  exit 2
fi

missing=0
for id in $ids; do
  name=""
  for country in $STOREFRONTS; do
    json=$(curl -s --max-time 20 "https://itunes.apple.com/lookup?bundleId=${id}&country=${country}")
    name=$(printf '%s' "$json" | sed -n 's/.*"trackName":"\([^"]*\)".*/\1/p' | head -1)
    [ -n "$name" ] && break
  done
  if [ -n "$name" ]; then
    printf 'ok         %-32s %s\n' "$id" "$name"
  else
    printf 'NOT FOUND  %s\n' "$id"
    missing=$((missing + 1))
  fi
done

if [ "$missing" -gt 0 ]; then
  echo
  echo "$missing ID(s) not found. To look up an app's current bundle ID:"
  echo "  curl -s 'https://itunes.apple.com/search?term=APP+NAME&entity=software&country=us&limit=5' | tr ',' '\n' | grep -E 'bundleId|trackName'"
  exit 1
fi
echo
echo "All bundle IDs found."
