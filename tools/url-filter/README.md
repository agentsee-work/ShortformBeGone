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

## What the first device test showed (15 November 2026, iPhone 16 Plus, iOS 27.2.1)

**It works, with one limit.**

- The filter starts, fetches its settings from the lookup server and makes
  lookups. A test page in Safari confirmed that in-page requests to listed
  addresses are refused even on a connection that is already open, which is
  what the network filter cannot do. Ordinary YouTube pages, the video player
  request and other sites load.
- **The system only looks up the exact address unless told otherwise.** On
  iOS 27.2 hierarchy enumeration is off by default, so `youtube.com/shorts`
  did not cover `youtube.com/shorts/<id>`. The app now sets
  `urlParsingConfiguration` (iOS 27) to enumerate path levels and drop the
  query. Whole-site entries matched at any depth without it.
- **The limit: one Short still plays.** Tapping a Short on the YouTube home
  page loads that video through `/youtubei/v1/player`, the same address every
  normal video uses, so it cannot be listed. The requests that build the
  Shorts feed (`/youtubei/v1/reel/...`) are refused, so there is nothing to
  swipe to. Reproduced in a desktop browser with the same requests blocked.
  Hiding the Shorts shelf and tab is the Safari blocker's job.

### Things that went wrong, and what to do about them

- **Failing closed blocks all of Safari** whenever the lookup server is out of
  reach or the filter is restarting. The prototype fails open.
- **Installing a new build while the filter is on** leaves the system unable
  to find the extension ("Failed to setup provider", empty identities list in
  the device log) until the phone is restarted. Switch the filter off, install,
  switch it on: `-urlFilter off`, install, `-urlFilter on`.
- **`NEURLFilterManager.status` reads `invalid`** until the system reports a
  change; follow `handleStatusChange()` instead.
- **`saveToPreferences()` throws `configurationUnchanged`** when nothing
  changed. It is not a failure.
- A few lookups timed out and were let through (three in one test round).

### Driving it from the Mac (debug builds)

    xcrun devicectl device process launch --terminate-existing --device <id> \
        agentsee.ShortformBeGone -- -urlFilter <command>

`on`, `off`, `reset` (clear the lookup cache), `remove` (delete the
configuration), `check` (wait until running, then log the system's verdict for
a set of addresses; 3 is deny, 2 is allow), `parse-hier|seg1|seg3|noquery|default`
(how addresses are split into lookup keys).

### Lock test with a profile (same day)

Installed `build/url-filter-test.mobileconfig` (a `com.apple.webcontent-filter`
payload with `FilterURLs` and `URLFilterParameters`) beside the main profile.
Installing it from Apple Configurator needed a confirmation on the phone.

- The profile switches the URL filter on by itself; the app did not have to.
  It ran alongside the main profile's network filter.
- **The profile cannot carry the address-splitting setting.** Apple documents
  no key for it, and the profile-installed filter came up matching exact
  addresses only. The app can set `urlParsingConfiguration` on the
  profile-installed configuration and save it, after which the sections match
  again. So the app has to do this once after the profile is installed.
- **The profile does not protect the filter from the app.** With the profile
  installed, the app's own calls switched the filter off and then removed its
  configuration; the profile stayed listed while nothing was being filtered.
  Removing and reinstalling the profile brought the filter back. A release
  build must therefore have no way to switch it off.
- The test profile has no removal password, and was removed by hand in
  Settings in a few taps, taking the URL filter with it. The main profile,
  which has one, could not be removed. So the URL filter payload has to live
  inside the password-protected profile to be locked. Not tested: the payload
  inside that profile, and whether Settings shows a separate off switch for
  the filter itself.

### Still open

- Whether Settings offers an off switch for a profile-installed URL filter,
  and the URL filter payload inside the password-protected profile.
- How often lookups time out in ordinary use.
- Sharing this needs hosted lookup servers and Apple's approval.
