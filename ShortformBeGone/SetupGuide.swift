//
//  SetupGuide.swift
//  ShortformBeGone
//
//  The setup steps shown in the app. The README in the source repository
//  carries the same guide in full.
//

import Foundation

struct SetupStep: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let time: String
    let warning: String?
    let sections: [Section]
    var offersProfile = false

    struct Section: Hashable {
        let heading: String?
        let items: [String]
    }
}

enum SetupGuide {

    static let requirements = [
        "A Mac with Apple Configurator (free on the Mac App Store)",
        "A USB cable from this device to the Mac",
        "A current iCloud backup of this device",
        "Someone you trust, or a timed lockbox, to hold a password",
        "About a day, most of it waiting",
    ]

    static let steps: [SetupStep] = [
        SetupStep(
            id: "prepare",
            title: "Get ready",
            summary: "Protect your sign-ins and back up before anything is erased.",
            time: "1–2 hours",
            warning: "Step 2 erases this device. Do not start it until everything here is done.",
            sections: [
                .init(heading: "Start this first", items: [
                    "Turn off Find My: Settings → your name → Find My → Find My iPhone. With Stolen Device Protection on, iOS makes you wait an hour first, so start now.",
                    "When the hour is up you get only a short window: confirm with Face ID, turn Find My off, enter your Apple Account password.",
                ]),
                .init(heading: "Sign-ins", items: [
                    "Move every authenticator code to a password manager you can reach from another device.",
                    "Switch accounts that approve sign-ins on this phone to another method first.",
                    "Save recovery codes for email, Apple Account and bank somewhere off this phone.",
                    "Check how your bank, work apps and eSIM handle a new phone.",
                ]),
                .init(heading: "Backups", items: [
                    "Unpair your Apple Watch, which backs it up to the phone.",
                    "Back up WhatsApp and Signal from inside those apps.",
                    "Turn on iCloud sync for Messages, Photos, Health and Passwords.",
                    "Make an encrypted backup to the Mac in Finder as a safety net.",
                    "Last of all, run an iCloud backup. This is the one you will restore from.",
                ]),
                .init(heading: "The lock", items: [
                    "Decide who or what will hold the removal password: a partner, a timed lockbox, an envelope at work. Not your memory or your password manager.",
                    "Delete any apps you no longer want. Once the profile is on, deleting apps needs the password.",
                ]),
            ]
        ),
        SetupStep(
            id: "supervise",
            title: "Supervise this device",
            summary: "A one-time erase with Apple Configurator that allows locked restrictions.",
            time: "About 1 hour",
            warning: "This erases the device. Restore from iCloud during setup, never from the Mac: restoring a Mac backup removes supervision.",
            sections: [
                .init(heading: "On the Mac", items: [
                    "Keep the Mac awake and on power. In Terminal, run: caffeinate -dimsu",
                    "Connect this device, unlock it and tap Trust.",
                    "In Apple Configurator, select the device and choose Prepare.",
                    "Choose Manual Configuration, tick Supervise devices, and leave “Allow devices to pair with other computers” ticked.",
                    "Choose Do not enroll in MDM. Skip any Apple Business Manager sign-in.",
                    "Create a new organisation, such as “Self”, and let it generate a supervision identity.",
                    "Setup Assistant: choose Show all steps, so that restoring a backup is offered.",
                    "Click Prepare. The device is erased and restarts.",
                ]),
                .init(heading: "On this device", items: [
                    "Go through setup to Apps & Data and choose Restore from iCloud Backup.",
                    "Stay on Wi-Fi and power while apps download.",
                    "Install ShortformBeGone again from the App Store if it has not come back.",
                ]),
                .init(heading: "Check it worked", items: [
                    "Apple Configurator should show the device as supervised. Do not continue until it does.",
                    "Turn Find My back on, pair your Watch, and add Apple Pay cards again.",
                ]),
                .init(heading: "If Configurator misbehaves", items: [
                    "Prepare can hang or fail. Quit Configurator, reconnect the device and run Prepare again; it is safe to repeat.",
                ]),
            ]
        ),
        SetupStep(
            id: "profile",
            title: "Install the profile",
            summary: "The profile blocks the apps, switches on the filter, and locks itself.",
            time: "20 minutes",
            warning: nil,
            sections: [
                .init(heading: "Get the files to the Mac", items: [
                    "Send the profile below to your Mac with AirDrop.",
                    "Download the two helper scripts from the project page (see About).",
                ]),
                .init(heading: "On the Mac", items: [
                    "Open the profile in a text editor and delete the lines for any apps you need to keep. LinkedIn and Threads are marked optional.",
                    "Run set-removal-password.sh. It creates a locked copy of the profile with a random password and prints the password without showing it.",
                    "In Apple Configurator, select the device, then Add → Profiles, and choose the locked copy.",
                ]),
                .init(heading: "Check, then hand over", items: [
                    "Settings → General → VPN & Device Management should list “No Short-Form Video” and a content filter.",
                    "The Status tab in this app should turn green.",
                    "Give the printed password to your keyholder, then delete the locked copy of the profile from the Mac.",
                ]),
            ],
            offersProfile: true
        ),
        SetupStep(
            id: "accounts",
            title: "Quieten what is left",
            summary: "Settings that remove the feeds on sites you can still use.",
            time: "10 minutes",
            warning: nil,
            sections: [
                .init(heading: nil, items: [
                    "YouTube: turn off and delete watch history at myactivity.google.com. The home page then shows no recommendations.",
                    "Instagram on the web: switch the feed to Following.",
                    "Facebook: use Feeds → Friends.",
                    "Lock your Mac and other devices too, or the habit just moves.",
                ]),
            ]
        ),
        SetupStep(
            id: "verify",
            title: "Try to get round it",
            summary: "Test it the way you would at 11pm. Every attempt should fail.",
            time: "10 minutes",
            warning: nil,
            sections: [
                .init(heading: nil, items: [
                    "The blocked apps are gone and cannot be installed again.",
                    "Other browsers cannot be installed.",
                    "Removing the profile asks for a password.",
                    "Erase All Content and Settings is greyed out.",
                    "In Safari, youtube.com/shorts, instagram.com/reels and tiktok.com do not load.",
                    "A reel or Short link opened from Messages or Mail does not load.",
                    "Deleting any app is refused.",
                    "It behaves the same on Wi-Fi and mobile data.",
                ]),
                .init(heading: "Known gaps", items: [
                    "A full restore from a computer removes everything. That takes over an hour, which is the point, and means you can never be locked out for good.",
                    "Video played inline inside other apps, such as chat or news apps, is not covered.",
                    "If the filter stops unexpectedly, traffic may pass until it restarts.",
                ]),
            ]
        ),
    ]
}
