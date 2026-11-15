//
//  ShortformBeGoneTests.swift
//  ShortformBeGoneTests
//

import Foundation
import Testing
@testable import ShortformBeGone

struct FilterRulesTests {

    let rules = FilterRules.standard

    private func blocked(_ text: String) -> Bool {
        rules.match(url: URL(string: text)!) != nil
    }

    @Test(arguments: [
        "https://www.tiktok.com/@someone/video/1",
        "https://tiktok.com",
        "https://vm.tiktok.com/abc",
        "https://m.youtube.com/shorts/abc123",
        "https://www.youtube.com/shorts",
        "https://www.youtube.com/youtubei/v1/reel/reel_item_watch?prettyPrint=false",
        "https://www.instagram.com/reel/Cabc/",
        "https://www.instagram.com/reels/",
        "https://www.instagram.com/explore/",
        "https://m.facebook.com/reel/123",
        "https://www.facebook.com/watch/?v=1",
        "https://fb.watch/abc",
        "https://www.snapchat.com/spotlight",
        "https://9gag.com/",
        "HTTPS://WWW.YOUTUBE.COM/Shorts/abc",
    ])
    func blocksShortFormURLs(_ url: String) {
        #expect(blocked(url))
    }

    @Test(arguments: [
        "https://www.youtube.com/watch?v=abc",
        "https://www.youtube.com/",
        "https://www.youtube.com/feed/subscriptions",
        "https://www.instagram.com/direct/inbox/",
        "https://www.instagram.com/p/Cabc/",
        "https://www.facebook.com/messages",
        "https://www.snapchat.com/",
        "https://example.com/shorts/abc",
        "https://nottiktok.com/",
        "https://tiktok.com.example.org/",
        "https://www.apple.com/",
    ])
    func allowsEverythingElse(_ url: String) {
        #expect(!blocked(url))
    }

    @Test func hostOnlyFlowsUseHostRulesOnly() {
        #expect(rules.match(host: "api.tiktokv.com") == .host("tiktokv.com"))
        #expect(rules.match(host: "TikTok.com.") == .host("tiktok.com"))
        // Path rules cannot apply when only the hostname is known.
        #expect(rules.match(host: "www.youtube.com") == nil)
        #expect(rules.match(host: "") == nil)
    }

    @Test func reportsWhichRuleMatched() {
        let match = rules.match(url: URL(string: "https://m.youtube.com/shorts/abc")!)
        #expect(match == .path("youtube.com/shorts"))
    }

    @Test func userEnteredTextNeedsNoScheme() {
        #expect(rules.match(userEntered: "youtube.com/shorts/abc") != nil)
        #expect(rules.match(userEntered: "  tiktok.com ") != nil)
        #expect(rules.match(userEntered: "youtube.com/watch?v=1") == nil)
        #expect(rules.match(userEntered: "") == nil)
    }

    @Test func vendorConfigurationOverridesStandardRules() {
        let config: [String: Any] = [
            "DenyHosts": ["Reddit.com"],
            "DenyPaths": ["https://x.com/i/videos", "not-a-path-rule", "x.com/"],
            "LogMatches": true,
        ]
        let custom = FilterRules(vendorConfiguration: config)
        #expect(custom.denyHosts == ["reddit.com"])
        #expect(custom.denyPaths.map(\.text) == ["x.com/i/videos"])
        #expect(custom.logMatches)
        #expect(custom.match(host: "old.reddit.com") != nil)
        #expect(custom.match(url: URL(string: "https://tiktok.com")!) == nil)
    }

    @Test func missingVendorConfigurationFallsBackToStandardRules() {
        #expect(FilterRules(vendorConfiguration: nil) == .standard)
        let hostsOnly = FilterRules(vendorConfiguration: ["DenyHosts": ["reddit.com"]])
        #expect(hostsOnly.denyHosts == ["reddit.com"])
        #expect(hostsOnly.denyPaths == FilterRules.standard.denyPaths)
    }
}
