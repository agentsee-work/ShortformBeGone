//
//  ContentBlockerRules.swift
//  Shared between the app and the Safari content blocker.
//
//  Turns the filter rules into Safari content-blocker rules. Safari applies
//  these to every request a page makes, including the background requests a
//  site makes once it is already open, which the network content filter is
//  never shown.
//

import Foundation

nonisolated enum ContentBlockerRules {

    /// Elements that lead into short-form feeds on sites that stay usable.
    /// Hiding the doors matters as much as blocking the rooms.
    static let hiddenElements: [(site: String, selectors: [String])] = [
        ("youtube.com", [
            "ytm-reel-shelf-renderer",
            "ytm-shorts-lockup-view-model",
            "ytm-shorts-lockup-view-model-v2",
            "ytd-reel-shelf-renderer",
            "ytd-rich-shelf-renderer[is-shorts]",
            "ytm-pivot-bar-item-renderer:has(.pivot-shorts)",
            "a[href^=\"/shorts\"]",
        ]),
        ("instagram.com", [
            "a[href^=\"/reels\"]",
            "a[href^=\"/explore\"]",
        ]),
        // Facebook's Reels tab switches views inside the page, so no address
        // is loaded that a rule could refuse; hiding the tab is the only lever.
        // Its mobile site labels controls rather than linking them, hence the
        // aria-label selectors. They are English-only.
        ("facebook.com", [
            "a[href*=\"/reel/\"]",
            "a[href^=\"/reel\"]",
            "a[href*=\"/reels/\"]",
            "a[href^=\"/watch\"]",
            "a[aria-label^=\"Reels\"]",
            "[role=\"tab\"][aria-label^=\"Reels\"]",
            "[role=\"button\"][aria-label^=\"Reels\"]",
            "[role=\"link\"][aria-label^=\"Reels\"]",
        ]),
    ]

    /// The rule list, as the JSON objects Safari expects.
    static func rules(for rules: FilterRules = .standard) -> [[String: Any]] {
        var list: [[String: Any]] = []

        for host in rules.denyHosts {
            list.append(block(urlFilter: prefix(forHost: host) + "[/:]"))
            list.append(block(urlFilter: prefix(forHost: host) + "$"))
        }
        for path in rules.denyPaths {
            list.append(block(urlFilter: prefix(forHost: path.host) + escape(path.pathPrefix)))
        }
        for entry in hiddenElements {
            list.append([
                "trigger": ["url-filter": ".*", "if-domain": ["*" + entry.site]],
                "action": ["type": "css-display-none", "selector": entry.selectors.joined(separator: ", ")],
            ])
        }
        return list
    }

    static func json(for rules: FilterRules = .standard) throws -> Data {
        try JSONSerialization.data(withJSONObject: self.rules(for: rules), options: [.prettyPrinted, .sortedKeys])
    }

    private static func block(urlFilter: String) -> [String: Any] {
        ["trigger": ["url-filter": urlFilter], "action": ["type": "block"]]
    }

    /// Matches the scheme and any subdomain, then the host itself.
    private static func prefix(forHost host: String) -> String {
        "^https?://([^/]*\\.)?" + escape(host)
    }

    /// Escapes the characters that mean something in Safari's rule syntax.
    private static func escape(_ text: String) -> String {
        var escaped = ""
        for character in text {
            if ".?+*()[]{}^$|\\".contains(character) { escaped.append("\\") }
            escaped.append(character)
        }
        return escaped
    }
}
