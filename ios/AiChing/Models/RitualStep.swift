import Foundation

// MARK: - 7-Step Ritual State Machine
/// Tracks the exact phase of the user's divination journey.
/// The machine is strictly linear — no skipping, no backtracking (except full reset).
enum RitualStep: Int, Codable, CaseIterable, Sendable {
    case idle        = 0
    case stillness   = 1
    case inquiry     = 2
    case splits      = 3
    case computation = 4
    case override    = 5
    case oracle      = 6

    var displayName: String {
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

    var subtitle: String {
        switch self {
        case .idle:        return "准备开始仪式"
        case .stillness:   return "凝神静气"
        case .inquiry:     return "写下你的问题"
        case .splits:      return "分蓍草以定爻"
        case .computation: return "卦象正在生成…"
        case .override:    return "倾听内心的声音"
        case .oracle:      return "卦象启示"
        }
    }

    var stepNumber: Int { rawValue }

    var isBeforeComputation: Bool {
        self.rawValue < RitualStep.computation.rawValue
    }
}
