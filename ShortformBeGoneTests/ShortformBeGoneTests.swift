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

    /// The profile template shipped in the app must carry the same rules as the built-in list.
    @Test func bundledProfileMatchesStandardRules() throws {
        let url = try #require(Bundle.main.url(forResource: "no-shortform", withExtension: "mobileconfig"))
        let profile = try #require(try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])
        let payloads = try #require(profile["PayloadContent"] as? [[String: Any]])
        let filter = try #require(payloads.first { $0["PayloadType"] as? String == "com.apple.webcontent-filter" })

        #expect(filter["PluginBundleID"] as? String == Bundle.main.bundleIdentifier)
        #expect(FilterRules(vendorConfiguration: filter["VendorConfig"] as? [String: Any]) == .standard)
        #expect(payloads.contains { $0["RemovalPassword"] as? String == "CHANGE_ME_REMOVAL_PASSWORD" })
    }

    @Test func contentBlockerRulesCoverEveryFilterRule() throws {
        let list = ContentBlockerRules.rules()
        let filters = list.compactMap { ($0["trigger"] as? [String: Any])?["url-filter"] as? String }
        func isBlocked(_ url: String) -> Bool {
            list.contains { rule in
                guard (rule["action"] as? [String: Any])?["type"] as? String == "block",
                      let pattern = (rule["trigger"] as? [String: Any])?["url-filter"] as? String,
                      let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
                return regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) != nil
            }
        }

        #expect(filters.count == list.count)
        #expect(isBlocked("https://m.youtube.com/shorts/abc"))
        #expect(isBlocked("https://m.youtube.com/youtubei/v1/reel/reel_item_watch?prettyPrint=false"))
        #expect(isBlocked("https://www.instagram.com/reels/"))
        #expect(isBlocked("https://tiktok.com"))
        #expect(isBlocked("https://www.tiktok.com/@someone"))
        #expect(!isBlocked("https://m.youtube.com/watch?v=abc"))
        #expect(!isBlocked("https://m.youtube.com/youtubei/v1/player"))
        #expect(!isBlocked("https://nottiktok.com/"))
        #expect(!isBlocked("https://tiktok.com.example.org/"))

        // Safari rejects the whole list if it is not valid JSON.
        let decoded = try JSONSerialization.jsonObject(with: ContentBlockerRules.json())
        #expect((decoded as? [[String: Any]])?.count == list.count)
    }

    /// Apple's sample URL filter ships this exact Bloom filter for these ten keys.
    @Test func prefilterMatchesApplesReferenceFilter() {
        var keys = ["example.com"] + (2...9).map { "example\($0).com" }
        keys.append("example10.com/resource?query=bugs")
        let prefilter = URLPrefilter(keys: keys, murmurSeed: 624_656_550)

        #expect(prefilter.bitCount == 144)
        #expect(prefilter.hashCount == 10)
        #expect(prefilter.bits.map { String(format: "%02x", $0) }.joined() == "76b4df1fdadd4d4c61f0c33238c1dd8f4d26")
    }

    @Test func urlFilterKeysCoverTheRulesAndTheirMobileSubdomains() {
        let keys = URLFilterData.keys()
        #expect(keys.contains("youtube.com/shorts"))
        #expect(keys.contains("m.youtube.com/shorts"))
        #expect(keys.contains("m.youtube.com/youtubei/v1/reel"))
        #expect(keys.contains("tiktok.com"))
        #expect(Set(keys).count == keys.count)
        #expect(keys.allSatisfy { $0 == $0.lowercased() && !$0.contains("://") })

        let prefilter = URLPrefilter(keys: keys)
        #expect(keys.allSatisfy(prefilter.mightContain))
        #expect(!prefilter.mightContain("youtube.com/watch"))
        #expect(URLFilterData.databaseText().contains("{ keyword: \"youtube.com/shorts\", value: \"1\" }"))
    }
}
