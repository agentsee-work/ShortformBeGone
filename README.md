# ShortformBeGone

A free iPhone and iPad content filter that blocks short-form, infinite-scroll video (Reels, Shorts, TikTok-style feeds) with a lock you can't casually undo. Messaging, long-form YouTube and normal browsing keep working.

It has no account, no ads, no purchases and collects no data. See [PRIVACY.md](PRIVACY.md).

## How it works

| Layer | What it does | How hard to undo |
| --- | --- | --- |
| 1. Supervised configuration profile | Blocks the apps by bundle ID, blocks other browsers, blocks app deletion and erase from Settings | Needs the removal password or a full restore from a computer |
| 2. ShortformBeGone content filter | Checks the full URL of every Safari and web-view request, and the hostname of every app's connections, against your rules | Locked by the profile; the rules live in the profile too |
| 3. Account settings | YouTube watch history off, which removes home-feed recommendations | Easy, but it only removes temptation |

iOS only runs a content filter like this on a **supervised** device. Supervising means a one-time erase with Apple Configurator on a Mac. That is the price of a lock that holds.

| Flow | What the filter sees | Rule used |
| --- | --- | --- |
| Safari and web views | Full URL, e.g. `https://m.youtube.com/shorts/abc` | `DenyHosts` or `DenyPaths` |
| Apps' own connections | Hostname only | `DenyHosts` |

## What you need

- A Mac with [Apple Configurator](https://apps.apple.com/app/apple-configurator/id1037126344) (free) and enough space for a phone backup
- A USB cable (direct port, no hub)
- The ShortformBeGone app on the phone
- A keyholder or timed lockbox for the removal password
- About a day, most of it waiting

You do **not** need an Apple Developer account or Xcode when you install the app from the App Store.

## Setup

The app's Setup tab carries these steps too.

### 1. Get ready

The erase in step 2 is the only risky part. Finish all of this first.

- **Start now:** turn off Find My (Settings → your name → Find My). With Stolen Device Protection on, iOS makes you wait an hour, then gives you a short window to finish.
- **Sign-ins:** move authenticator codes to a password manager you can reach from another device; switch phone-approval logins to another method; save recovery codes off the phone; check how your bank, work apps and eSIM handle a new phone.
- **Backups:** unpair the Apple Watch; back up WhatsApp and Signal in-app; turn on iCloud sync for Messages, Photos, Health and Passwords; make an encrypted Finder backup as a safety net; run an iCloud backup last.
- **The lock:** decide who holds the removal password. Delete apps you no longer want, because deleting needs the password once the profile is on.

### 2. Supervise the device

> **Restore from iCloud during setup, never from the Mac.** Restoring a Mac backup made before supervision removes supervision.

1. Keep the Mac awake: `caffeinate -dimsu` in Terminal.
2. Connect the phone, unlock it, tap **Trust**.
3. Apple Configurator → select the phone → **Prepare**.
4. **Manual Configuration**, tick **Supervise devices**, leave "Allow devices to pair with other computers" ticked.
5. **Do not enroll in MDM**. Skip any Apple Business Manager sign-in.
6. Create an organisation (e.g. "Self") and let it generate a supervision identity. Back that up.
7. Setup Assistant: **Show all steps**.
8. **Prepare**. The phone is erased.
9. On the phone: **Apps & Data → Restore from iCloud Backup**.
10. Check Apple Configurator shows the phone as supervised (or `cfgutil get isSupervised`) before continuing.

Configurator is flaky. If Prepare hangs or fails, quit it, reconnect and run Prepare again; it is safe to repeat.

### 3. Install the profile

1. In the app: Setup → Install the profile → **Send the profile to your Mac**. Two files arrive in Downloads: `no-shortform.mobileconfig` and `set-removal-password.sh`. (Both are also in [`Profile/`](Profile).)
2. Open the profile in a text editor and delete the lines for apps you need to keep. Edit `DenyHosts` / `DenyPaths` to change the rules.
3. Set the removal password without seeing it:

   ```bash
   bash ~/Downloads/set-removal-password.sh
   ```

   This writes `no-shortform.locked.mobileconfig` and prints the password. With no printer, add `--to-file`.
4. Apple Configurator → select the phone → **Add → Profiles** → choose the locked copy.
5. Check Settings → General → VPN & Device Management lists "No Short-Form Video" and a content filter, and the app's Status tab is green.
6. Hand the printed password to the keyholder, then delete the locked copy: the password is readable inside it.

### 4. Quieten what is left

- YouTube: turn off and delete watch history at myactivity.google.com.
- Instagram on the web: switch the feed to Following. Facebook: Feeds → Friends.
- Lock your Mac and other devices too.

### 5. Try to get round it

Blocked apps gone and not installable; other browsers not installable; profile removal asks for a password; Erase All Content and Settings greyed out; `youtube.com/shorts`, `instagram.com/reels` and `tiktok.com` don't load in Safari or from links in Messages; deleting any app is refused; same on Wi-Fi and mobile data.

## Known gaps

- **Full restore from a computer** removes everything. Deliberate: you can never be locked out for good.
- **Section rules only see the first request on each connection.** Measured on iOS 27.2: the filter is shown one address per connection, not per page. A fresh visit to `youtube.com/shorts` is blocked. But once Safari already has a connection open to the same site (you were just on the YouTube home page, say), opening or tapping into Shorts reuses it and the filter is never asked. The same applies to the Instagram and Facebook section rules. Whole-site rules (`DenyHosts`) do not have this gap. To close it for a site, add it to `DenyHosts` and lose the rest of that site too.
- **Inline video in other apps** (chat, news) isn't covered.
- **Filter failure:** if the extension crashes, traffic may pass until it restarts.
- **New apps** aren't in the list until you add their bundle ID and domain.

## Changing rules or breaking glass

The keyholder enters the removal password, you remove the profile, edit the template, and install it again with a **new** password.

Set `LogMatches` to true in the profile to see what is blocked in Console.app (subsystem `shortformfilter`).

## Building it yourself

Requires Xcode 27 and, to run on a device, a paid Apple Developer account (Network Extensions aren't available to free accounts).

| Target | What it is |
| --- | --- |
| `ShortformBeGone` | The app: status, rules, setup guide |
| `ShortformBeGoneFilterData` | `NEFilterDataProvider`: makes the block decisions |
| `ShortformBeGoneFilterControl` | `NEFilterControlProvider`: required partner, does nothing |
| `Shared/FilterRules.swift` | The rule matcher, used by all three |

If you change the bundle ID, change `PluginBundleID` in the profile to match. A development-signed build expires after a year; an App Store build does not.

```bash
tools/verify-bundle-ids.sh   # check the profile's app IDs against the App Store
tools/screenshots.sh         # regenerate the App Store screenshots
```

Submission notes are in [AppStore/README.md](AppStore/README.md).

## License

[MIT](LICENSE). Copyright (c) 2026 AgentSee.
