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

    /// The system URL filter (iOS 26 and later). Prototype: it needs a lookup
    /// server, whose address is baked into the build as SBG_PIR_SERVER_URL.
    enum URLFilterState: Equatable {
        /// This build has no lookup server, or the system is too old.
        case unavailable
        case notConfigured
        case stopped
        case starting
        case running
        case failed(String)
    }

    private(set) var urlFilter: URLFilterState = .unavailable
    /// Whether the URL filter is switched on, whatever state it has reached.
    private(set) var urlFilterEnabled = false

    /// The lookup server this build was made for, if any.
    static var lookupServerURL: URL? {
        guard let configuration = Bundle.main.object(forInfoDictionaryKey: "NSPIRConfiguration") as? [String: Any],
              let text = configuration["PIRServerURL"] as? String, !text.isEmpty else { return nil }
        return URL(string: text)
    }

    /// Must match a token in the lookup server's service-config.json.
    private static let lookupServerToken = "AAAA"

    static let safariBlockerIdentifier = (Bundle.main.bundleIdentifier ?? "") + ".SafariBlocker"

    private(set) var state: State = .checking
    private(set) var safariBlocker: SafariBlockerState = .checking
    /// The rules in force: the profile's when installed, otherwise the standard set.
    private(set) var rules = FilterRules.standard
    private(set) var rulesComeFromProfile = false

    func refresh() async {
        await refreshSafariBlocker()
        await refreshFilter()
        #if DEBUG
        // `-urlFilter on|off|reset|remove` drives the prototype from the Mac.
        if !handledURLFilterCommand, let command = UserDefaults.standard.string(forKey: "urlFilter") {
            handledURLFilterCommand = true
            switch command {
            case "on": await turnOnURLFilter()
            case "off": await turnOffURLFilter()
            case "reset": await resetURLFilterCache()
            case "remove": await removeURLFilter()
            default: break
            }
        }
        #endif
        await refreshURLFilter()
    }

    @ObservationIgnored private var handledURLFilterCommand = false

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

    private func refreshURLFilter() async {
        guard #available(iOS 26.0, *), Self.lookupServerURL != nil else {
            urlFilter = .unavailable
            return
        }
        let manager = NEURLFilterManager.shared
        do {
            try await manager.loadFromPreferences()
        } catch {
            Self.log.notice("URL filter: nothing to load (\(String(describing: error), privacy: .public))")
            urlFilter = .notConfigured
            return
        }
        let status = await manager.status
        let lastError = await manager.lastDisconnectError
        urlFilterEnabled = manager.isEnabled
        Self.log.notice("URL filter: enabled \(manager.isEnabled, privacy: .public), fail closed \(manager.shouldFailClosed, privacy: .public), status \(status.rawValue, privacy: .public), last error \(String(describing: lastError), privacy: .public), server \(manager.pirServerURL?.absoluteString ?? "-", privacy: .public)")
        switch status {
        case .running: urlFilter = .running
        case .starting: urlFilter = .starting
        case .stopped, .stopping:
            if let lastError { urlFilter = .failed(String(describing: lastError)) } else { urlFilter = manager.isEnabled ? .stopped : .notConfigured }
        case .invalid, _:
            if manager.isEnabled, let lastError { urlFilter = .failed(String(describing: lastError)) } else { urlFilter = manager.isEnabled ? .stopped : .notConfigured }
        }
    }

    /// Points the system URL filter at the lookup server and switches it on.
    /// The system asks the person to allow it and to enter the device passcode.
    func turnOnURLFilter() async {
        guard #available(iOS 26.0, *), let server = Self.lookupServerURL else { return }
        let manager = NEURLFilterManager.shared
        do {
            try? await manager.loadFromPreferences()
            try manager.setConfiguration(
                pirServerURL: server,
                pirPrivacyPassIssuerURL: server,
                pirAuthenticationToken: Self.lookupServerToken,
                controlProviderBundleIdentifier: (Bundle.main.bundleIdentifier ?? "") + ".URLFilter"
            )
            // Prototype: let pages through when a lookup cannot be made. Failing
            // closed blocks every page whenever the lookup server is out of reach.
            manager.shouldFailClosed = false
            manager.prefilterFetchInterval = 2700
            manager.isEnabled = true
            try await saveURLFilter(manager)
            Self.log.notice("URL filter: configuration saved")
        } catch {
            Self.log.error("URL filter: could not save configuration: \(String(describing: error), privacy: .public)")
            urlFilter = .failed(String(describing: error))
            return
        }
        await refreshURLFilter()
    }

    /// Switches the system URL filter off, leaving its configuration in place.
    func turnOffURLFilter() async {
        guard #available(iOS 26.0, *) else { return }
        let manager = NEURLFilterManager.shared
        do {
            try await manager.loadFromPreferences()
            manager.isEnabled = false
            try await saveURLFilter(manager)
            Self.log.notice("URL filter: switched off")
        } catch {
            Self.log.error("URL filter: could not switch off: \(String(describing: error), privacy: .public)")
        }
        await refreshURLFilter()
    }

    /// Removes the URL filter's configuration from the device altogether.
    func removeURLFilter() async {
        guard #available(iOS 26.0, *) else { return }
        let manager = NEURLFilterManager.shared
        do {
            try await manager.loadFromPreferences()
            try await manager.removeFromPreferences()
            Self.log.notice("URL filter: configuration removed")
        } catch {
            Self.log.error("URL filter: could not remove configuration: \(String(describing: error), privacy: .public)")
        }
        await refreshURLFilter()
    }

    /// Throws away what the system has cached from the lookup server.
    func resetURLFilterCache() async {
        guard #available(iOS 26.0, *) else { return }
        let manager = NEURLFilterManager.shared
        do {
            try await manager.loadFromPreferences()
            try await manager.resetPIRCache()
            Self.log.notice("URL filter: lookup cache reset")
        } catch {
            Self.log.error("URL filter: could not reset the lookup cache: \(String(describing: error), privacy: .public)")
        }
        await refreshURLFilter()
    }

    /// Saving a configuration that is already in place is reported as an error; it is not one.
    @available(iOS 26.0, *)
    private func saveURLFilter(_ manager: NEURLFilterManager) async throws {
        do {
            try await manager.saveToPreferences()
        } catch {
            if String(describing: error).contains("configurationUnchanged") { return }
            throw error
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
