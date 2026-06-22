import Foundation
import UIKit
import CoreHaptics

// MARK: - Haptic Feedback Service
/// Manages all haptic feedback throughout the ritual using Core Haptics and UIFeedbackGenerator.
/// Falls back gracefully on devices without haptic support.
final class HapticService: @unchecked Sendable {

    static let shared = HapticService()

    private var hapticEngine: CHHapticEngine?
    private var isEngineRunning = false
    private let supportsHaptics: Bool

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if supportsHaptics {
            prepareEngine()
        }
    }

    // MARK: - Engine Lifecycle

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.resetHandler = { [weak self] in
                self?.isEngineRunning = false
                self?.restartEngine()
            }
            hapticEngine?.stoppedHandler = { [weak self] _ in
                self?.isEngineRunning = false
            }
            try hapticEngine?.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine failed to start: \(error.localizedDescription)")
        }
    }

    private func restartEngine() {
        guard let engine = hapticEngine else { return }
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine restart failed: \(error.localizedDescription)")
        }
    }

    func ensureEngineRunning() {
        guard supportsHaptics, let engine = hapticEngine, !isEngineRunning else { return }
        restartEngine()
    }

    // MARK: - Public Haptic Patterns

    /// Light impact — subtle confirmation
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium impact — ceremonial affirmation
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Heavy impact — important moment (oracle arrival, ceremony)
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Selection feedback — very light, for toggles
    func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Error/notification — rejection, early release
    func errorNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// Success notification — ritual step completion
    func successNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Ceremonial heavy impact for oracle arrival
    func ceremonialImpact() {
        heavyImpact()
        // Brief delay then a second pulse for ceremonial feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumImpact()
        }
    }

    /// Gentle sweep — line appears in computation
    func lineAppearSweep() {
        guard supportsHaptics else {
            lightImpact()
            return
        }
        ensureEngineRunning()
        guard let engine = hapticEngine else { return }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            lightImpact()
        }
    }

    /// Firm thud — stalk split release
    func splitReleaseThud() {
        guard supportsHaptics else {
            mediumImpact()
            return
        }
        ensureEngineRunning()
        guard let engine = hapticEngine else { return }

        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            mediumImpact()
        }
    }

    /// Custom ritual pattern — a sequence of pulses
    func ritualPulse() {
        guard supportsHaptics else {
            heavyImpact()
            return
        }
        ensureEngineRunning()
        guard let engine = hapticEngine else { return }

        do {
            let events: [CHHapticEvent] = (0..<3).map { i in
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 + Float(i) * 0.15)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                return CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i) * 0.12
                )
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            heavyImpact()
        }
    }

    /// Reset — clear error haptics
    func resetRejection() {
        errorNotification()
    }
}
