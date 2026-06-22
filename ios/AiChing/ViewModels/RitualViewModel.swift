import Foundation
import SwiftUI

// MARK: - Central ViewModel: 6-Step State Machine
/// Orchestrates the entire ritual flow. Each view reads state and calls actions.
/// The ViewModel enforces strict linear progression - no skipping states.
@MainActor
final class RitualViewModel: ObservableObject {

    // MARK: - Published State
    @Published var currentStep: RitualStep = .idle

    // Step 1: Stillness
    @Published var holdProgress: Double = 0.0         // 0.0-1.0
    @Published var isHolding = false
    @Published var holdFailed = false
    @Published var holdTargetDuration: Double = 5.0   // randomized 4-7s
    @Published var touchForce: Double = 0.0           // 0-1 normalized
    @Published var jitterRadius: Double = 0.0         // px of finger movement
    @Published var accelX: Double = 0.0
    @Published var accelY: Double = 0.0
    @Published var accelZ: Double = 0.0

    // Step 2: Inquiry
    @Published var questionText = ""
    @Published var isTyping = false
    @Published var characterCount: Int = 0

    // Step 3: Splits
    @Published var currentSplitIndex: Int = 0         // 0-5
    @Published var splitProgress: [Double] = [0, 0, 0, 0, 0, 0]
    @Published var isDragging = false
    @Published var splitComplete = false

    // Step 4: Computation
    @Published var isComputing = false
    @Published var computationProgress: Double = 0.0  // 0.0-1.0 (line-by-line reveal)
    @Published var computedLines: [LineValue] = []
    @Published var computedResult: HexagramResult?

    // Step 5: Override
    @Published var overriddenLines: [LineValue] = []
    @Published var hasOverridden = false
    @Published var isOverriding = true

    // Step 6: Oracle
    @Published var oracleData: OracleDisplayData?
    @Published var hashHex: String = ""

    // Journal
    @Published var savedReadings: [Reading] = []
    @Published var searchQuery = ""

    // Global
    @Published var showJournal = false
    @Published var isMotionAuthorized = true
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let entropyService = EntropyService()
    private let haptics = HapticService.shared
    private let hexagramLookup = HexagramService.shared
    private let storage = StorageService.shared

    // MARK: - Internal State
    var holdStartTime: Date?
    private var holdTimer: Timer?
    private var accelTimer: Timer?
    // MARK: - Initialization

    init() {
        loadJournal()
        randomizeHoldDuration()
    }

    /// Check motion permissions on appear
    func checkMotionAuthorization() {
        Task {
            let authorized = await entropyService.isMotionAuthorized()
            await MainActor.run { self.isMotionAuthorized = authorized }
        }
    }

    // MARK: - Reset

    /// Full reset - returns to Idle and discards all collected entropy.
    func resetRitual() {
        // Cancel any in-progress operations
        holdTimer?.invalidate()
        holdTimer = nil
        // Reset all state
        currentStep = .idle
        holdProgress = 0.0
        isHolding = false
        holdFailed = false
        questionText = ""
        isTyping = false
        characterCount = 0
        currentSplitIndex = 0
        splitProgress = [0, 0, 0, 0, 0, 0]
        isDragging = false
        splitComplete = false
        isComputing = false
        computationProgress = 0.0
        computedLines = []
        computedResult = nil
        overriddenLines = []
        hasOverridden = false
        isOverriding = true
        oracleData = nil
        hashHex = ""
        errorMessage = nil

        // Reset entropy
        Task { await entropyService.reset() }

        randomizeHoldDuration()
        haptics.lightImpact()
    }

    // MARK: - Step Transitions

    func beginRitual() {
        guard currentStep == .idle else { return }
        Task {
            await entropyService.initialize()
            await entropyService.startMotionCollection()
        }
        haptics.mediumImpact()
        currentStep = .stillness
    }

    // MARK: - Step 1: Stillness

    private func randomizeHoldDuration() {
        holdTargetDuration = Double.random(in: 4.0...7.0)
    }

