import Foundation

// MARK: - Hash Function Abstraction

/// Platform-abstracted hash function.
/// Uses CryptoKit (Apple), swift-crypto (Linux), or a minimal fallback.
protocol HashFunction {
    static func hash(data: Data) -> Data
}

/// Platform hash function: uses CryptoKit on Apple platforms,
/// pure Swift SHA-256 elsewhere. Always produces correct SHA-256.
enum PlatformHash: HashFunction {
    static func hash(data: Data) -> Data {
        #if canImport(CryptoKit)
        CryptoKitSHA256(data)
        #else
        sha256(data)
        #endif
    }
}

#if canImport(CryptoKit)
import CryptoKit
private func CryptoKitSHA256(_ data: Data) -> Data {
    Data(SHA256.hash(data: data))
}
#endif

// MARK: - Pure Swift SHA-256

private func sha256(_ data: Data) -> Data {
    let bytes = [UInt8](data)
    let msg = pad(bytes)
    var h = SHA256State()
    for i in stride(from: 0, to: msg.count, by: 64) {
        let block = Array(msg[i..<min(i+64, msg.count)])
        compress(&h, block)
    }
    var out = Data(capacity: 32)
    func appendBE(_ val: UInt32) {
        var big = val.bigEndian
        withUnsafeBytes(of: &big) { out.append(contentsOf: $0) }
    }
    appendBE(h.h0)
    appendBE(h.h1)
    appendBE(h.h2)
    appendBE(h.h3)
    appendBE(h.h4)
    appendBE(h.h5)
    appendBE(h.h6)
    appendBE(h.h7)
    return out
}

private struct SHA256State {
    var h0: UInt32 = 0x6a09e667
    var h1: UInt32 = 0xbb67ae85
    var h2: UInt32 = 0x3c6ef372
    var h3: UInt32 = 0xa54ff53a
    var h4: UInt32 = 0x510e527f
    var h5: UInt32 = 0x9b05688c
    var h6: UInt32 = 0x1f83d9ab
    var h7: UInt32 = 0x5be0cd19
}

private let K: [UInt32] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]

private func pad(_ input: [UInt8]) -> [UInt8] {
    var msg = input
    let len = UInt64(msg.count * 8)
    msg.append(0x80)
    while (msg.count % 64) != 56 {
        msg.append(0x00)
    }
    withUnsafeBytes(of: len.bigEndian) { msg.append(contentsOf: $0) }
    return msg
}

private func compress(_ state: inout SHA256State, _ block: [UInt8]) {
    var W = [UInt32](repeating: 0, count: 64)
    for t in 0..<16 {
        let i = t * 4
        W[t] = (UInt32(block[i]) << 24) | (UInt32(block[i+1]) << 16) | (UInt32(block[i+2]) << 8) | UInt32(block[i+3])
    }
    for t in 16..<64 {
        let s0 = rotateRight(W[t-15], 7) ^ rotateRight(W[t-15], 18) ^ (W[t-15] >> 3)
        let s1 = rotateRight(W[t-2], 17) ^ rotateRight(W[t-2], 19) ^ (W[t-2] >> 10)
        W[t] = W[t-16] &+ s0 &+ W[t-7] &+ s1
    }

    var a = state.h0, b = state.h1, c = state.h2, d = state.h3
    var e = state.h4, f = state.h5, g = state.h6, h = state.h7

    for t in 0..<64 {
        let S1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25)
        let ch = (e & f) ^ (~e & g)
        let temp1 = h &+ S1 &+ ch &+ K[t] &+ W[t]
        let S0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22)
        let maj = (a & b) ^ (a & c) ^ (b & c)
        let temp2 = S0 &+ maj

        h = g; g = f; f = e; e = d &+ temp1
        d = c; c = b; b = a; a = temp1 &+ temp2
    }

    state.h0 = state.h0 &+ a; state.h1 = state.h1 &+ b
    state.h2 = state.h2 &+ c; state.h3 = state.h3 &+ d
    state.h4 = state.h4 &+ e; state.h5 = state.h5 &+ f
    state.h6 = state.h6 &+ g; state.h7 = state.h7 &+ h
}

@inline(__always)
private func rotateRight(_ x: UInt32, _ n: UInt32) -> UInt32 {
    (x >> n) | (x << (32 - n))
}

// MARK: - Entropy Payload
/// Data structure for all entropy sources collected during the ritual.
/// Serialized and hashed via SHA-256 to produce 6 line values.
public struct EntropyPayload: Codable, Sendable {
    public let holdDurationMicroseconds: Int64
    public let holdForceSamples: [Double]
    public let holdJitterSamples: [CodablePoint]
    public let stillnessStartTimestamp: TimeInterval

    public let accelerometerSamples: [AccelSample]
    public let gyroscopeSamples: [GyroSample]
    public let magnetometerSamples: [MagSample]

    public let question: String
    public let interKeystrokeIntervals: [Double]
    public let backspaceCount: Int
    public let totalTypingDuration: Double
    public let finalKeystrokeTimestamp: TimeInterval

    public let splitPercentages: [Double]
    public let splitDragSpeeds: [Double]
    public let splitJitters: [[Double]]
    public let splitReleaseTimestamps: [TimeInterval]
    public let splitTrajectories: [[CodablePoint]]

