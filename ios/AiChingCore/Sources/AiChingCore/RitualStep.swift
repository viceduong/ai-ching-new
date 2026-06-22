import Foundation

public enum RitualStep: Int, Codable, CaseIterable, Sendable {
    case idle        = 0
    case stillness   = 1
    case inquiry     = 2
    case splits      = 3
    case computation = 4
    case override    = 5
    case oracle      = 6

    public var displayName: String {
        switch self {
        case .idle:        return "准备"
        case .stillness:   return "静心"
        case .inquiry:     return "问卦"
        case .splits:      return "分蓍"
        case .computation: return "演卦"
        case .override:    return "感应"
        case .oracle:      return "启示"
        }
    }

    public var stepNumber: Int { rawValue }

    public var isBeforeComputation: Bool {
        self.rawValue < RitualStep.computation.rawValue
    }
}
