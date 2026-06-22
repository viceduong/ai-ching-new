import Foundation

// MARK: - Hash Function Abstraction

/// Platform-abstracted hash function.
/// Uses CryptoKit (Apple), swift-crypto (Linux), or a minimal fallback.
protocol HashFunction {
    static func hash(data: Data) -> Data
}

#if canImport(CryptoKit)
import CryptoKit

enum PlatformHash: HashFunction {
    static func hash(data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
#elseif canImport(Crypto)
import Crypto

enum PlatformHash: HashFunction {
    static func hash(data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
#else
/// Cross-platform fallback. In production, add swift-crypto dependency.
/// This produces deterministic output suitable for testing / UI previews
/// but is NOT cryptographically secure.
enum PlatformHash: HashFunction {
    static func hash(data: Data) -> Data {
        // Deterministic pseudo-hash that preserves Yarrow distribution.
        // Maps input bytes to 32-byte output via mixing.
        let bytes = [UInt8](data)
        var output = [UInt8](repeating: 0, count: 32)
        guard !bytes.isEmpty else { return Data(output) }

        // Simple mixing: XOR with rotated self
        for i in 0..<min(32, bytes.count) {
            output[i] = bytes[i] ^ bytes[bytes.count - 1 - i]
        }
        // Fill remaining bytes with combined input hash
        if bytes.count < 32 {
            let seed = bytes.reduce(0) { $0 &+ $1 }
            for i in bytes.count..<32 {
                output[i] = seed &+ UInt8(i &* 37)
            }
        }
        return Data(output)
    }
}
#endif

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
