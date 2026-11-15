//
//  FilterStatusModel.swift
//  ShortformBeGone
//

import Foundation
import NetworkExtension
import Observation

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

    private(set) var state: State = .checking
    /// The rules in force: the profile's when installed, otherwise the standard set.
    private(set) var rules = FilterRules.standard
    private(set) var rulesComeFromProfile = false

    func refresh() async {
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
