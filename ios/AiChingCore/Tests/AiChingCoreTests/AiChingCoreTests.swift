import XCTest
@testable import AiChingCore

final class AiChingCoreTests: XCTestCase {

    // MARK: - LineValue Tests

    func testLineValueYarrowDistribution() {
        // 6=oldYin(6.25%), 7=youngYang(31.25%), 8=youngYin(43.75%), 9=oldYang(18.75%)
        let oldYin = LineValue.from(yarrowValue: 0.03)
        XCTAssertEqual(oldYin, .oldYin)

        let youngYang = LineValue.from(yarrowValue: 0.2)
        XCTAssertEqual(youngYang, .youngYang)

        let youngYin = LineValue.from(yarrowValue: 0.6)
        XCTAssertEqual(youngYin, .youngYin)

        let oldYang = LineValue.from(yarrowValue: 0.9)
        XCTAssertEqual(oldYang, .oldYang)
    }

    func testLineValueMoving() {
        XCTAssertTrue(LineValue.oldYin.isMoving)
        XCTAssertTrue(LineValue.oldYang.isMoving)
        XCTAssertFalse(LineValue.youngYin.isMoving)
        XCTAssertFalse(LineValue.youngYang.isMoving)
    }

    func testLineValueBinaryBit() {
        XCTAssertEqual(LineValue.oldYin.binaryBit, 0)
        XCTAssertEqual(LineValue.youngYin.binaryBit, 0)
        XCTAssertEqual(LineValue.youngYang.binaryBit, 1)
        XCTAssertEqual(LineValue.oldYang.binaryBit, 1)
    }

    // MARK: - HexagramResult Tests

    func testHexagramResultPrimaryIndex() {
        // All yin → Kun (index 0)
        let allYin = HexagramResult(lineValues: [.youngYin, .youngYin, .youngYin, .youngYin, .youngYin, .youngYin])
        XCTAssertEqual(allYin.primaryIndex, 0)
        XCTAssertFalse(allYin.hasMovingLines)

        // All yang → Qian (index 63)
        let allYang = HexagramResult(lineValues: [.youngYang, .youngYang, .youngYang, .youngYang, .youngYang, .youngYang])
        XCTAssertEqual(allYang.primaryIndex, 63)
        XCTAssertFalse(allYang.hasMovingLines)
    }

    func testHexagramResultMovingLines() {
        // Bottom line moving (oldYin) → should produce secondary hexagram
        let result = HexagramResult(lineValues: [.oldYin, .youngYang, .youngYin, .youngYang, .youngYin, .youngYang])
        XCTAssertTrue(result.hasMovingLines)
        XCTAssertEqual(result.movingLinePositions, [0])
        XCTAssertNotNil(result.secondaryIndex)
        // Moving line flips, so secondary should differ from primary
        XCTAssertNotEqual(result.primaryIndex, result.secondaryIndex)
    }

    func testHexagramResultAllMoving() {
        // All 6 lines moving → swaps to opposite hexagram
        let result = HexagramResult(lineValues: [.oldYin, .oldYang, .oldYin, .oldYang, .oldYin, .oldYang])
        XCTAssertEqual(result.movingLinePositions.count, 6)
        XCTAssertEqual(result.primaryIndex, 21) // binary 010101
    }

    // MARK: - HashingService Tests

    func testDeterministicHash() {
        let payload = createTestPayload()
        let hash1 = HashingService.computeSHA256(payload: payload)
        let hash2 = HashingService.computeSHA256(payload: payload)
        XCTAssertEqual(hash1, hash2, "Hash must be deterministic for identical inputs")
    }

    func testDifferentInputsProduceDifferentHashes() {
        let payload1 = createTestPayload(seed: "alpha")
        let payload2 = createTestPayload(seed: "beta")
        let hash1 = HashingService.computeSHA256(payload: payload1)
        let hash2 = HashingService.computeSHA256(payload: payload2)
        XCTAssertNotEqual(hash1, hash2, "Different inputs should produce different hashes")
    }

    func testHashProduces6Lines() {
        let payload = createTestPayload()
        let result = HashingService.compute(from: payload)
        XCTAssertEqual(result.lineValues.count, 6)
    }

    func testAllLineValuesValid() {
        // Run 1000 random payloads, verify all line values are valid
        for _ in 0..<1000 {
            let seed = UUID().uuidString
            let payload = createTestPayload(seed: seed)
            let result = HashingService.compute(from: payload)
            for value in result.lineValues {
                XCTAssertTrue([6, 7, 8, 9].contains(value.rawValue))
            }
        }
    }

