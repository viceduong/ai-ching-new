import Foundation

/// Cross-platform hexagram lookup service.
/// Loads from SPM bundle resource (Apple) or falls back to embedded JSON.
public final class HexagramService: Sendable {
    public static let shared = HexagramService()

    private let database: HexagramDatabase

    private init() {
        // Try SPM bundle first, then main bundle, then embedded fallback
        if let db = Self.loadFromBundle() {
            self.database = db
        } else {
            self.database = HexagramDatabase(hexagrams: Self.embeddedHexagrams())
        }
    }

    private static func loadFromBundle() -> HexagramDatabase? {
        #if canImport(FoundationNetworking)
        // Linux: SPM resource loading
        let bundle = Bundle.module
        #else
        // Apple platforms: try Bundle.module (SPM) then main bundle
        let bundle = Bundle.module
        #endif
        guard let url = bundle.url(forResource: "hexagrams", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? JSONDecoder().decode(HexagramDatabase.self, from: data)
        else {
            return nil
        }
        return db
    }

    public func hexagram(at index: Int) -> Hexagram? {
        database.hexagram(at: index)
    }

    public func hexagram(number: Int) -> Hexagram? {
        database.hexagram(number: number)
    }

    public func name(for index: Int) -> String {
        database.hexagram(at: index)?.displayName ?? "Unknown (\(index))"
    }

    public func judgment(for index: Int) -> String {
        database.hexagram(at: index)?.judgment ?? "Judgment not found."
    }

    public func image(for index: Int) -> String {
        database.hexagram(at: index)?.image ?? "Image not found."
    }

    public func lineText(hexagramIndex: Int, linePosition: Int) -> String {
        guard let hex = database.hexagram(at: hexagramIndex),
              linePosition >= 0, linePosition < hex.lineTexts.count
        else { return "Line text not found." }
        return hex.lineTexts[linePosition]
    }

    // MARK: - Oracle Display Data
    public struct OracleDisplayData: Sendable {
        public let primaryHexagram: Hexagram?
        public let secondaryHexagram: Hexagram?
        public let primaryIndex: Int
        public let secondaryIndex: Int?
        public let lineValues: [LineValue]
        public let movingLinePositions: [Int]
        public let movingLineTexts: [(position: Int, text: String)]

        public init(primaryHexagram: Hexagram?, secondaryHexagram: Hexagram?,
                    primaryIndex: Int, secondaryIndex: Int?,
                    lineValues: [LineValue], movingLinePositions: [Int],
                    movingLineTexts: [(position: Int, text: String)]) {
            self.primaryHexagram = primaryHexagram
            self.secondaryHexagram = secondaryHexagram
            self.primaryIndex = primaryIndex
            self.secondaryIndex = secondaryIndex
            self.lineValues = lineValues
            self.movingLinePositions = movingLinePositions
            self.movingLineTexts = movingLineTexts
        }
    }

    public func oracleData(for result: HexagramResult) -> OracleDisplayData {
        let primary = database.hexagram(at: result.primaryIndex)

        let secondary: Hexagram?
        if let secondaryIdx = result.secondaryIndex {
            secondary = database.hexagram(at: secondaryIdx)
        } else {
            secondary = nil
        }

        var movingLineTexts: [(position: Int, text: String)] = []
        for pos in result.movingLinePositions {
            let text = primary?.lineTexts[safe: pos] ?? "Line text not found."
            movingLineTexts.append((pos, text))
        }

        return OracleDisplayData(
            primaryHexagram: primary,
            secondaryHexagram: secondary,
            primaryIndex: result.primaryIndex,
            secondaryIndex: result.secondaryIndex,
            lineValues: result.lineValues,
            movingLinePositions: result.movingLinePositions,
            movingLineTexts: movingLineTexts
        )
    }

    // MARK: - Safe Array Access
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - Embedded Fallback
extension HexagramService {
    static func embeddedHexagrams() -> [Hexagram] {
        [
            Hexagram(id: 0, name: "Kūn – The Receptive", chineseName: "坤",
                     judgment: "The Receptive brings about sublime success...",
                     image: "The earth's condition is receptive devotion...",
                     lineTexts: ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6"]),
            Hexagram(id: 63, name: "Qián – The Creative", chineseName: "乾",
                     judgment: "The Creative works sublime success...",
                     image: "The movement of heaven is full of power...",
                     lineTexts: ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6"]),
        ]
    }
}
