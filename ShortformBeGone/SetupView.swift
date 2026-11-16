//
//  SetupView.swift
//  ShortformBeGone
//

import SwiftUI

struct SetupView: View {
    @AppStorage("completedSetupSteps") private var completedSteps = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Setting this up takes real effort, once. That is deliberate: a lock you can undo in a tap does not survive a weak moment.")
                        .font(.subheadline)
                }

                Section("Steps") {
                    ForEach(Array(SetupGuide.steps.enumerated()), id: \.element.id) { index, step in
                        NavigationLink(value: step) {
                            StepRow(number: index + 1, step: step, isDone: isDone(step))
                        }
                    }
                }

                Section("You will need") {
                    ForEach(SetupGuide.requirements, id: \.self) { item in
                        Label(item, systemImage: "circle.fill")
                            .labelStyle(BulletLabelStyle())
                            .font(.subheadline)
                    }
                }

                Section {
                    NavigationLink("About and privacy") { AboutView() }
                }
            }
            .navigationTitle("Setup")
            .navigationDestination(for: SetupStep.self) { step in
                SetupStepView(step: step, isDone: binding(for: step))
            }
        }
    }

    private var doneIDs: Set<String> {
        Set(completedSteps.split(separator: ",").map(String.init))
    }

    private func isDone(_ step: SetupStep) -> Bool {
        doneIDs.contains(step.id)
    }

    private func binding(for step: SetupStep) -> Binding<Bool> {
        Binding(
            get: { isDone(step) },
            set: { done in
                var ids = doneIDs
                if done { ids.insert(step.id) } else { ids.remove(step.id) }
                completedSteps = ids.sorted().joined(separator: ",")
            }
        )
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon
                .font(.system(size: 6))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            configuration.title
        }
    }
}

private struct StepRow: View {
    let number: Int
    let step: SetupStep
    let isDone: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "\(number).circle")
                .font(.title3)
                .foregroundStyle(isDone ? Color.green : Color.accentColor)
                .accessibilityLabel(isDone ? "Done" : "Step \(number)")
            VStack(alignment: .leading, spacing: 3) {
                Text(step.title).font(.headline)
                Text(step.summary).font(.subheadline).foregroundStyle(.secondary)
                Text(step.time).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SetupStepView: View {
    let step: SetupStep
    @Binding var isDone: Bool

    var body: some View {
        List {
            if let warning = step.warning {
                Section {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline.weight(.medium))
                }
            }

            if step.offersProfile {
                Section {
                    ShareLink(item: ProfileFile.page) {
                        Label("Send the download link to your Mac", systemImage: "square.and.arrow.up")
                    }
                } footer: {
                    Text("The link opens the page with two files to download on the Mac: the profile template and a script that locks it. Neither is part of this app. The template has no password until you run the script.")
                }
            }

            ForEach(step.sections, id: \.self) { section in
                Section {
                    ForEach(Array(section.items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text(item)
                        }
                        .font(.subheadline)
                    }
                } header: {
                    if let heading = section.heading { Text(heading) }
                }
            }

            Section {
                Toggle("I have done this step", isOn: $isDone)
            }
        }
        .navigationTitle(step.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum ProfileFile {
    /// Where the profile template and the script that sets its removal
    /// password are published. They are downloaded on the Mac, not shipped here.
    static let page = URL(string: "https://github.com/agentsee-work/ShortformBeGone/tree/main/Profile")!
}

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        List {
            Section("What this app is") {
                Text("ShortformBeGone is a content filter for people who want short-form video off their own device for good. It blocks Reels, Shorts and TikTok-style feeds while leaving messaging, long-form video and ordinary browsing alone.")
                Text("It is free, has no account, no ads and no purchases.")
            }
            .font(.subheadline)

            Section("Privacy") {
                Text("The filter checks each web address against the rule list on this device and either allows or blocks it. It keeps no history, makes no network connections, and sends nothing to anyone. The app collects no data.")
            }
            .font(.subheadline)

            Section("Why it needs a supervised device") {
                Text("iOS only lets a content filter like this run on a supervised device. Supervision is also what makes the lock hold: the filter cannot be switched off in Settings, and the profile cannot be removed without a password you do not keep.")
            }
            .font(.subheadline)

            Section("Help") {
                Link("Email apps@agentsee.work", destination: URL(string: "mailto:apps@agentsee.work")!)
                Link("Report a problem on GitHub", destination: URL(string: "https://github.com/agentsee-work/ShortformBeGone/issues")!)
            }

            Section {
                LabeledContent("Version", value: version)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SetupView()
}
