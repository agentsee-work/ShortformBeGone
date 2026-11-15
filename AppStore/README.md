# App Store submission

Everything for the listing, and what still has to be done by hand.

## Listing text

**Name** (30 max): `ShortformBeGone`

**Subtitle** (30 max): `Block Reels, Shorts and feeds`

**Promotional text** (170 max):
`A lock on short-form video that survives a weak moment. Free, private, no account. Needs a one-time setup with a Mac.`

**Keywords** (100 max):
`reels,shorts,tiktok,blocker,content filter,doomscroll,focus,screen time,digital wellbeing,supervised`

**Category:** Productivity. Secondary: Health & Fitness.

**Age rating:** answer "None" to every content question (4+).

**Price:** Free. No in-app purchases.

**Description:**

```
ShortformBeGone blocks short-form, infinite-scroll video on your iPhone or iPad: Instagram Reels, YouTube Shorts, TikTok and feeds like them. Messaging, long-form video and ordinary browsing keep working.

It is built for people who have tried app timers and deleted-then-reinstalled their way through every softer option. The lock cannot be switched off in Settings, and removing it needs a password that you hand to someone else.

IMPORTANT: SETUP NEEDS A MAC AND ERASES YOUR DEVICE ONCE
iOS only runs a content filter like this on a supervised device. Supervising is a one-time erase and restore using Apple Configurator (free) on a Mac. The app walks you through it step by step, including what to back up first. Until that is done, the app can show you the rules and the guide but cannot block anything.

WHAT IT BLOCKS
• Whole sites that are only a short-form feed, such as tiktok.com, in every app
• Just the short-form sections of sites worth keeping: youtube.com/shorts, instagram.com/reel and /explore, facebook.com/reel and /watch, snapchat.com/spotlight
• With the included configuration profile: the apps themselves, other browsers, and deleting the filter

WHAT IT LEAVES ALONE
• Long-form YouTube in Safari
• Instagram and Facebook messages and posts on the web
• Everything else

IN THE APP
• Status: whether the filter is running
• Rules: what is blocked, and a box to test any address
• Setup: the full guide, and the profile ready to send to your Mac

PRIVATE BY DESIGN
The filter checks each address against a list on your device and keeps no history. It has no network access of its own. No account, no analytics, no ads, no purchases. Nothing leaves your device.

The rules are yours to change: edit two lists in the profile.

Free, and staying free.
```

**What's New (1.0):** `First release.`

## App Privacy answers

- Data collection: **No, we do not collect data from this app.**
- Tracking: No.

## App Review notes

Paste into "Notes" under App Review Information:

```
ShortformBeGone is a content filter (NEFilterDataProvider + NEFilterControlProvider) for people who want to block short-form video on their own device.

As documented by Apple (TN3134), a content filter provider on iOS only runs on a supervised device, where it is enabled by a com.apple.webcontent-filter configuration profile. The app therefore cannot enable the filter on an ordinary review device, and does not attempt to: it never calls NEFilterManager.saveToPreferences.

What works on any device, with no sign-in:
- Status tab: reports that the filter is not set up.
- Rules tab: lists the rules; type e.g. "youtube.com/shorts/abc" into "Test an address" to see it matched, and "youtube.com/watch?v=abc" to see it allowed.
- Setup tab: the full guide. Step 3 shares the configuration profile template (bundled in the app) and a small shell script that the user runs on their own Mac to set the profile's removal password. The script is not executed on the device.

To see the filter running: supervise a test device with Apple Configurator, install the app, then install the profile from Setup > Install the profile using Apple Configurator. The Status tab turns green and youtube.com/shorts stops loading in Safari.

Privacy: the filter extension keeps no history and makes no network connections. The app collects no data and contains no third-party code.
```

A short screen recording of the filter working on your supervised phone, attached to the review notes, will help a lot.

## Screenshots

In `AppStore/screenshots/`, already at the required sizes:

| Folder | Size | App Store Connect slot |
| --- | --- | --- |
| `iPhone 18 Pro Max` | 1320 × 2868 | iPhone 6.9" |
| `iPad Pro 13-inch (M5)` | 2064 × 2752 | iPad 13" |

Suggested order: `1-status`, `2-rules-blocked`, `3-setup`, `4-install-profile`. Regenerate with `tools/screenshots.sh`.

## To do by hand

1. **Sign in to Xcode** with the developer account (Xcode → Settings → Accounts). No signing certificate is on this Mac yet.
2. **Open the project and let Xcode register the three App IDs.** Select each of the three targets → Signing & Capabilities and check there are no errors. The Network Extensions capability (Content Filter) is already declared in each target's entitlements file.
3. **Test on your supervised phone:** run from Xcode once, then install the profile. Its `PluginBundleID` is already `agentsee.ShortformBeGone`.
4. **Privacy policy URL:** `https://github.com/agentsee-work/ShortformBeGone/blob/main/PRIVACY.md`. **Support URL:** `https://github.com/agentsee-work/ShortformBeGone/issues`.
5. **Create the app in App Store Connect** with bundle ID `agentsee.ShortformBeGone`, and paste in the text above.
6. **Archive and upload:** Product → Archive → Distribute App → App Store Connect.
7. **Submit for review** with the review notes above.

## Review risk

The app is unusual: it does nothing visible on an unsupervised device. Apple may ask for a demonstration, or push back under guideline 2.1 (cannot verify) or 4.2 (minimal functionality). The review notes and a screen recording are the answer. If it is rejected, the fallbacks are TestFlight public links (builds last 90 days) or sharing the source so others can build it themselves.
