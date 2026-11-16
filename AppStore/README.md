# App Store submission

Everything for the listing, and what still has to be done by hand.

## Listing text

**Name** (30 max): `ShortformBeGone`

**Subtitle** (30 max): `Block short video and feeds`

**Promotional text** (170 max):
`A lock on short-form video that survives a weak moment. Free, private, no account. Needs a one-time setup with a Mac.`

**Keywords** (100 max):
`short video,video blocker,content filter,doomscroll,focus,attention,wellbeing,infinite scroll`

No other company's product names here or in the subtitle: App Review rejects those. The description may name what is blocked.

**Category:** Productivity. Secondary: Health & Fitness.

**Age rating:** answer "None" to every content question (4+).

**Price:** Free. No in-app purchases.

**Description:**

```
ShortformBeGone blocks short-form, infinite-scroll video on your iPhone or iPad: Instagram Reels, YouTube Shorts, TikTok and feeds like them. Messaging, long-form video and ordinary browsing keep working.

WORKS IN A MINUTE
The app adds two Safari extensions. Switch on the ShortformBeGone content blocker in Settings and Shorts and Reels stop loading in Safari straight away. Switch on ShortformBeGone Guard and allow it for YouTube, Instagram, Facebook and Snapchat, and you are also taken back to the home page when you reach a Short or Reel from inside a site you already have open. Long-form YouTube keeps working.

A LOCK FOR WHEN WILLPOWER RUNS OUT
A blocker you can switch off in a tap does not survive a weak moment. For people who have tried app timers and deleted-then-reinstalled their way through every softer option, the app includes a full guide to locking your device down: a content filter that cannot be switched off in Settings, the apps themselves blocked, and a removal password that you hand to someone else.

The lock needs a Mac and erases your device once. iOS only allows it on a supervised device, which means a one-time erase and restore using Apple Configurator (free). The app walks you through it, including what to back up first.

WHAT IT BLOCKS
• Whole sites that are only a short-form feed, such as tiktok.com
• Just the short-form sections of sites worth keeping: youtube.com/shorts, instagram.com/reel and /explore, facebook.com/reel and /watch, snapchat.com/spotlight
• The links and shelves that lead into them
• With the lock: the apps themselves, other browsers, and deleting the filter

WHAT IT LEAVES ALONE
• Long-form YouTube in Safari
• Instagram and Facebook messages and posts on the web
• Everything else

IN THE APP
• Status: which layers are running
• Rules: what is blocked, and a box to test any address
• Setup: the full guide, with a link to the profile for your Mac

PRIVATE BY DESIGN
Safari applies the blocking rules itself; the app never sees what you browse. The Guard runs only on the four sites it covers, looks only at the page address, and keeps nothing. The content filter checks each address against a list on your device and keeps no history. No account, no analytics, no ads, no purchases. Nothing leaves your device.

Free, and staying free.
```

**What's New (1.0):** `First release.`

## App Privacy answers

- Data collection: **No, we do not collect data from this app.**
- Tracking: No.

## App Review notes

Paste into "Notes" under App Review Information:

