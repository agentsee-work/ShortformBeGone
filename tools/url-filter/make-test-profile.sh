#!/bin/bash
# Prototype: writes a profile that switches on the system URL filter on a
# supervised device, to test whether a profile-delivered URL filter is locked.
# It has no removal password, so it can be removed again in Settings.
# Usage: tools/url-filter/make-test-profile.sh [server-url]
set -euo pipefail
cd "$(dirname "$0")/../.."
SERVER="${1:-http://$(scutil --get LocalHostName).local:8080}"
OUT="build/url-filter-test.mobileconfig"
mkdir -p build
cat > "$OUT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadDisplayName</key>
	<string>ShortformBeGone URL filter (test)</string>
	<key>PayloadIdentifier</key>
	<string>agentsee.ShortformBeGone.urlfilter-test</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>$(uuidgen)</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
	<key>PayloadScope</key>
	<string>System</string>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadType</key>
			<string>com.apple.webcontent-filter</string>
			<key>PayloadIdentifier</key>
			<string>agentsee.ShortformBeGone.urlfilter-test.filter</string>
			<key>PayloadUUID</key>
			<string>$(uuidgen)</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>FilterType</key>
			<string>Plugin</string>
			<key>UserDefinedName</key>
			<string>ShortformBeGone URL filter</string>
			<key>PluginBundleID</key>
			<string>agentsee.ShortformBeGone</string>
			<key>FilterURLs</key>
			<true/>
			<key>URLFilterParameters</key>
			<dict>
				<key>URLFilterControlProviderBundleIdentifier</key>
				<string>agentsee.ShortformBeGone.URLFilter</string>
				<key>PIRServerURL</key>
				<string>$SERVER</string>
				<key>PIRPrivacyPassIssuerURL</key>
				<string>$SERVER</string>
				<key>PIRAuthenticationToken</key>
				<string>AAAA</string>
				<key>URLFilterFailClosed</key>
				<false/>
				<key>URLPrefilterFetchFrequency</key>
				<integer>2700</integer>
			</dict>
		</dict>
	</array>
</dict>
</plist>
PLIST
plutil -lint "$OUT"
