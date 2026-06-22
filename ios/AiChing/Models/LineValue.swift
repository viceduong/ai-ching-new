import Foundation

// MARK: - Tứ Tượng: The Four Fundamental Symbols
/// Maps to the four classical I Ching line types with Yarrow-stalk probabilities.
enum LineValue: Int, Codable, CaseIterable, Identifiable, Sendable {
    case oldYin    = 6  // Thái Âm - Moving Yin
    case youngYang = 7  // Thiếu Dương - Static Yang
    case youngYin  = 8  // Thiếu Âm - Static Yin
    case oldYang   = 9  // Thái Dương - Moving Yang

    var id: Int { rawValue }

    /// Whether this line is "moving" (老阳/老阴) — it transforms in the secondary hexagram.
    var isMoving: Bool {
        self == .oldYin || self == .oldYang
    }

    /// Binary representation: Yang (—) = 1, Yin (- -) = 0
    var binaryBit: Int {
        self == .youngYang || self == .oldYang ? 1 : 0
    }

    /// Display symbol used in the UI
    var displaySymbol: String {
        switch self {
        case .oldYin:    return "— — ×"
        case .youngYang: return "———"
        case .youngYin:  return "— —"
        case .oldYang:   return "——— ○"
        }
    }

    /// Name in Vietnamese classical terminology
    var vietnameseName: String {
        switch self {
        case .oldYin:    return "Thái Âm"
        case .youngYang: return "Thiếu Dương"
        case .youngYin:  return "Thiếu Âm"
        case .oldYang:   return "Thái Dương"
        }
    }

    /// Chinese character
    var chineseChar: String {
        switch self {
        case .oldYin:    return "老阴"
        case .youngYang: return "少阳"
        case .youngYin:  return "少阴"
        case .oldYang:   return "老阳"
        }
    }

    // Yarrow-stalk probabilities (classical):
    // 6 (Old Yin):   1/16  ≈ 6.25%
    // 7 (Young Yang): 5/16  ≈ 31.25%
    // 8 (Young Yin):  7/16  ≈ 43.75%
    // 9 (Old Yang):   3/16  ≈ 18.75%
    static let yarrowThresholds: [(LineValue, ClosedRange<Double>)] = [
        (.oldYin,    0.0000...0.0625),
        (.youngYang, 0.0625...0.3750),
        (.youngYin,  0.3750...0.8125),
        (.oldYang,   0.8125...1.0000),
    ]

    /// Map a normalized Double (0.0–1.0) to a LineValue using Yarrow-stalk probability thresholds.
    static func from(yarrowValue: Double) -> LineValue {
        let clamped = min(max(yarrowValue, 0), 0.9999)
        for (value, range) in yarrowThresholds {
            if range.contains(clamped) {
                return value
            }
        }
        return .youngYin // default fallback (most probable)
    }
}
