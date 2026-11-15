//
//  FilterControlProvider.swift
//  ShortformBeGoneFilterControl
//
//  iOS content filters are a pair: the data provider makes the decisions and
//  this control provider would fetch rule updates. All rules arrive in the
//  configuration profile, so there is nothing to fetch and this stays minimal.
//

import NetworkExtension

final class FilterControlProvider: NEFilterControlProvider {

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func handleNewFlow(_ flow: NEFilterFlow, completionHandler: @escaping (NEFilterControlVerdict) -> Void) {
        // Only reached if the data provider asks for more rules, which it never does.
        completionHandler(.allow(withUpdateRules: false))
    }
}
