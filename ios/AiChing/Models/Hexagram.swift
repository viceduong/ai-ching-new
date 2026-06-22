import Foundation

// MARK: - Hexagram Model (Bundled JSON)
/// Represents a single hexagram from the I Ching corpus.
struct Hexagram: Codable, Identifiable, Sendable, Equatable {
    let id: Int                    // 0–63 (matching binary index)
    let name: String               // e.g. "Khôn – The Receptive"
    let chineseName: String        // e.g. "坤"
    let judgment: String           // The primary judgment (Thoán từ)
    let image: String              // The image/commentary (Tượng)
    let lineTexts: [String]        // 6 strings, line 1 (bottom) to line 6 (top)

    /// Binary representation (bottom to top, line 1 = LSB)
    /// Used for lookup: 000000 → 0 (Khôn), 111111 → 63 (Càn)
    var binaryPattern: String {
        String(repeating: "—", count: 6) // placeholder; actual computed from id
    }

    /// The 6-line display: bottom line first (index 0) = first line
    var lines: [LineType] {
        (0..<6).map { position in
            let bit = (id >> (5 - position)) & 1
            return bit == 1 ? LineType.yang : LineType.yin
        }
    }

    enum LineType: Sendable, Equatable {
        case yin, yang

        var symbol: String {
            switch self {
            case .yin:  return "— —"
            case .yang: return "———"
            }
        }
    }

    /// Full hexagram name with number
    var displayName: String {
        "\(id + 1). \(name)"
    }
}

// MARK: - Hexagram Database Container
struct HexagramDatabase: Codable, Sendable {
    let hexagrams: [Hexagram]

    /// Lookup by binary index (0–63)
    func hexagram(at index: Int) -> Hexagram? {
        hexagrams.first { $0.id == index }
    }

    /// Lookup by hexagram number (1–64)
    func hexagram(number: Int) -> Hexagram? {
        hexagrams.first { $0.id == number - 1 }
    }
}

// MARK: - Computed Hexagram Result
struct HexagramResult: Sendable, Equatable {
    let lineValues: [LineValue]           // 6 values (6,7,8,9) bottom→top
    let primaryIndex: Int                 // 0–63
    let secondaryIndex: Int?              // nil if no moving lines
    let movingLinePositions: [Int]        // 0-based positions of moving lines

    var hasMovingLines: Bool {
        !movingLinePositions.isEmpty
    }

    init(lineValues: [LineValue]) {
        assert(lineValues.count == 6, "Must have exactly 6 lines")
        self.lineValues = lineValues

        // Calculate primary hexagram index (bottom=LSB, top=MSB)
        var primary = 0
        for (i, value) in lineValues.enumerated() {
            let bit = value.binaryBit
            primary |= (bit << (5 - i)) // line 0 (bottom) = bit 5, line 5 (top) = bit 0
        }
        self.primaryIndex = primary

        // Detect moving lines and compute secondary hexagram
        var moving = [Int]()
        var secondaryLines = lineValues
        for (i, value) in lineValues.enumerated() {
            if value.isMoving {
                moving.append(i)
                // Flip: Old Yin (6) → Young Yang (7), Old Yang (9) → Young Yin (8)
                secondaryLines[i] = (value == .oldYin) ? .youngYang : .youngYin
            }
        }
        self.movingLinePositions = moving

        if moving.isEmpty {
            self.secondaryIndex = nil
        } else {
            var secondary = 0
            for (i, value) in secondaryLines.enumerated() {
                let bit = value.binaryBit
                secondary |= (bit << (5 - i))
            }
            self.secondaryIndex = secondary
        }
    }
}

// MARK: - Reading (Persisted Model)
/// A complete reading saved to the device.
struct Reading: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let date: Date
    let question: String
    let lineValues: [Int]            // 6 values as raw Ints (6,7,8,9)
    let primaryHexagramIndex: Int
    let secondaryHexagramIndex: Int?
    let hashSeed: String             // hex string of the SHA-256 hash
    let userNotes: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        question: String,
        lineValues: [Int],
        primaryHexagramIndex: Int,
        secondaryHexagramIndex: Int?,
        hashSeed: String,
        userNotes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.question = question
        self.lineValues = lineValues
        self.primaryHexagramIndex = primaryHexagramIndex
        self.secondaryHexagramIndex = secondaryHexagramIndex
        self.hashSeed = hashSeed
        self.userNotes = userNotes
    }
}
