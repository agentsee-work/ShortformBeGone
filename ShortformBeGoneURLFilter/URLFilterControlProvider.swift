//
//  URLFilterControlProvider.swift
//  ShortformBeGoneURLFilter
//
//  Supplies the system URL filter with its on-device prefilter. The system
//  does the filtering; this extension never sees an address.
//

import ExtensionFoundation
import NetworkExtension
import os

@main
final class URLFilterControlProvider: NEURLFilterControlProvider {

    private let log = Logger(subsystem: "shortformfilter", category: "urlfilter")

    required init() {}

    func start() async throws {
        log.notice("URL filter provider started")
    }

    func stop(reason: NEProviderStopReason) async throws {
        log.notice("URL filter provider stopped, reason \(reason.rawValue, privacy: .public)")
    }

    func fetchPrefilter(existingPrefilterTag: String?) async throws -> NEURLFilterPrefilter? {
        let prefilter = URLPrefilter(keys: URLFilterData.keys())
        guard existingPrefilterTag != prefilter.tag else {
            log.notice("Prefilter unchanged (\(prefilter.tag, privacy: .public))")
            return nil
        }
        log.notice("Supplying prefilter \(prefilter.tag, privacy: .public): \(prefilter.bitCount, privacy: .public) bits, \(prefilter.hashCount, privacy: .public) hashes")
        return NEURLFilterPrefilter(
            data: .smallFilter(prefilter.bits),
            tag: prefilter.tag,
            bitCount: Int(prefilter.bitCount),
            hashCount: Int(prefilter.hashCount),
            murmurSeed: prefilter.murmurSeed
        )
    }
}