    public let batteryLevel: Float
    public let thermalState: Int
    public let processorCount: Int
    public let sessionNonce: String

    public init(
        holdDurationMicroseconds: Int64,
        holdForceSamples: [Double],
        holdJitterSamples: [CodablePoint],
        stillnessStartTimestamp: TimeInterval,
        accelerometerSamples: [AccelSample],
        gyroscopeSamples: [GyroSample],
        magnetometerSamples: [MagSample],
        question: String,
        interKeystrokeIntervals: [Double],
        backspaceCount: Int,
        totalTypingDuration: Double,
        finalKeystrokeTimestamp: TimeInterval,
        splitPercentages: [Double],
        splitDragSpeeds: [Double],
        splitJitters: [[Double]],
        splitReleaseTimestamps: [TimeInterval],
        splitTrajectories: [[CodablePoint]],
        batteryLevel: Float,
        thermalState: Int,
        processorCount: Int,
        sessionNonce: String
    ) {
        self.holdDurationMicroseconds = holdDurationMicroseconds
        self.holdForceSamples = holdForceSamples
        self.holdJitterSamples = holdJitterSamples
        self.stillnessStartTimestamp = stillnessStartTimestamp
        self.accelerometerSamples = accelerometerSamples
        self.gyroscopeSamples = gyroscopeSamples
        self.magnetometerSamples = magnetometerSamples
        self.question = question
        self.interKeystrokeIntervals = interKeystrokeIntervals
        self.backspaceCount = backspaceCount
        self.totalTypingDuration = totalTypingDuration
        self.finalKeystrokeTimestamp = finalKeystrokeTimestamp
        self.splitPercentages = splitPercentages
        self.splitDragSpeeds = splitDragSpeeds
        self.splitJitters = splitJitters
        self.splitReleaseTimestamps = splitReleaseTimestamps
        self.splitTrajectories = splitTrajectories
        self.batteryLevel = batteryLevel
        self.thermalState = thermalState
        self.processorCount = processorCount
        self.sessionNonce = sessionNonce
    }

    /// Serializes the entire payload to a deterministic byte array for hashing.
    public func serialize() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(self) {
            return data
        }
        // Fallback: manual byte packing
        return fallbackSerialization()
    }

    private func fallbackSerialization() -> Data {
        var bytes = Data()
        withUnsafeBytes(of: holdDurationMicroseconds.bigEndian) { bytes.append(contentsOf: $0) }
        for v in holdForceSamples { withUnsafeBytes(of: v) { bytes.append(contentsOf: $0) } }
        for p in holdJitterSamples {
            withUnsafeBytes(of: p.x) { bytes.append(contentsOf: $0) }
            withUnsafeBytes(of: p.y) { bytes.append(contentsOf: $0) }
        }
        if let qData = question.data(using: .utf8) { bytes.append(qData) }
        for i in interKeystrokeIntervals { withUnsafeBytes(of: i) { bytes.append(contentsOf: $0) } }
        withUnsafeBytes(of: backspaceCount.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: totalTypingDuration) { bytes.append(contentsOf: $0) }
        for p in splitPercentages { withUnsafeBytes(of: p) { bytes.append(contentsOf: $0) } }
        withUnsafeBytes(of: batteryLevel) { bytes.append(contentsOf: $0) }
        if let nData = sessionNonce.data(using: .utf8) { bytes.append(nData) }
        return bytes
    }
}

// MARK: - Codable Sensor Data
public struct AccelSample: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let timestamp: TimeInterval
    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        self.x = x; self.y = y; self.z = z; self.timestamp = timestamp
    }
}

public struct GyroSample: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let timestamp: TimeInterval
    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        self.x = x; self.y = y; self.z = z; self.timestamp = timestamp
    }
}

public struct MagSample: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let timestamp: TimeInterval
    public init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        self.x = x; self.y = y; self.z = z; self.timestamp = timestamp
    }
}

// MARK: - Codable CGPoint Replacement
public struct CodablePoint: Codable, Sendable, Equatable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) {
        self.x = x; self.y = y
    }
}

// MARK: - HashingService
public struct HashingService: Sendable {

    public static func compute(from payload: EntropyPayload) -> HexagramResult {
        let hash = computeSHA256(payload: payload)
        let lineValues = mapToLines(hash: hash)
        return HexagramResult(lineValues: lineValues)
    }

    public static func computeSHA256(payload: EntropyPayload) -> Data {
        let serialized = payload.serialize()
        return PlatformHash.hash(data: serialized)
    }

    public static func mapToLines(hash: Data) -> [LineValue] {
        guard hash.count >= 6 else {
            return (0..<6).map { _ in .youngYin }
        }
        return (0..<6).map { i in
            let byte = hash[i]
            let normalized = Double(byte) / 256.0
            return LineValue.from(yarrowValue: normalized)
        }
    }

    public static func hashHex(hash: Data) -> String {
        hash.map { String(format: "%02x", $0) }.joined()
    }

    public static func computeWithHash(from payload: EntropyPayload) -> (result: HexagramResult, hashHex: String) {
        let hash = computeSHA256(payload: payload)
        let lineValues = mapToLines(hash: hash)
        let result = HexagramResult(lineValues: lineValues)
        let hex = hashHex(hash: hash)
        return (result, hex)
    }
}
