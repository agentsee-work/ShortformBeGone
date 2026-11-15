//
//  StatusView.swift
//  ShortformBeGone
//

import SwiftUI

struct StatusView: View {
    let filter: FilterStatusModel
    let showSetup: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: symbol)
                            .font(.system(size: 64))
                            .foregroundStyle(tint)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)
                        Text(title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("status-summary")
                }

                Section {
                    LabeledContent {
                        Text(networkFilterText).foregroundStyle(filter.state == .active ? .green : .secondary)
                    } label: {
                        Label("Network filter", systemImage: "network.badge.shield.half.filled")
                    }
                    LabeledContent {
                        Text(safariBlockerText).foregroundStyle(filter.safariBlocker == .on ? .green : .orange)
                    } label: {
                        Label("Safari blocker", systemImage: "safari")
                    }
                    .accessibilityIdentifier("safari-blocker-row")
                    if filter.urlFilter != .unavailable {
                        LabeledContent {
                            Text(urlFilterText).foregroundStyle(filter.urlFilter == .running ? .green : .orange)
                        } label: {
                            Label("URL filter (prototype)", systemImage: "link.badge.plus")
                        }
                        if filter.urlFilterEnabled {
                            Button("Turn off the URL filter", role: .destructive) {
                                Task { await filter.turnOffURLFilter() }
                            }
                        } else {
                            Button("Turn on the URL filter") {
                                Task { await filter.turnOnURLFilter() }
                            }
                        }
                        if case .failed(let reason) = filter.urlFilter {
                            Text(reason).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Layers")
                } footer: {
                    Text(layersFooter)
                }

                if filter.state == .active || filter.state == .disabled {
                    Section("In force") {
                        LabeledContent("Blocked sites", value: "\(filter.rules.denyHosts.count)")
                        LabeledContent("Blocked sections", value: "\(filter.rules.denyPaths.count)")
                        LabeledContent("Rules from", value: filter.rulesComeFromProfile ? "Your profile" : "Standard list")
                    }
                }

                if filter.state == .notInstalled || filter.state == .disabled {
                    Section {
                        Button("Open the setup guide", action: showSetup)
                    } footer: {
                        Text("The filter is switched on by a configuration profile, so that it cannot be switched off in a weak moment. This app cannot turn it on by itself.")
                    }
                }

                Section {
                    Label("Nothing you browse leaves this device. The filter has no network access and keeps no history.", systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("ShortformBeGone")
            .refreshable { await filter.refresh() }
        }
    }

    private var networkFilterText: String {
        switch filter.state {
        case .checking: "Checking…"
        case .active: "On"
        case .disabled: "Off"
        case .notInstalled: "Not set up"
        }
    }

    private var urlFilterText: String {
        switch filter.urlFilter {
        case .unavailable: "Unavailable"
        case .notConfigured: "Not set up"
        case .stopped: "Stopped"
        case .starting: "Starting…"
        case .running: "On"
        case .failed: "Problem"
        }
    }

    private var safariBlockerText: String {
        switch filter.safariBlocker {
        case .checking: "Checking…"
        case .on: "On"
        case .off: "Off"
        case .failed: "Problem"
        }
    }

    private var layersFooter: String {
        switch filter.safariBlocker {
        case .off:
            "Switch the Safari blocker on in Settings → Apps → Safari → Extensions → ShortformBeGone. It blocks Shorts and Reels inside sites that are already open, which the network filter cannot see."
        case .failed(let reason):
            "Safari could not load the blocker: \(reason)"
        default:
            "The network filter blocks whole sites for every app. The Safari blocker blocks the short-form sections inside sites you keep."
        }
    }

    /// The two layers combined into one headline.
    private enum Summary {
        case checking
        /// Both layers on: blocked and locked.
        case blocked
        /// Network filter on, Safari blocker off.
        case needsSafariBlocker
        /// Safari blocker on, but no profile, so nothing is locked.
        case safariOnly
        case filterDisabled
        case notSetUp
    }

    private var summary: Summary {
        let safariOn = filter.safariBlocker == .on
        switch filter.state {
        case .checking: return .checking
        case .active: return safariOn ? .blocked : .needsSafariBlocker
        case .disabled: return .filterDisabled
        case .notInstalled: return safariOn ? .safariOnly : .notSetUp
        }
    }

    private var symbol: String {
        switch summary {
        case .checking: "shield"
        case .blocked: "checkmark.shield.fill"
        case .needsSafariBlocker, .filterDisabled: "exclamationmark.shield.fill"
        case .safariOnly: "shield.lefthalf.filled"
        case .notSetUp: "shield.slash"
        }
    }

    private var tint: Color {
        switch summary {
        case .checking, .notSetUp: .secondary
        case .blocked: .green
        case .needsSafariBlocker, .filterDisabled, .safariOnly: .orange
        }
    }

    private var title: String {
        switch summary {
        case .checking: "Checking…"
        case .blocked: "Short-form video is blocked"
        case .needsSafariBlocker: "Switch on the Safari blocker"
        case .safariOnly: "Blocked in Safari, not locked"
        case .filterDisabled: "Filter installed but switched off"
        case .notSetUp: "Not set up yet"
        }
    }

    private var message: String {
        switch summary {
        case .checking:
            "Looking for the filter and the Safari blocker."
        case .blocked:
            "Both layers are running. Reels, Shorts and TikTok-style feeds are blocked in Safari and in every app."
        case .needsSafariBlocker:
            "The network filter is running, but Shorts and Reels can still be reached from inside a site that is already open. The Safari blocker closes that."
        case .safariOnly:
            "Shorts and Reels are blocked in Safari. Nothing stops you switching the blocker off or using another app, until you finish the setup guide."
        case .filterDisabled:
            "The filter is on this device but not running. Check Settings → General → VPN & Device Management, or reinstall the profile."
        case .notSetUp:
            "Nothing is blocked yet. Start with the Safari blocker, which takes a minute, then follow the setup guide to lock it."
        }
    }
}

#Preview {
    StatusView(filter: FilterStatusModel(), showSetup: {})
}
