//
//  RulesView.swift
//  ShortformBeGone
//

import SwiftUI

struct RulesView: View {
    let filter: FilterStatusModel
    @State private var testAddress = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("youtube.com/shorts/…", text: $testAddress)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("test-address")
                    if !testAddress.trimmingCharacters(in: .whitespaces).isEmpty {
                        testResult
                    }
                } header: {
                    Text("Test an address")
                } footer: {
                    Text("Type or paste a web address to see whether the rules block it.")
                }

                Section {
                    ForEach(filter.rules.denyHosts, id: \.self) { host in
                        Text(host).monospaced()
                    }
                } header: {
                    Text("Blocked sites")
                } footer: {
                    Text(filter.state == .active
                         ? "Blocked completely, including every subdomain, in Safari and for every app."
                         : "Blocked completely, including every subdomain, in Safari. With the network filter set up, they are blocked for every app.")
                }

                Section {
                    ForEach(filter.rules.denyPaths.map(\.text), id: \.self) { path in
                        Text(path).monospaced()
                    }
                } header: {
                    Text("Blocked sections")
                } footer: {
                    Text(filter.state == .active
                         ? "Only addresses starting with these are blocked, in Safari and in-app browsers. The rest of each site keeps working."
                         : "Only addresses starting with these are blocked, in Safari. The rest of each site keeps working.")
                }

                Section {
                    Text(filter.rulesComeFromProfile
                         ? "These rules come from your installed profile. To change them, edit DenyHosts and DenyPaths in the profile and install it again."
                         : "This is the standard list. A profile can replace it: edit DenyHosts and DenyPaths in the profile before installing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Rules")
        }
    }

    @ViewBuilder
    private var testResult: some View {
        if let match = filter.rules.match(userEntered: testAddress) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blocked")
                    Text("by rule \(match.rule)").font(.footnote).foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "nosign").foregroundStyle(.red)
            }
            .accessibilityIdentifier("test-result")
        } else {
            Label {
                Text("Allowed")
            } icon: {
                Image(systemName: "checkmark.circle").foregroundStyle(.green)
            }
            .accessibilityIdentifier("test-result")
        }
    }
}

#Preview {
    RulesView(filter: FilterStatusModel())
}
