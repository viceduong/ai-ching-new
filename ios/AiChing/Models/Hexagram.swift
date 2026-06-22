import Foundation

struct Hexagram: Codable, Identifiable, Sendable, Equatable {
    let id: Int
    let name: String
    let chineseName: String
    let judgment: String
    let image: String
    let lineTexts: [String]
    let nameVi: String?
    let judgmentVi: String?
    let imageVi: String?
    let lineTextsVi: [String]?

    var lines: [LineType] {
        (0..<6).map { pos in
            let bit = (id >> (5 - pos)) & 1
            return bit == 1 ? .yang : .yin
        }
    }

    enum LineType: Sendable, Equatable {
        case yin, yang
        var symbol: String {
            switch self {
            case .yin: return "- -"
            case .yang: return "---"
            }
        }
    }

    var displayName: String { "\(id + 1). \(name)" }
}

struct HexagramDatabase: Codable, Sendable {
    let hexagrams: [Hexagram]
    func hexagram(at index: Int) -> Hexagram? { hexagrams.first { $0.id == index } }
    func hexagram(number: Int) -> Hexagram? { hexagrams.first { $0.id == number - 1 } }
}

struct HexagramResult: Sendable, Equatable {
    let lineValues: [LineValue]
    let primaryIndex: Int
    let secondaryIndex: Int?
    let movingLinePositions: [Int]
    var hasMovingLines: Bool { !movingLinePositions.isEmpty }

    init(lineValues: [LineValue]) {
        assert(lineValues.count == 6)
        self.lineValues = lineValues
        var primary = 0
        for (i, v) in lineValues.enumerated() { primary |= (v.binaryBit << (5 - i)) }
        self.primaryIndex = primary
        var moving = [Int]()
        var sec = lineValues
        for (i, v) in lineValues.enumerated() {
            if v.isMoving { moving.append(i); sec[i] = (v == .oldYin) ? .youngYang : .youngYin }
        }
        self.movingLinePositions = moving
        if moving.isEmpty { self.secondaryIndex = nil }
        else {
            var si = 0
            for (i, v) in sec.enumerated() { si |= (v.binaryBit << (5 - i)) }
            self.secondaryIndex = si
        }
    }
}

struct Reading: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let date: Date
    let question: String
    let lineValues: [Int]
    let primaryHexagramIndex: Int
    let secondaryHexagramIndex: Int?
    let hashSeed: String
    let userNotes: String?

    init(id: UUID = UUID(), date: Date = Date(), question: String,
         lineValues: [Int], primaryHexagramIndex: Int,
         secondaryHexagramIndex: Int?, hashSeed: String,
         userNotes: String? = nil) {
        self.id = id; self.date = date; self.question = question
        self.lineValues = lineValues; self.primaryHexagramIndex = primaryHexagramIndex
        self.secondaryHexagramIndex = secondaryHexagramIndex
        self.hashSeed = hashSeed; self.userNotes = userNotes
    }
}