    func testYarrowProbabilityDistribution() {
        // Run 100k iterations and check rough Yarrow distribution
        var counts = [LineValue: Int]()
        counts[.oldYin] = 0
        counts[.youngYang] = 0
        counts[.youngYin] = 0
        counts[.oldYang] = 0

        for i in 0..<100_000 {
            let payload = createTestPayload(seed: "dist_\(i)")
            let result = HashingService.compute(from: payload)
            counts[result.lineValues[0], default: 0] += 1
        }

        let total = 100_000
        let oldYinRatio = Double(counts[.oldYin] ?? 0) / Double(total)
        let youngYangRatio = Double(counts[.youngYang] ?? 0) / Double(total)
        let youngYinRatio = Double(counts[.youngYin] ?? 0) / Double(total)
        let oldYangRatio = Double(counts[.oldYang] ?? 0) / Double(total)

        // Allow 2% tolerance for randomness
        XCTAssertEqual(oldYinRatio, 0.0625, accuracy: 0.02)
        XCTAssertEqual(youngYangRatio, 0.3125, accuracy: 0.03)
        XCTAssertEqual(youngYinRatio, 0.4375, accuracy: 0.03)
        XCTAssertEqual(oldYangRatio, 0.1875, accuracy: 0.03)
    }

    // MARK: - HexagramService Tests

    func testHexagramLookup() {
        let service = HexagramService.shared
        let kun = service.hexagram(at: 0)
        XCTAssertNotNil(kun)
        XCTAssertEqual(kun?.chineseName, "坤")

        let qian = service.hexagram(number: 64)
        XCTAssertNotNil(qian)
        if let qian = qian {
            XCTAssertEqual(qian.id, 63)
        }
    }

    func testAll64HexagramsAccessible() {
        let service = HexagramService.shared
        for i in 0..<64 {
            let hex = service.hexagram(at: i)
            XCTAssertNotNil(hex, "Hexagram at index \(i) should not be nil")
            XCTAssertEqual(hex?.lineTexts.count, 6, "Hexagram \(i) must have 6 lines")
        }
    }

    // MARK: - EntropyPayload Tests

    func testPayloadSerializationDeterministic() {
        let payload = createTestPayload()
        let data1 = payload.serialize()
        let data2 = payload.serialize()
        XCTAssertEqual(data1, data2, "Serialization must be deterministic")
    }

    func testPayloadNonceChangesHash() {
        let p1 = createTestPayload(seed: "same")
        let p2 = createTestPayload(seed: "same")
        let h1 = HashingService.computeSHA256(payload: p1)
        let h2 = HashingService.computeSHA256(payload: p2)
        XCTAssertEqual(h1, h2)
    }

    // MARK: - Helpers

    private func createTestPayload(seed: String = "test") -> EntropyPayload {
        EntropyPayload(
            holdDurationMicroseconds: 5_000_000,
            holdForceSamples: [0.5, 0.6, 0.55],
            holdJitterSamples: [CodablePoint(x: 100, y: 200), CodablePoint(x: 101, y: 199)],
            stillnessStartTimestamp: 1_700_000_000,
            accelerometerSamples: [AccelSample(x: 0.01, y: -0.02, z: 1.0, timestamp: 1)],
            gyroscopeSamples: [GyroSample(x: 0.001, y: -0.002, z: 0.003, timestamp: 1)],
            magnetometerSamples: [MagSample(x: 10, y: -20, z: 30, timestamp: 1)],
            question: seed,
            interKeystrokeIntervals: [0.1, 0.15, 0.12],
            backspaceCount: 1,
            totalTypingDuration: 2.5,
            finalKeystrokeTimestamp: 1_700_000_010,
            splitPercentages: [0.3, 0.5, 0.7, 0.4, 0.6, 0.8],
            splitDragSpeeds: [100, 200, 150, 180, 90, 300],
            splitJitters: [[0.5], [0.3], [0.7], [0.2], [0.6], [0.4]],
            splitReleaseTimestamps: [1, 2, 3, 4, 5, 6],
            splitTrajectories: [[CodablePoint(x: 0, y: 0), CodablePoint(x: 100, y: 50)]],
            batteryLevel: 0.8,
            thermalState: 0,
            processorCount: 8,
            sessionNonce: "test-\(seed)"
        )
    }
}
