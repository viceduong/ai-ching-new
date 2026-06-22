import Foundation
import CoreMotion
import UIKit

// MARK: - Entropy Collection Service
/// Manages all sensor data collection during the ritual (Steps 1–3).
/// Uses Core Motion for accelerometer, gyroscope, and magnetometer.
/// Collects touch dynamics and keyboard dynamics.
actor EntropyService {

    // MARK: Dependencies
    private let motionManager = CMMotionManager()
    let motionAccumulator = MotionDataAccumulator()

    // MARK: Collected State
    private(set) var holdStartTime: Date?
    private(set) var holdForceSamples = [Double]()
    private(set) var holdJitterSamples = [CGPoint]()
    private(set) var holdDurationMicroseconds: Int64 = 0
    private(set) var stillnessStartTimestamp: TimeInterval = 0

    private(set) var question = ""
    private(set) var interKeystrokeIntervals = [Double]()
    private(set) var backspaceCount = 0
    private(set) var totalTypingDuration: Double = 0
    private(set) var typingStartTime: Date?
    private var lastKeystrokeTime: Date?

    private(set) var splitPercentages = [Double]()
    private(set) var splitDragSpeeds = [Double]()
    private(set) var splitJitters = [[Double]]()
    private(set) var splitReleaseTimestamps = [TimeInterval]()
    private(set) var splitTrajectories = [[CGPoint]]()

    private var _sessionNonce = ""

    var sessionNonce: String { _sessionNonce }

    // MARK: Lifecycle

    func initialize() {
        _sessionNonce = UUID().uuidString
    }

    func reset() {
        holdStartTime = nil
        holdForceSamples.removeAll()
        holdJitterSamples.removeAll()
        holdDurationMicroseconds = 0
        stillnessStartTimestamp = 0
        question = ""
        interKeystrokeIntervals.removeAll()
        backspaceCount = 0
        totalTypingDuration = 0
        typingStartTime = nil
        lastKeystrokeTime = nil
        splitPercentages.removeAll()
        splitDragSpeeds.removeAll()
        splitJitters.removeAll()
        splitReleaseTimestamps.removeAll()
        splitTrajectories.removeAll()
        motionAccumulator.reset()
        _sessionNonce = UUID().uuidString
    }

    // MARK: - Step 1: Stillness - Motion Collection

    func startMotionCollection() {
        stillnessStartTimestamp = Date().timeIntervalSince1970

        // Accelerometer at 50Hz
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 50.0
        let accelQueue = OperationQueue()
        accelQueue.maxConcurrentOperationCount = 1
        motionManager.startAccelerometerUpdates(to: accelQueue) { [weak self] data, error in
            guard let data, error == nil, let self else { return }
            let sample = CMAccelerationData(
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z,
                timestamp: data.timestamp
            )
            self.motionAccumulator.appendAccel(sample)
        }

        // Gyroscope at 50Hz
        guard motionManager.isGyroAvailable else { return }
        motionManager.gyroUpdateInterval = 1.0 / 50.0
        let gyroQueue = OperationQueue()
        gyroQueue.maxConcurrentOperationCount = 1
        motionManager.startGyroUpdates(to: gyroQueue) { [weak self] data, error in
            guard let data, error == nil, let self else { return }
            let sample = CMRotationRateData(
                x: data.rotationRate.x,
                y: data.rotationRate.y,
                z: data.rotationRate.z,
                timestamp: data.timestamp
            )
            self.motionAccumulator.appendGyro(sample)
        }

        // Magnetometer at 50Hz
        guard motionManager.isMagnetometerAvailable else { return }
        motionManager.magnetometerUpdateInterval = 1.0 / 50.0
        let magQueue = OperationQueue()
        magQueue.maxConcurrentOperationCount = 1
        motionManager.startMagnetometerUpdates(to: magQueue) { [weak self] data, error in
            guard let data, error == nil, let self else { return }
            let sample = CMMagneticFieldData(
                x: data.magneticField.x,
                y: data.magneticField.y,
                z: data.magneticField.z,
                timestamp: data.timestamp
            )
            self.motionAccumulator.appendMag(sample)
        }
    }

    func stopMotionCollection() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
    }

    // MARK: - Step 1: Hold Tracking

    func beginHold(at point: CGPoint, force: Double) {
        holdStartTime = Date()
        holdJitterSamples = [point]
        holdForceSamples = [force]
    }

    func updateHold(at point: CGPoint, force: Double) {
        holdJitterSamples.append(point)
        holdForceSamples.append(force)
    }

    func endHold() {
        guard let start = holdStartTime else { return }
        holdDurationMicroseconds = Int64(Date().timeIntervalSince(start) * 1_000_000)
        holdStartTime = nil
    }

    var holdDurationSeconds: Double {
        guard let start = holdStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Step 2: Keystroke Tracking

    func beginTyping() {
        typingStartTime = Date()
        lastKeystrokeTime = Date()
        interKeystrokeIntervals.removeAll()
        backspaceCount = 0
    }

    func registerKeystroke(character: String) {
        let now = Date()
        if let last = lastKeystrokeTime {
            let interval = now.timeIntervalSince(last)
            interKeystrokeIntervals.append(interval)
        }
        lastKeystrokeTime = now
    }

    func registerBackspace() {
        backspaceCount += 1
        let now = Date()
        if let last = lastKeystrokeTime {
            let interval = now.timeIntervalSince(last)
            interKeystrokeIntervals.append(interval)
        }
        lastKeystrokeTime = now
    }

    func finishTyping(question: String) {
        self.question = question
        if let start = typingStartTime {
            totalTypingDuration = Date().timeIntervalSince(start)
        }
        typingStartTime = nil
        lastKeystrokeTime = nil
    }

    // MARK: - Step 3: Split Tracking

    func registerSplit(percentage: Double, speed: Double, jitter: [Double], trajectory: [CGPoint]) {
        splitPercentages.append(percentage)
        splitDragSpeeds.append(speed)
        splitJitters.append(jitter)
        splitReleaseTimestamps.append(Date().timeIntervalSince1970)
        splitTrajectories.append(trajectory)
    }

    // MARK: - Payload Assembly

    func buildPayload() -> EntropyPayload {
        let (accel, gyro, mag) = motionAccumulator.snapshot()
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        return EntropyPayload(
            holdDurationMicroseconds: holdDurationMicroseconds,
            holdForceSamples: holdForceSamples,
            holdJitterSamples: holdJitterSamples,
            stillnessStartTimestamp: stillnessStartTimestamp,
            accelerometerSamples: accel,
            gyroscopeSamples: gyro,
            magnetometerSamples: mag,
            question: question,
            interKeystrokeIntervals: interKeystrokeIntervals,
            backspaceCount: backspaceCount,
            totalTypingDuration: totalTypingDuration,
            finalKeystrokeTimestamp: Date().timeIntervalSince1970,
            splitPercentages: splitPercentages,
            splitDragSpeeds: splitDragSpeeds,
            splitJitters: splitJitters,
            splitReleaseTimestamps: splitReleaseTimestamps,
            splitTrajectories: splitTrajectories,
            batteryLevel: device.batteryLevel >= 0 ? device.batteryLevel : 0.5,
            thermalState: ProcessInfo.processInfo.thermalState.rawValue,
            processorCount: ProcessInfo.processInfo.processorCount,
            sessionNonce: _sessionNonce
        )
    }

    // MARK: - Live Sensor Readings (for UI feedback)

    nonisolated func latestAccel() -> (x: Double, y: Double, z: Double) {
        let (accel, _, _) = motionAccumulator.snapshot()
        guard let last = accel.last else { return (0, 0, 0) }
        return (last.x, last.y, last.z)
    }

    // MARK: - Health

    func isMotionAuthorized() -> Bool {
        if #available(iOS 15.0, *) {
            // On iOS 15+, Core Motion always has access unless restricted
            return CMMotionManager().isAccelerometerAvailable
        }
        return CMMotionManager().isAccelerometerAvailable
    }
}
