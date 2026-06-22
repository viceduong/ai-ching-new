import SwiftUI

// MARK: - Step 3: Six Splits (Yarrow Stalk Casting)
struct SplitsView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var dragOffset: CGFloat = 0
    @State private var isHovering = false

    var vi: Bool { isVietnamese }

    private let stalkCount = 50
    private let handleWidth: CGFloat = 36

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 3, label: t(L.Step.splits, vi))
                .padding(.top, 60)

            Text(t(L.Splits.instruction, vi))
                .font(DS.Font.serif(14))
                .foregroundColor(DS.Color.ink.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

            // Line counter with trigram-style indicator
            HStack(spacing: 12) {
                Text("\(t(L.Splits.line, vi)) \(viewModel.currentSplitIndex + 1) \(t(L.Splits.of, vi)) 6")
                    .font(DS.Font.serif(16, weight: .semibold))
                    .foregroundColor(DS.Color.gold)
                Text("·")
                    .foregroundColor(DS.Color.inkFaded.opacity(0.3))
                TrigramView(lines: Array(repeating: viewModel.currentSplitIndex >= 0, count: 1), width: 18, isHighlighted: true)
            }
            .padding(.top, DS.Spacing.lg)

            Spacer().frame(height: 20)

            // Yarrow stalks bundle
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Bundle container
                    VStack(spacing: 2) {
                        ForEach(0..<40, id: \.self) { row in
                            HStack(spacing: 1.5) {
                                ForEach(0..<stalkCount, id: \.self) { i in
                                    stalkView(index: i, row: row, geo: geo)
                                }
                            }
                        }
                    }
                    .padding(DS.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.Color.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(DS.Color.gold.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                    )

                    // Gold drag handle
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DS.Color.goldLight, DS.Color.gold, DS.Color.goldDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: handleWidth, height: 200)
                        .shadow(color: DS.Color.gold.opacity(0.4), radius: 6, x: 0, y: 2)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "chevron.left.2").font(.system(size: 9, weight: .bold))
                                Image(systemName: "chevron.left.2").font(.system(size: 9, weight: .bold))
                                Image(systemName: "chevron.left.2").font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(DS.Color.ink.opacity(0.6))
                        )
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let maxOffset = geo.size.width - 80 - handleWidth
                                    dragOffset = min(max(value.translation.width, 0), maxOffset)
                                    let percentage = maxOffset > 0 ? Double(dragOffset / maxOffset) : 0.5
                                    viewModel.updateSplit(percentage: percentage, speed: 0, jitter: [], trajectory: [])
                                }
                                .onEnded { _ in
                                    withAnimation(DS.Anim.default) {
                                        viewModel.completeCurrentSplit()
                                        dragOffset = 0
                                    }
                                }
                        )
                }
            }
            .frame(height: 220)
            .padding(.horizontal, DS.Spacing.lg)

            // Progress
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < viewModel.currentSplitIndex ? DS.Color.gold
                              : i == viewModel.currentSplitIndex ? DS.Color.gold.opacity(0.4)
                              : DS.Color.divider)
                        .frame(width: 36, height: 4)
                }
            }
            .padding(.top, DS.Spacing.md)

            Spacer()

            Text(t(L.Splits.hint, vi))
                .font(DS.Font.serif(11))
                .foregroundColor(DS.Color.inkFaded.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
    }

    private func stalkView(index: Int, row: Int, geo: GeometryProxy) -> some View {
        let splitIndex = Int(CGFloat(stalkCount) * viewModel.splitProgress[viewModel.currentSplitIndex])
        let isLeft = index < splitIndex
        let width = max(1.5, (geo.size.width - 80) / CGFloat(stalkCount))

        return Capsule()
            .fill(isLeft
                ? DS.Color.ink.opacity(0.55)
                : DS.Color.ink.opacity(0.18))
            .frame(width: width, height: 4)
    }
}