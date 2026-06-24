import SwiftUI

// MARK: - Step 3: The Six Splits (Yarrow Stalk Casting)
struct SplitsView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var splitPosition: Double = 0.5
    @State private var showResult: Bool = false
    @State private var lastShown: Int = -1

    var vi: Bool { isVietnamese }
    private let totalLines = 6

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer().frame(height: 50)

                // Step counter
                HStack(spacing: 8) {
                    TrigramView(lines: [true, true, true], width: 18, isHighlighted: true)
                    Text("\(viewModel.currentSplitIndex + 1) / \(totalLines)")
                        .font(DS.Font.serif(20, weight: .semibold))
                        .foregroundColor(DS.Color.ink)
                }

                Text(t(L.Splits.instruction, vi))
                    .font(DS.Font.serif(14))
                    .foregroundColor(DS.Color.inkFaded)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.top, DS.Spacing.md)

                Spacer()

                // CENTERED: Tap anywhere on the bundle to cast a line
                ZStack {
                    // Bundle background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.Color.surface.opacity(0.6))
                        .frame(width: 200, height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DS.Color.gold.opacity(0.15), lineWidth: 0.5)
                        )

                    // 50 vertical stalks with split indicator
                    ForEach(0..<50, id: \.self) { i in
                        let xPos = (CGFloat(i) / 49) * 180 - 90
                        let splitIdx = Int(50 * splitPosition)
                        let isLeft = i < splitIdx
                        Capsule()
                            .fill(isLeft ? DS.Color.ink.opacity(0.75) : DS.Color.ink.opacity(0.3))
                            .frame(width: 2.5, height: 160)
                            .offset(x: xPos, y: 0)
                    }

                    // Split line indicator
                    Rectangle()
                        .fill(DS.Color.gold.opacity(0.6))
                        .frame(width: 2, height: 170)
                        .offset(x: CGFloat(splitPosition) * 180 - 90, y: 0)

                    // Result trigram overlay
                    if showResult {
                        TrigramView(lines: [true, true, true], width: 50, isHighlighted: true)
                            .offset(y: -110)
                            .scaleEffect(1.0)
                            .transition(.scale)
                    }
                }
                .frame(width: 220, height: 200)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let progress = max(0, min(1, val.location.x / 200))
                            splitPosition = progress
                        }
                        .onEnded { _ in
                            commitSplit()
                        }
                )

                // Direction labels
                HStack {
                    Text(vi ? "Trái" : "Left")
                        .font(DS.Font.serif(11))
                        .foregroundColor(DS.Color.inkFaded)
                    Spacer()
                    Text(vi ? "Phải" : "Right")
                        .font(DS.Font.serif(11))
                        .foregroundColor(DS.Color.inkFaded)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.md)

                // Progress dots
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(i < viewModel.currentSplitIndex ? DS.Color.gold
                                  : i == viewModel.currentSplitIndex ? DS.Color.crimson
                                  : DS.Color.divider)
                            .frame(width: i == viewModel.currentSplitIndex ? 12 : 8, height: i == viewModel.currentSplitIndex ? 12 : 8)
                    }
                }
                .padding(.top, DS.Spacing.lg)

                Spacer()

                // Hint
                Text(t(L.Splits.hint, vi))
                    .font(DS.Font.serif(12))
                    .foregroundColor(DS.Color.inkFaded.opacity(0.5))
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.lg)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(RitualBackground())
        .onChange(of: viewModel.currentSplitIndex) { _ in
            if viewModel.currentSplitIndex > lastShown {
                lastShown = viewModel.currentSplitIndex
                withAnimation(.spring(response: 0.4)) { showResult = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) { showResult = false }
                }
            }
        }
    }

    private func commitSplit() {
        viewModel.updateSplit(percentage: splitPosition, speed: 0, jitter: [], trajectory: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel.completeSplit(percentage: splitPosition, speed: 0, jitter: [], trajectory: [])
            splitPosition = 0.5
        }
    }
}