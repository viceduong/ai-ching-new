import Foundation

/// Maps to the four classical I Ching line types with Yarrow-stalk probabilities.
public enum LineValue: Int, Codable, CaseIterable, Identifiable, Sendable {
    case oldYin    = 6  // Thái Âm - Moving Yin
    case youngYang = 7  // Thiếu Dương - Static Yang
    case youngYin  = 8  // Thiếu Âm - Static Yin
    case oldYang   = 9  // Thái Dương - Moving Yang

    public var id: Int { rawValue }

    public var isMoving: Bool {
        self == .oldYin || self == .oldYang
    }

    public var binaryBit: Int {
        self == .youngYang || self == .oldYang ? 1 : 0
    }

    public var displaySymbol: String {
        switch self {
        case .oldYin:    return "— — ×"
        case .youngYang: return "———"
        case .youngYin:  return "— —"
        case .oldYang:   return "——— ○"
        }
    }

    public var vietnameseName: String {
        switch self {
        case .oldYin:    return "Thái Âm"
        case .youngYang: return "Thiếu Dương"
        case .youngYin:  return "Thiếu Âm"
        case .oldYang:   return "Thái Dương"
        }
    }

    public var chineseChar: String {
        switch self {
        case .oldYin:    return "老阴"
        case .youngYang: return "少阳"
        case .youngYin:  return "少阴"
        case .oldYang:   return "老阳"
        }
    }

    static let yarrowThresholds: [(LineValue, ClosedRange<Double>)] = [
        (.oldYin,    0.0000...0.0625),
        (.youngYang, 0.0625...0.3750),
        (.youngYin,  0.3750...0.8125),
        (.oldYang,   0.8125...1.0000),
    ]

    public static func from(yarrowValue: Double) -> LineValue {
        let clamped = min(max(yarrowValue, 0), 0.9999)
        for (value, range) in yarrowThresholds {
            if range.contains(clamped) {
                return value
            }
        }
        return .youngYin
    }
}
