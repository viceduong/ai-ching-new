import Foundation

// MARK: - Hexagram Lookup Service
/// Loads and caches the hexagram database from the bundled JSON resource.
/// Provides lookup by index, number, and name.
final class HexagramService: Sendable {
    static let shared = HexagramService()

    private let database: HexagramDatabase

    private init() {
        guard let url = Bundle.main.url(forResource: "hexagrams", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? JSONDecoder().decode(HexagramDatabase.self, from: data)
        else {
            // Fallback: minimal database for development
            self.database = HexagramDatabase(hexagrams: Self.fallbackHexagrams())
            assertionFailure("hexagrams.json not found or malformed — using fallback")
            return
        }
        self.database = db
    }

    /// Initialize with custom data (for previews/testing)
    init(database: HexagramDatabase) {
        self.database = database
    }

    // MARK: - Lookup

    /// Get hexagram by binary index (0–63)
    func hexagram(at index: Int) -> Hexagram? {
        database.hexagram(at: index)
    }

    /// Get hexagram by classical number (1–64)
    func hexagram(number: Int) -> Hexagram? {
        database.hexagram(number: number)
    }

    /// Get hexagram name for display
    func name(for index: Int) -> String {
        database.hexagram(at: index)?.displayName ?? "Unknown (\(index))"
    }

    /// Get judgment text for a hexagram
    func judgment(for index: Int) -> String {
        database.hexagram(at: index)?.judgment ?? "Judgment not found."
    }

    /// Get image text for a hexagram
    func image(for index: Int) -> String {
        database.hexagram(at: index)?.image ?? "Image not found."
    }

    /// Get specific line text for a hexagram
    func lineText(hexagramIndex: Int, linePosition: Int) -> String {
        guard let hex = database.hexagram(at: hexagramIndex),
              linePosition >= 0, linePosition < hex.lineTexts.count
        else {
            return "Line text not found."
        }
        return hex.lineTexts[linePosition]
    }

    // MARK: - Batch Lookup for Oracle Display

    /// Get all display data needed for the Oracle view
    func oracleData(for result: HexagramResult) -> OracleDisplayData {
        let primary = database.hexagram(at: result.primaryIndex)

        let secondary: Hexagram?
        if let secondaryIdx = result.secondaryIndex {
            secondary = database.hexagram(at: secondaryIdx)
        } else {
            secondary = nil
        }

        let movingLineTexts: [(position: Int, text: String)] = result.movingLinePositions.map { pos in
            let text = primary?.lineTexts[safe: pos] ?? "Line text not found."
            return (pos, text)
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

    // MARK: - Fallback

    private static func fallbackHexagrams() -> [Hexagram] {
        [
            Hexagram(id: 0, name: "Khôn – The Receptive", chineseName: "坤",
                     judgment: "The Receptive brings sublime success...",
                     image: "The earth's condition is receptive devotion...",
                     lineTexts: ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6"],
                     nameVi: nil, judgmentVi: nil, imageVi: nil, lineTextsVi: nil),
            Hexagram(id: 63, name: "Càn – The Creative", chineseName: "乾",
                     judgment: "The Creative works sublime success...",
                     image: "The movement of heaven is full of power...",
                     lineTexts: ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6"],
                     nameVi: nil, judgmentVi: nil, imageVi: nil, lineTextsVi: nil)
        ]
    }
}

// MARK: - Oracle Display Data
struct OracleDisplayData: Sendable {
    let primaryHexagram: Hexagram?
    let secondaryHexagram: Hexagram?
    let primaryIndex: Int
    let secondaryIndex: Int?
    let lineValues: [LineValue]
    let movingLinePositions: [Int]
    let movingLineTexts: [(position: Int, text: String)]
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
