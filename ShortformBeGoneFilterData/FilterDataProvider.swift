//
//  FilterDataProvider.swift
//  ShortformBeGoneFilterData
//
//  Decides, for every new network flow, whether it may proceed. It runs in a
//  sandbox with no network or disk access of its own, and nothing it sees
//  leaves the device.
//

import NetworkExtension
import os

final class FilterDataProvider: NEFilterDataProvider {

    private let log = Logger(subsystem: "shortformfilter", category: "data")
    private var rules = FilterRules.standard
    #if DEBUG
    /// Debug builds only: set `TraceFlows` to true in the profile's VendorConfig
    /// to log what every flow looks like. Never compiled into release builds,
    /// because it writes the addresses you visit to the system log.
    private var traceFlows = false
    #endif

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        rules = FilterRules(vendorConfiguration: filterConfiguration.vendorConfiguration)
        #if DEBUG
        traceFlows = filterConfiguration.vendorConfiguration?["TraceFlows"] as? Bool ?? false
        #endif
        log.notice("Filter started: \(self.rules.denyHosts.count, privacy: .public) host rules, \(self.rules.denyPaths.count, privacy: .public) path rules")
        completionHandler(nil)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        log.notice("Filter stopped, reason \(reason.rawValue, privacy: .public)")
        completionHandler()
    }

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        #if DEBUG
        if traceFlows {
            let host = (flow as? NEFilterSocketFlow)?.remoteHostname ?? "-"
            let urlText = flow.url.map { ($0.host ?? "-") + $0.path } ?? "-"
            log.notice("TRACE \(String(describing: type(of: flow)), privacy: .public) url=\(urlText, privacy: .public) host=\(host, privacy: .public) app=\(flow.sourceAppIdentifier ?? "-", privacy: .public)")
        }
        #endif
        guard let match = match(for: flow) else { return .allow() }
        if rules.logMatches {
            log.notice("Blocked by rule \(match.rule, privacy: .public)")
        }
        return .drop()
    }

    private func match(for flow: NEFilterFlow) -> FilterRules.Match? {
        // Safari and web views report the full URL.
        if let url = flow.url, let match = rules.match(url: url) {
            return match
        }
        // Apps' own connections only report where they are going.
        if let socketFlow = flow as? NEFilterSocketFlow,
           let host = socketFlow.remoteHostname,
           let match = rules.match(host: host) {
            return match
        }
        return nil
    }
}
