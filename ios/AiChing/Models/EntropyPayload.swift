import Foundation
import CoreMotion

// MARK: - Entropy Payload
/// Aggregates all entropy sources collected during Steps 1–3 of the ritual.
/// This struct is serialized and hashed via SHA-256 in Step 4.
struct EntropyPayload: Codable, Sendable {
    // MARK: Step 1 - Stillness
    let holdDurationMicroseconds: Int64
    let holdForceSamples: [Double]
    let holdJitterSamples: [CGPoint]
    let stillnessStartTimestamp: TimeInterval

    // MARK: Step 1 - Device Motion (sampled at ~50Hz during hold)
    let accelerometerSamples: [CMAccelerationData]
    let gyroscopeSamples: [CMRotationRateData]
    let magnetometerSamples: [CMMagneticFieldData]

    // MARK: Step 2 - Inquiry
    let question: String
    let interKeystrokeIntervals: [Double] // seconds between each key press
    let backspaceCount: Int
    let totalTypingDuration: Double
    let finalKeystrokeTimestamp: TimeInterval

    // MARK: Step 3 - Splits (6 iterations)
    let splitPercentages: [Double]      // 0.0–1.0 per split
    let splitDragSpeeds: [Double]       // pixels/second per split
    let splitJitters: [[Double]]         // position variance per split
    let splitReleaseTimestamps: [TimeInterval]
    let splitTrajectories: [[CGPoint]]   // full drag path per split

    // MARK: Device Environmental
    let batteryLevel: Float
    let thermalState: Int
    let processorCount: Int
    let sessionNonce: String            // UUID generated at ritual start

    // MARK: Encoding for hashing
    /// Serializes the entire payload to a deterministic byte array for SHA-256.
    func serialize() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        // Best effort: if encoding fails, fall back to a predictable representation
        guard let data = try? encoder.encode(self) else {
            // Fallback: create a deterministic data representation manually
            return fallbackSerialization()
        }
        return data
    }

    private func fallbackSerialization() -> Data {
        var bytes = Data()
        // Encode each field in a fixed order for determinism
        withUnsafeBytes(of: holdDurationMicroseconds.bigEndian) { bytes.append(contentsOf: $0) }
        for v in holdForceSamples { withUnsafeBytes(of: v) { bytes.append(contentsOf: $0) } }
        for p in holdJitterSamples {
            withUnsafeBytes(of: p.x) { bytes.append(contentsOf: $0) }
            withUnsafeBytes(of: p.y) { bytes.append(contentsOf: $0) }
        }
        for a in accelerometerSamples { bytes.append(a.serialize()) }
        for g in gyroscopeSamples { bytes.append(g.serialize()) }
        for m in magnetometerSamples { bytes.append(m.serialize()) }
        if let qData = question.data(using: .utf8) { bytes.append(qData) }
        for i in interKeystrokeIntervals { withUnsafeBytes(of: i) { bytes.append(contentsOf: $0) } }
        withUnsafeBytes(of: backspaceCount.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: totalTypingDuration) { bytes.append(contentsOf: $0) }
        for p in splitPercentages { withUnsafeBytes(of: p) { bytes.append(contentsOf: $0) } }
        for s in splitDragSpeeds { withUnsafeBytes(of: s) { bytes.append(contentsOf: $0) } }
        for j in splitJitters { for v in j { withUnsafeBytes(of: v) { bytes.append(contentsOf: $0) } } }
        withUnsafeBytes(of: batteryLevel) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: thermalState.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: processorCount.bigEndian) { bytes.append(contentsOf: $0) }
        if let nData = sessionNonce.data(using: .utf8) { bytes.append(nData) }
        return bytes
    }
}

// MARK: - Codable wrappers for Core Motion types

struct CMAccelerationData: Codable, Sendable {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval

    func serialize() -> Data {
        var bytes = Data()
        withUnsafeBytes(of: x) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: y) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: z) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: timestamp) { bytes.append(contentsOf: $0) }
        return bytes
    }
}

struct CMRotationRateData: Codable, Sendable {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval

    func serialize() -> Data {
        var bytes = Data()
        withUnsafeBytes(of: x) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: y) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: z) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: timestamp) { bytes.append(contentsOf: $0) }
        return bytes
    }
}

struct CMMagneticFieldData: Codable, Sendable {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval

    func serialize() -> Data {
        var bytes = Data()
        withUnsafeBytes(of: x) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: y) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: z) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: timestamp) { bytes.append(contentsOf: $0) }
        return bytes
    }
}

// MARK: - Motion Manager Data Accumulator
/// Thread-safe accumulator for sensor data collected during the ritual.
final class MotionDataAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var accelerometer = [CMAccelerationData]()
    private(set) var gyroscope = [CMRotationRateData]()
    private(set) var magnetometer = [CMMagneticFieldData]()

    let maxSamples = 10_000 // cap per session to prevent memory bloat

    func appendAccel(_ data: CMAccelerationData) {
        lock.lock(); defer { lock.unlock() }
        guard accelerometer.count < maxSamples else { return }
        accelerometer.append(data)
    }

    func appendGyro(_ data: CMRotationRateData) {
        lock.lock(); defer { lock.unlock() }
        guard gyroscope.count < maxSamples else { return }
        gyroscope.append(data)
    }

    func appendMag(_ data: CMMagneticFieldData) {
        lock.lock(); defer { lock.unlock() }
        guard magnetometer.count < maxSamples else { return }
        magnetometer.append(data)
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        accelerometer.removeAll()
        gyroscope.removeAll()
        magnetometer.removeAll()
    }

    func snapshot() -> (accel: [CMAccelerationData], gyro: [CMRotationRateData], mag: [CMMagneticFieldData]) {
        lock.lock(); defer { lock.unlock() }
        return (accelerometer, gyroscope, magnetometer)
    }
}
