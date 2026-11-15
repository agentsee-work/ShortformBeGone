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

    private var symbol: String {
        switch filter.state {
        case .checking: "shield"
        case .active: "checkmark.shield.fill"
        case .disabled: "exclamationmark.shield.fill"
        case .notInstalled: "shield.slash"
        }
    }

    private var tint: Color {
        switch filter.state {
        case .checking: .secondary
        case .active: .green
        case .disabled: .orange
        case .notInstalled: .secondary
        }
    }

    private var title: String {
        switch filter.state {
        case .checking: "Checking…"
        case .active: "Short-form video is blocked"
        case .disabled: "Filter installed but switched off"
        case .notInstalled: "Not set up yet"
        }
    }

    private var message: String {
        switch filter.state {
        case .checking:
            "Looking for the content filter."
        case .active:
            "The content filter is running. Reels, Shorts and TikTok-style feeds are blocked in Safari and in every app."
        case .disabled:
            "The filter is on this device but not running. Check Settings → General → VPN & Device Management, or reinstall the profile."
        case .notInstalled:
            "The content filter is not running on this device. Follow the setup guide to supervise the device and install the profile."
        }
    }
}

#Preview {
    StatusView(filter: FilterStatusModel(), showSetup: {})
}