```
ShortformBeGone blocks short-form video (Reels, Shorts, TikTok-style feeds) for people who want it off their own device.

WHY THIS APP EXISTS
I built it for myself. Short-form video feeds were costing me hours and attention, and every tool I tried (app timers, Screen Time limits, blockers) left the off switch with me, so each one lasted until the first weak evening. Blocking the sites and apps outright was not the answer either: long-form YouTube, and messages and posts on Instagram and Facebook, are worth keeping. I could not find an app that removes only the short-form sections of those sites and can also be locked so that the person using it cannot undo it on impulse. ShortformBeGone puts those pieces together: two Safari extensions that work at once on any device, a network content filter for a supervised device, and a guide to supervising your own device with a removal password held by someone you trust. It is free, open source (https://github.com/agentsee-work/ShortformBeGone), collects nothing, and is offered to other people in the same position.

TO TEST ON ANY DEVICE, NO SIGN-IN:
1. Open Settings > Apps > Safari > Extensions. Switch on ShortformBeGone, and ShortformBeGone Guard (allow it for youtube.com).
2. In Safari, open youtube.com/shorts or instagram.com/reels: they do not load. youtube.com/watch?v=... still plays.
3. In the app, the Status tab shows "Safari blocker: On". The Rules tab lists the rules; type "youtube.com/shorts/abc" into "Test an address" to see it matched.

The app has three parts:
- A Safari content blocker extension. Works on any device, as above.
- A Safari web extension ("Guard") with one content script and no background page. On youtube.com, instagram.com, facebook.com and snapchat.com it reads the page address and returns to the site's home page when the address is a short-form section opened without a page load. It collects and sends nothing.
- A network content filter (NEFilterDataProvider + NEFilterControlProvider). As documented in TN3134, this only runs on a supervised device, where it is enabled by a com.apple.webcontent-filter configuration profile. The app never calls NEFilterManager.saveToPreferences. On a review device the Status tab reports it as "Not set up", which is expected.

The Setup tab is a guide to supervising one's own device. The app does not contain, install or offer a configuration profile: its "Install the profile" step shares a link to the app's web page (https://agentsee.work/shortformbegone/), where the user downloads the profile template on their own Mac and installs it themselves with Apple Configurator.

To see the network filter running: supervise a test device with Apple Configurator, install the app, then install the profile with Apple Configurator. The Status tab turns green.

Privacy: neither extension keeps history or makes network connections. The app collects no data and contains no third-party code.
```

A short screen recording of the filter working on your supervised phone, attached to the review notes, will help a lot.

## Screenshots

In `AppStore/screenshots/`, already at the required sizes:

| Folder | Size | App Store Connect slot |
| --- | --- | --- |
| `iPhone 18 Pro` | 1206 × 2622 | iPhone with Dynamic Island, medium display (6.1" or 6.3"); the slot the version page shows first |
| `iPhone 18 Pro Max` | 1320 × 2868 | iPhone 6.9", under View All Sizes in Media Manager |
| `iPhone Duo` | 1398 × 2034 | iPhone Duo (optional; earns the "made for iPhone Duo" badge) |
| `iPad Pro 13-inch (M5)` | 2064 × 2752 | iPad 13" |

Suggested order: `1-status`, `2-rules-blocked`, `3-setup`, `4-install-profile`. Regenerate with `tools/screenshots.sh`.

## To do by hand

1. **Sign in to Xcode** with the developer account (Xcode → Settings → Accounts). No signing certificate is on this Mac yet.
2. **Open the project and let Xcode register the five App IDs** (the app and its four extensions). Select each of those five targets → Signing & Capabilities and check there are no errors. The Network Extensions capability (Content Filter) is already declared in the entitlements of the app and the two filter extensions.
3. **Test on your supervised phone:** run from Xcode once, then install the profile. Its `PluginBundleID` is already `agentsee.ShortformBeGone`.
4. **Privacy policy URL:** `https://agentsee.work/shortformbegone/privacy/`. **Support URL:** `https://agentsee.work/shortformbegone/support/`. **Marketing URL:** `https://agentsee.work/shortformbegone/`. **Contact email** (App Review Information and the app's About screen): `apps@agentsee.work`; the inbox must exist before submitting.
5. **Create the app in App Store Connect** with bundle ID `agentsee.ShortformBeGone`, and paste in the text above.
6. **Archive and upload:** Product → Archive → Distribute App → App Store Connect.
7. **Submit for review** with the review notes above.

## Review risk

Lower than before: the Safari blocker works on a reviewer's ordinary device, so the app does something visible without supervision, and the profile is no longer inside the app (guideline 5.5 restricts apps that offer configuration profiles). The network filter still cannot be shown on an unsupervised device; the review notes explain that. A screen recording of the full lock on your supervised phone is still worth attaching.
