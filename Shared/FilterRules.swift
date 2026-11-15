//
//  FilterRules.swift
//  Shared between the app and both filter extensions.
//

import Foundation

/// The block rules the content filter applies.
///
/// Rules normally arrive in the `VendorConfig` dictionary of the configuration
/// profile, so the list can be changed without rebuilding the app. When a
/// profile supplies no rules, `FilterRules.standard` is used.
nonisolated struct FilterRules: Equatable, Sendable {

    /// Keys read from the profile's `VendorConfig` dictionary.
    enum ConfigKey {
        static let denyHosts = "DenyHosts"
        static let denyPaths = "DenyPaths"
        static let logMatches = "LogMatches"
    }

    /// A `host/path-prefix` rule, such as `youtube.com/shorts`.
    struct PathRule: Equatable, Sendable {
        let host: String
        /// Lowercased, always starting with `/`.
        let pathPrefix: String

        init?(_ text: String) {
            var text = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            for scheme in ["https://", "http://"] where text.hasPrefix(scheme) {
                text.removeFirst(scheme.count)
            }
            guard let slash = text.firstIndex(of: "/") else { return nil }
            let host = FilterRules.normalise(host: String(text[..<slash]))
            let path = String(text[slash...])
            guard !host.isEmpty, path.count > 1 else { return nil }
            self.host = host
            self.pathPrefix = path
        }

        var text: String { host + pathPrefix }
    }

    /// Domains blocked entirely, including every subdomain.
    var denyHosts: [String]
    /// URL prefixes blocked on otherwise-allowed domains.
    var denyPaths: [PathRule]
    /// When true, the filter logs each match to the unified log.
    var logMatches: Bool

    init(denyHosts: [String], denyPaths: [String], logMatches: Bool = false) {
        self.denyHosts = denyHosts.map(FilterRules.normalise(host:)).filter { !$0.isEmpty }
        self.denyPaths = denyPaths.compactMap(PathRule.init)
        self.logMatches = logMatches
    }

    /// Builds rules from a profile's `VendorConfig`. Missing lists fall back to
    /// the standard ones, so a profile can override just one of them.
    init(vendorConfiguration: [String: Any]?) {
        let config = vendorConfiguration ?? [:]
        let hosts = config[ConfigKey.denyHosts] as? [String]
        let paths = config[ConfigKey.denyPaths] as? [String]
        self.init(
            denyHosts: hosts ?? FilterRules.standardDenyHosts,
            denyPaths: paths ?? FilterRules.standardDenyPaths,
            logMatches: config[ConfigKey.logMatches] as? Bool ?? false
        )
    }

    // MARK: Matching

    enum Match: Equatable, Sendable {
        case host(String)
        case path(String)

        var rule: String {
            switch self {
            case .host(let rule), .path(let rule): rule
            }
        }
    }

    /// The rule that blocks this URL, if any. Used for Safari and web-view
    /// flows, where the filter sees the full URL.
    func match(url: URL) -> Match? {
        guard let host = url.host else { return nil }
        if let hostMatch = match(host: host) { return hostMatch }
        let host_ = FilterRules.normalise(host: host)
        let path = url.path.isEmpty ? "/" : url.path.lowercased()
        for rule in denyPaths where FilterRules.host(host_, isWithin: rule.host) && path.hasPrefix(rule.pathPrefix) {
            return .path(rule.text)
        }
        return nil
    }

    /// The rule that blocks this hostname, if any. Used for apps' own
    /// connections, where the filter only sees the hostname.
    func match(host: String) -> Match? {
        let host = FilterRules.normalise(host: host)
        guard !host.isEmpty else { return nil }
        for rule in denyHosts where FilterRules.host(host, isWithin: rule) {
            return .host(rule)
        }
        return nil
    }

    /// Checks text typed by a person, which may lack a scheme.
    func match(userEntered text: String) -> Match? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: withScheme) else { return nil }
        return match(url: url)
    }

    // MARK: Helpers

    static func normalise(host: String) -> String {
        var host = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while host.hasSuffix(".") { host.removeLast() }
        while host.hasPrefix(".") { host.removeFirst() }
        return host
    }

    /// True when `host` is `domain` or one of its subdomains.
    static func host(_ host: String, isWithin domain: String) -> Bool {
        host == domain || host.hasSuffix("." + domain)
    }
}

// MARK: - Standard rules

nonisolated extension FilterRules {

    /// Services that are nothing but a short-form feed: blocked outright.
    static let standardDenyHosts = [
        "tiktok.com",
        "tiktokv.com",
        "douyin.com",
        "kwai.com",
        "kuaishou.com",
        "likee.video",
        "triller.co",
        "9gag.com",
        "fb.watch",
    ]

    /// Short-form sections of services that are otherwise worth keeping.
    static let standardDenyPaths = [
        "youtube.com/shorts",
        "youtube.com/youtubei/v1/reel",
        "instagram.com/reel",
        "instagram.com/explore",
        "facebook.com/reel",
        "facebook.com/watch",
        "snapchat.com/spotlight",
    ]

    static let standard = FilterRules(denyHosts: standardDenyHosts, denyPaths: standardDenyPaths)
}
