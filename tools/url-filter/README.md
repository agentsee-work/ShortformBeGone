# URL filter prototype

**Status: prototype, not yet tested on a device.**

The network content filter is shown one address per connection, so it misses Shorts reached from inside an open YouTube session. The Safari content blocker closes that gap but cannot be locked on. Apple's URL filter (iOS 26 and later) checks every address requested through WebKit and URLSession, and can be delivered by a profile on a supervised device. This prototype is to find out whether it catches in-session Shorts and whether a profile locks it.

## How it works

1. The app's `ShortformBeGoneURLFilter` extension gives the system a Bloom filter built from the block list.
2. For each address, the system checks the Bloom filter on the device. If the address cannot be on the list, it is allowed at once.
3. For a possible match, the system asks a lookup server using private information retrieval: the server answers without learning which address was asked about.
4. If the server confirms the match, the request fails.

The block list never leaves this repository: both the Bloom filter and the server's database are generated from `Shared/FilterRules.swift`.

## The catch

A lookup server is required. There is no on-device-only mode.

| | Your own phone, built from Xcode | Shared with other people |
| --- | --- | --- |
| Server | Apple's example server on your Mac, plain HTTP on your network | Hosted server, token issuer and gateway, on HTTPS |
| Apple approval | None | Required, reported to take weeks |
| Works away from home | No. With fail-closed on, possible matches are blocked while the server is unreachable | Yes |

## Running it

One-time build of Apple's open-source server (several minutes):

```bash
tools/url-filter/run-server.sh --build
```

Start the server with the current block list:

```bash
tools/url-filter/run-server.sh
```

Build the app with the server's address, so the URL filter row appears in the Status tab:

```bash
xcodebuild -project ShortformBeGone.xcodeproj -scheme ShortformBeGone -destination 'id=<device id>' -allowProvisioningUpdates SBG_PIR_SERVER_URL="http://<your Mac>.local:8080" build
```

Without `SBG_PIR_SERVER_URL` the app builds as before and the URL filter is hidden.

## Test plan

Phone on the same Wi-Fi as the Mac, server running.

1. Switch the Safari blocker **off** (Settings → Apps → Safari → Extensions), so only the URL filter is being tested.
2. In the app's Status tab, tap **Turn on the URL filter**, allow it, enter the passcode.
3. Wait for the row to read **On**. This can take a minute.
4. In Safari, open the YouTube home page, then tap into a Short, and separately type `m.youtube.com/shorts`.
5. Check long-form video still plays.
6. Lock test: install `build/url-filter-test.mobileconfig` (from `tools/url-filter/make-test-profile.sh`) with Apple Configurator and see whether the URL filter can still be switched off in Settings.

The server log shows a request each time the phone looks something up.
