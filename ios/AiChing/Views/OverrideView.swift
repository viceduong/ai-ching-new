import SwiftUI

// MARK: - Step 5: Intuition Override — Tap the Lines
struct OverrideView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false

    var vi: Bool { isVietnamese }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Title
            VStack(spacing: 4) {
                Text(t(L.Override.title, vi))
                    .font(DS.Font.serif(20, weight: .light))
                    .foregroundColor(DS.Color.ink)
                Text(vi ? "Chạm để thay đổi" : "Tap a line to change")
                    .font(DS.Font.serif(12))
                    .foregroundColor(DS.Color.inkFaded)
                    .italic()
            }
            .padding(.bottom, DS.Spacing.lg)

            // The hexagram - tappable lines
            if let result = viewModel.computedResult {
                VStack(spacing: 6) {
                    // Chinese name
                    Text(HexagramService.shared.hexagram(at: result.primaryIndex)?.chineseName ?? "")
                        .font(DS.Font.chinese(28))
                        .foregroundColor(DS.Color.ink.opacity(0.5))

                    // 6 tappable lines
                    ForEach((0..<6).reversed(), id: \.self) { i in
                        let displayIdx = 5 - i
                        let val = viewModel.overriddenLines[safe: displayIdx] ?? .youngYin
                        let isYang = val == .youngYang || val == .oldYang
                        let isMoving = val == .oldYin || val == .oldYang

                        Button(action: { viewModel.toggleLine(at: displayIdx) }) {
                            TappableLine(
                                isYang: isYang,
                                isMoving: isMoving,
                                isActive: viewModel.isOverriding && viewModel.hasOverridden
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer()

            // Accept — just a subtle text button
            Button(action: {
                withAnimation(DS.Anim.default) { viewModel.acceptOracle() }
            }) {
                Text(t(L.Override.accept, vi))
                    .font(DS.Font.serif(15, weight: .medium))
                    .foregroundColor(DS.Color.gold)
                    .padding(.vertical, DS.Spacing.sm)
            }

            Spacer().frame(height: 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RitualBackground())
    }
}

// MARK: - Tappable Line
struct TappableLine: View {
    let isYang: Bool
    let isMoving: Bool
    let isActive: Bool

    var body: some View {
        HStack {
            Spacer()
            if isYang {
                Capsule()
                    .fill(isMoving ? DS.Color.crimson : DS.Color.ink)
                    .frame(width: 200, height: 6)
                    .opacity(isActive ? 1.0 : 0.7)
            } else {
                HStack(spacing: 14) {
                    Capsule()
                        .fill(isMoving ? DS.Color.crimson : DS.Color.ink)
                        .frame(width: 93, height: 6)
                        .opacity(isActive ? 1.0 : 0.7)
                    Capsule()
                        .fill(isMoving ? DS.Color.crimson : DS.Color.ink)
                        .frame(width: 93, height: 6)
                        .opacity(isActive ? 1.0 : 0.7)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}