    func beginHold(at point: CGPoint, force: Double) {
        guard currentStep == .stillness else { return }
        holdStartTime = Date()
        isHolding = true
        holdFailed = false
        holdProgress = 0.0
        touchForce = force
        accelX = 0; accelY = 0; accelZ = 0

        haptics.lightImpact()

        Task { await entropyService.beginHold(at: point, force: force) }

        // Start motion collection
        Task { await entropyService.startMotionCollection() }

        // Poll accelerometer for live display
        accelTimer?.invalidate()
        accelTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, self.isHolding else { return }
            Task { @MainActor in
                let accel = self.entropyService.latestAccel()
                self.accelX = accel.x
                self.accelY = accel.y
                self.accelZ = accel.z
            }
        }

        // Progress timer
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let start = self.holdStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            self.holdProgress = min(elapsed / self.holdTargetDuration, 1.0)
            if self.holdProgress >= 1.0 {
                self.completeHold()
            }
        }
    }

    func updateHold(at point: CGPoint, force: Double) {
        guard isHolding else { return }
        touchForce = min(max(force, 0), 1)
        if let start = holdStartTime {
            let dist = hypot(point.x - 160, point.y - 160) // distance from center
            jitterRadius = dist
        }
        Task { await entropyService.updateHold(at: point, force: force) }
    }

    func cancelHold() {
        guard isHolding else { return }
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        holdProgress = 0.0
        holdFailed = true

        haptics.errorNotification()
        Task { await entropyService.endHold() }

        // Brief rejection animation, then reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.holdFailed = false
        }
    }

    func completeHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        holdProgress = 1.0

        haptics.mediumImpact()

        Task {
            await entropyService.endHold()
            await entropyService.stopMotionCollection()
        }

        // Transition to Inquiry after brief pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentStep = .inquiry
        }
    }

    // MARK: - Step 2: Inquiry

    func beginTyping() {
        isTyping = true
        Task { await entropyService.beginTyping() }
    }

    func registerKeystroke(character: String) {
        if !isTyping {
            beginTyping()
        }
        Task { await entropyService.registerKeystroke(character: character) }
        characterCount = questionText.count
    }

    func registerBackspace() {
        Task { await entropyService.registerBackspace() }
        characterCount = questionText.count
    }

    func submitQuestion() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 5 else {
            haptics.errorNotification()
            return
        }

        haptics.mediumImpact()

        Task {
            await entropyService.finishTyping(question: trimmed)
        }
        isTyping = false
        currentStep = .splits
    }

    // MARK: - Step 3: Splits

    func updateSplit(percentage: Double, speed: Double, jitter: [Double], trajectory: [CGPoint]) {
        guard currentStep == .splits, currentSplitIndex < 6 else { return }

        splitProgress[currentSplitIndex] = percentage
        isDragging = true
    }

    func completeSplit(percentage: Double, speed: Double, jitter: [Double], trajectory: [CGPoint]) {
        guard currentStep == .splits, currentSplitIndex < 6 else { return }

        splitProgress[currentSplitIndex] = percentage
        isDragging = false

        haptics.splitReleaseThud()

        Task {
            await entropyService.registerSplit(
                percentage: percentage,
                speed: speed,
                jitter: jitter,
                trajectory: trajectory
            )
        }

        // Auto-advance after settle animation (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if self.currentSplitIndex < 5 {
                self.currentSplitIndex += 1
                haptics.lightImpact() // readiness signal
            } else {
                self.splitComplete = true
                // Transition to computation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.performComputation()
                }
            }
        }
    }

    // MARK: - Step 4: Computation

    private func performComputation() {
        currentStep = .computation
        isComputing = true
        computationProgress = 0.0
        computedLines = []

        haptics.mediumImpact()

        // Heavy computation on background task
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            // Build entropy payload (actor-isolated, must await)
            let payload = await self.entropyService.buildPayload()

            // Compute SHA-256 and map to lines (pure function, no isolation needed)
            let (result, hex) = HashingService.computeWithHash(from: payload)

            // All UI updates on main actor
            await MainActor.run {
                let lineRevealInterval = 0.4

                // Animate lines appearing one by one
                for i in 0..<6 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * lineRevealInterval) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.computationProgress = Double(i + 1) / 6.0
                            self.computedLines.append(result.lineValues[i])
                        }
                        self.haptics.lineAppearSweep()
                    }
                }

                // Finalize after all lines revealed
                DispatchQueue.main.asyncAfter(deadline: .now() + 6 * lineRevealInterval + 0.5) {
                    withAnimation {
                        self.computedResult = result
                        self.hashHex = hex
                        self.isComputing = false
                    }
                    self.haptics.ceremonialImpact()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.overriddenLines = result.lineValues
                        self.currentStep = .override
                    }
                }
            }
        }
    }

    // MARK: - Step 5: Override

    func toggleLine(at position: Int) {
        guard currentStep == .override,
              position >= 0, position < overriddenLines.count
        else { return }

        haptics.selectionFeedback()

        let current = overriddenLines[position]
        // Toggle between moving/static:
        // Old Yin (6) ↔ Young Yin (8)
        // Old Yang (9) ↔ Young Yang (7)
        let newValue: LineValue
        switch current {
        case .oldYin:    newValue = .youngYin
        case .youngYin:  newValue = .oldYin
        case .oldYang:   newValue = .youngYang
        case .youngYang: newValue = .oldYang
        }

        overriddenLines[position] = newValue
        hasOverridden = true

        // Recompute result with overridden lines
        let newResult = HexagramResult(lineValues: overriddenLines)
        computedResult = newResult

        // Update oracle display data
        oracleData = hexagramLookup.oracleData(for: newResult)
    }

    func acceptOracle() {
        guard currentStep == .override,
              let result = computedResult
        else { return }

        haptics.ceremonialImpact()

        // Finalize oracle display data
        oracleData = hexagramLookup.oracleData(for: result)

        currentStep = .oracle
    }

    // MARK: - Step 6: Oracle

    /// Save the current reading to history.
    func saveReading() {
        guard let result = computedResult else { return }

        let reading = Reading(
            question: questionText,
            lineValues: result.lineValues.map(\.rawValue),
            primaryHexagramIndex: result.primaryIndex,
            secondaryHexagramIndex: result.secondaryIndex,
            hashSeed: hashHex
        )

        if storage.saveReading(reading) {
            haptics.successNotification()
            loadJournal()
        } else {
            errorMessage = "Failed to save reading."
        }
    }

    /// Generate share text for the current reading.
    func shareText() -> String {
        guard let data = oracleData else { return "AiChing Reading" }
        var text = "🪷 I Ching Reading\n\n"
        text += "Question: \(questionText)\n\n"
        text += data.primaryHexagram.map { "Primary: \($0.displayName)\n" } ?? ""
        text += "Seed: \(hashHex.prefix(16))...\n"
        text += "- AiChing"
        return text
    }

    // MARK: - Journal

    func loadJournal() {
        savedReadings = storage.loadReadings()
    }

    func deleteReading(id: UUID) {
        if storage.deleteReading(id: id) {
            loadJournal()
        }
    }

    func searchJournal() {
        if searchQuery.isEmpty {
            loadJournal()
        } else {
            savedReadings = storage.search(query: searchQuery)
        }
    }

    // MARK: - Share Reading from History

    func shareReading(_ reading: Reading) -> String {
        var text = "🪷 I Ching Reading\n\n"
        text += "Question: \(reading.question)\n"
        text += "Date: \(reading.date.formatted(date: .long, time: .shortened))\n"
        text += "Primary Hexagram: \(hexagramLookup.name(for: reading.primaryHexagramIndex))\n"
        if let secondary = reading.secondaryHexagramIndex {
            text += "Secondary: \(hexagramLookup.name(for: secondary))\n"
        }
        text += "Seed: \(reading.hashSeed.prefix(16))...\n"
        text += "- AiChing"
        return text
    }

    // MARK: - Preview Support

    static var preview: RitualViewModel {
        let vm = RitualViewModel()
        vm.currentStep = .oracle
        vm.questionText = "What guidance do I need?"
        let lines: [LineValue] = [.youngYin, .youngYang, .oldYin, .youngYang, .youngYin, .youngYang]
        let result = HexagramResult(lineValues: lines)
        vm.computedResult = result
        vm.overriddenLines = lines
        vm.oracleData = HexagramService.shared.oracleData(for: result)
        vm.hashHex = "a1b2c3d4e5f6..."
        return vm
    }
}
