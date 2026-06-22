import Foundation

/// Represents a single hexagram from the I Ching corpus.
public struct Hexagram: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let name: String
    public let chineseName: String
    public let judgment: String
    public let image: String
    public let lineTexts: [String]
    public let nameVi: String?
    public let judgmentVi: String?
    public let imageVi: String?
    public let lineTextsVi: [String]?

    public init(id: Int, name: String, chineseName: String, judgment: String, image: String, lineTexts: [String], nameVi: String? = nil, judgmentVi: String? = nil, imageVi: String? = nil, lineTextsVi: [String]? = nil) {
        self.id = id; self.name = name; self.chineseName = chineseName
        self.judgment = judgment; self.image = image; self.lineTexts = lineTexts
        self.nameVi = nameVi; self.judgmentVi = judgmentVi; self.imageVi = imageVi; self.lineTextsVi = lineTextsVi
    }

    public var lines: [LineType] {
        (0..<6).map { position in
            let bit = (id >> (5 - position)) & 1
            return bit == 1 ? .yang : .yin
        }
    }

    public enum LineType: Sendable, Equatable {
        case yin, yang

        public var symbol: String {
            switch self {
            case .yin:  return "— —"
            case .yang: return "———"
            }
        }
    }

    public var displayName: String {
        "\(id + 1). \(name)"
    }


}

public struct HexagramDatabase: Codable, Sendable {
    public let hexagrams: [Hexagram]

    public func hexagram(at index: Int) -> Hexagram? {
        hexagrams.first { $0.id == index }
    }

    public func hexagram(number: Int) -> Hexagram? {
        hexagrams.first { $0.id == number - 1 }
    }

    public init(hexagrams: [Hexagram]) {
        self.hexagrams = hexagrams
    }
}

/// Result of the SHA-256 hashing → Yarrow mapping computation.
public struct HexagramResult: Sendable, Equatable {
    public let lineValues: [LineValue]
    public let primaryIndex: Int
    public let secondaryIndex: Int?
    public let movingLinePositions: [Int]

    public var hasMovingLines: Bool { !movingLinePositions.isEmpty }

    public init(lineValues: [LineValue]) {
        assert(lineValues.count == 6, "Must have exactly 6 lines")
        self.lineValues = lineValues

        var primary = 0
        for (i, value) in lineValues.enumerated() {
            let bit = value.binaryBit
            primary |= (bit << (5 - i))
        }
        self.primaryIndex = primary

        var moving = [Int]()
        var secondaryLines = lineValues
        for (i, value) in lineValues.enumerated() {
            if value.isMoving {
                moving.append(i)
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

/// A complete reading saved to the device.
public struct Reading: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let question: String
    public let lineValues: [Int]
    public let primaryHexagramIndex: Int
    public let secondaryHexagramIndex: Int?
    public let hashSeed: String
    public let userNotes: String?

    public init(
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
