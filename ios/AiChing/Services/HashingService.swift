import Foundation
import CryptoKit

// MARK: - Cryptographic Hashing Service
/// Assembles the entropy payload and computes SHA-256.
/// Maps hash bytes to I Ching line values using Yarrow-stalk probability.
struct HashingService: Sendable {

    /// Complete computation: payload → SHA-256 → 6 line values
    /// - Returns: A HexagramResult with primary/secondary indices and moving lines.
    static func compute(from payload: EntropyPayload) -> HexagramResult {
        let hash = computeSHA256(payload: payload)
        let lineValues = mapToLines(hash: hash)
        return HexagramResult(lineValues: lineValues)
    }

    /// Compute SHA-256 of the serialized entropy payload.
    static func computeSHA256(payload: EntropyPayload) -> Data {
        let serialized = payload.serialize()
        let hash = SHA256.hash(data: serialized)
        return Data(hash)
    }

    /// Map first 6 bytes of SHA-256 output to LineValues using Yarrow-stalk thresholds.
    /// - Parameter hash: 32-byte SHA-256 digest.
    /// - Returns: Array of 6 LineValues (bottom → top).
    static func mapToLines(hash: Data) -> [LineValue] {
        guard hash.count >= 6 else {
            // Fallback: pad with zeros if hash is unexpectedly short
            return (0..<6).map { _ in .youngYin }
        }

        return (0..<6).map { i in
            let byte = hash[i] // 0–255
            let normalized = Double(byte) / 256.0 // 0.0–0.996
            return LineValue.from(yarrowValue: normalized)
        }
    }

    /// Generate a hex string representation of the hash for persistence.
    static func hashHex(hash: Data) -> String {
        hash.map { String(format: "%02x", $0) }.joined()
    }

    /// Full computation returning hash hex string alongside result.
    static func computeWithHash(from payload: EntropyPayload) -> (result: HexagramResult, hashHex: String) {
        let hash = computeSHA256(payload: payload)
        let lineValues = mapToLines(hash: hash)
        let result = HexagramResult(lineValues: lineValues)
        let hex = hashHex(hash: hash)
        return (result, hex)
    }
}

// MARK: - Verification & Testing Support
extension HashingService {

    /// Deterministic test: given exact inputs, should produce exact outputs.
    /// Used for unit testing the hash-to-line mapping.
    static func testMapping() -> Bool {
        // Test all 256 byte values map to valid LineValues
        for byte in 0...255 {
            let data = Data([UInt8(byte)])
            let lines = mapToLines(hash: data + Data(repeating: 0, count: 5))
            guard lines.count == 6 else { return false }
            for line in lines {
                if ![6, 7, 8, 9].contains(line.rawValue) { return false }
            }
        }
        // Verify probability distribution is roughly Yarrow-like
        var counts = [LineValue: Int]()
        let iterations = 100_000
        for _ in 0..<iterations {
            let randomBytes = (0..<6).map { _ in UInt8.random(in: 0...255) }
            let data = Data(randomBytes)
            let lines = mapToLines(hash: data + Data(repeating: 0, count: 26))
            counts[lines[0], default: 0] += 1
        }
        // Check rough proportions (allowing 15% tolerance for randomness)
        let oldYinRatio = Double(counts[.oldYin] ?? 0) / Double(iterations)
        let youngYangRatio = Double(counts[.youngYang] ?? 0) / Double(iterations)
        let youngYinRatio = Double(counts[.youngYin] ?? 0) / Double(iterations)
        let oldYangRatio = Double(counts[.oldYang] ?? 0) / Double(iterations)

        // Expected: 6.25%, 31.25%, 43.75%, 18.75%
        let ratioOk = abs(oldYinRatio - 0.0625) < 0.03 &&
                      abs(youngYangRatio - 0.3125) < 0.05 &&
                      abs(youngYinRatio - 0.4375) < 0.05 &&
                      abs(oldYangRatio - 0.1875) < 0.04
        return ratioOk
    }
}
