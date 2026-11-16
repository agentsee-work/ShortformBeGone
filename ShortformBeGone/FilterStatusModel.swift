//
//  FilterStatusModel.swift
//  ShortformBeGone
//

import Foundation
import NetworkExtension
import Observation
import SafariServices
import os

/// Reads whether the content filter is installed and running on this device.
@Observable
final class FilterStatusModel {

    enum State: Equatable {
        case checking
        /// A filter configuration exists and is switched on.
        case active
        /// A filter configuration exists but is switched off.
        case disabled
        /// No configuration: the profile has not been installed.
        case notInstalled
    }

    enum SafariBlockerState: Equatable {
        case checking
        case on
        /// Installed but not switched on in Settings.
        case off
        /// Safari refused the rule list, or could not be asked.
        case failed(String)
    }

    private static let log = Logger(subsystem: "shortformfilter", category: "app")

    static let safariBlockerIdentifier = (Bundle.main.bundleIdentifier ?? "") + ".SafariBlocker"

    private(set) var state: State = .checking
    private(set) var safariBlocker: SafariBlockerState = .checking
    /// The rules in force: the profile's when installed, otherwise the standard set.
    private(set) var rules = FilterRules.standard
    private(set) var rulesComeFromProfile = false

    func refresh() async {
        await refreshSafariBlocker()
        await refreshFilter()
    }

    /// Gives Safari the current rule list and reads whether the blocker is switched on.
    private func refreshSafariBlocker() async {
        #if DEBUG
        if let demo = UserDefaults.standard.string(forKey: "demoState") {
            safariBlocker = demo == "active" ? .on : .off
            return
        }
        #endif
        do {
            try await SFContentBlockerManager.reloadContentBlocker(withIdentifier: Self.safariBlockerIdentifier)
            let state = try await SFContentBlockerManager.stateOfContentBlocker(withIdentifier: Self.safariBlockerIdentifier)
            safariBlocker = state.isEnabled ? .on : .off
            Self.log.notice("Safari blocker rules loaded; enabled: \(state.isEnabled, privacy: .public)")
        } catch {
            safariBlocker = .failed(error.localizedDescription)
            Self.log.error("Safari blocker failed to load: \(String(describing: error), privacy: .public)")
        }
    }

    private func refreshFilter() async {
        #if DEBUG
        // `-demoState active` shows the running state where no filter can run,
        // such as the Simulator. Used for screenshots.
        if let demo = UserDefaults.standard.string(forKey: "demoState") {
            rulesComeFromProfile = demo != "notInstalled"
            state = switch demo {
            case "active": .active
            case "disabled": .disabled
            default: .notInstalled
            }
            return
        }
        #endif

        let manager = NEFilterManager.shared()
        do {
            try await manager.loadFromPreferences()
        } catch {
            // Loading fails where filters are unsupported; treat as not set up.
            state = .notInstalled
            rules = .standard
            rulesComeFromProfile = false
            return
        }

        guard let configuration = manager.providerConfiguration else {
            state = .notInstalled
            rules = .standard
            rulesComeFromProfile = false
            return
        }
        rules = FilterRules(vendorConfiguration: configuration.vendorConfiguration)
        rulesComeFromProfile = configuration.vendorConfiguration != nil
        state = manager.isEnabled ? .active : .disabled
    }
}
