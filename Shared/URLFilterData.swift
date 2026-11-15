//
//  URLFilterData.swift
//  Shared between the app, the URL filter extension and the database tool.
//
//  The system URL filter (iOS 26 and later) checks every address requested
//  through WebKit and URLSession. It first asks an on-device Bloom filter
//  "could this be on the list?", and only for possible matches asks a lookup
//  server, through a private query the server cannot read.
//  This file produces both: the list of keys the server holds, and the Bloom
//  filter built from the same keys.
//

import Foundation

nonisolated enum URLFilterData {

    /// Subdomains listed explicitly as well, so that matching does not depend
    /// on the system walking up from `m.youtube.com` to `youtube.com`.
    static let extraSubdomains = ["m", "music"]

    /// The keys to block: addresses without a scheme, lowercased.
    /// The system checks every path prefix of a requested address, so
    /// `youtube.com/shorts` covers everything beneath it.
    static func keys(for rules: FilterRules = .standard) -> [String] {
        var keys: [String] = []
        for host in rules.denyHosts {
            keys.append(host)
            keys += extraSubdomains.map { "\($0).\(host)" }
        }
        for path in rules.denyPaths {
            keys.append(path.text)
            keys += extraSubdomains.map { "\($0).\(path.text)" }
        }
        var seen = Set<String>()
        return keys.filter { seen.insert($0).inserted }
    }

    /// The lookup server's input file, in protobuf text format.
    static func databaseText(for rules: FilterRules = .standard) -> String {
        let rows = keys(for: rules).map { "{ keyword: \"\($0)\", value: \"1\" }" }
        return "rows: [\n  " + rows.joined(separator: ",\n  ") + "\n]\n"
    }
}

/// A Bloom filter in the layout the system URL filter reads: FNV-1a and
/// MurmurHash3 (32-bit) combined by double hashing, bits stored low bit first.
nonisolated struct URLPrefilter: Equatable, Sendable {
    let bits: Data
    let bitCount: UInt32
    let hashCount: UInt32
    let murmurSeed: UInt32
    /// Changes whenever the contents change, so the system knows to reload.
    let tag: String

    init(keys: [String], falsePositiveTolerance: Double = 0.001, murmurSeed: UInt32 = 0x5B6F_1D2A) {
        let count = Double(max(keys.count, 1))
        let bitCount = UInt32((-(count * log(falsePositiveTolerance)) / pow(log(2.0), 2)).rounded(.up))
        let hashCount = UInt32(((Double(bitCount) / count) * log(2.0)).rounded(.up))
        var bits = Data(count: Int((bitCount + 7) / 8))

        for key in keys {
            let data = Data(key.utf8)
            let fnv = URLPrefilter.fnv1a(data)
            let murmur = URLPrefilter.murmur3(data, seed: murmurSeed)
            for round in 0..<hashCount {
                let index = Int((fnv &+ round &* murmur) % bitCount)
                bits[index / 8] |= UInt8(1 << (index % 8))
            }
        }

        self.bits = bits
        self.bitCount = bitCount
        self.hashCount = hashCount
        self.murmurSeed = murmurSeed
        self.tag = "\(keys.count)-\(String(URLPrefilter.fnv1a(Data(keys.joined(separator: "\n").utf8)), radix: 16))"
    }

    func mightContain(_ key: String) -> Bool {
        let data = Data(key.utf8)
        let fnv = URLPrefilter.fnv1a(data)
        let murmur = URLPrefilter.murmur3(data, seed: murmurSeed)
        return (0..<hashCount).allSatisfy { round in
            let index = Int((fnv &+ round &* murmur) % bitCount)
            return bits[index / 8] & UInt8(1 << (index % 8)) != 0
        }
    }

    static func fnv1a(_ data: Data) -> UInt32 {
        var hash: UInt32 = 0x811c_9dc5
        for byte in data {
            hash = (hash ^ UInt32(byte)) &* 0x0100_0193
        }
        return hash
    }

    static func murmur3(_ data: Data, seed: UInt32) -> UInt32 {
        let bytes = [UInt8](data)
        let c1: UInt32 = 0xcc9e_2d51, c2: UInt32 = 0x1b87_3593
        var hash = seed
        let blockCount = bytes.count / 4

        func mix(_ value: UInt32) -> UInt32 {
            var k = value &* c1
            k = (k << 15) | (k >> 17)
            return k &* c2
        }

        for block in 0..<blockCount {
            let i = block * 4
            let k = UInt32(bytes[i]) | UInt32(bytes[i + 1]) << 8 | UInt32(bytes[i + 2]) << 16 | UInt32(bytes[i + 3]) << 24
            hash ^= mix(k)
            hash = (hash << 13) | (hash >> 19)
            hash = hash &* 5 &+ 0xe654_6b64
        }

        var tail: UInt32 = 0
        let tailStart = blockCount * 4
        for offset in stride(from: bytes.count - tailStart - 1, through: 0, by: -1) {
            tail = (tail << 8) | UInt32(bytes[tailStart + offset])
        }
        if bytes.count > tailStart { hash ^= mix(tail) }

        hash ^= UInt32(bytes.count)
        hash ^= hash >> 16
        hash = hash &* 0x85eb_ca6b
        hash ^= hash >> 13
        hash = hash &* 0xc2b2_ae35
        hash ^= hash >> 16
        return hash
    }
}
