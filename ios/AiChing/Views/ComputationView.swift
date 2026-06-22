import SwiftUI

// MARK: - Step 4: Computation (Hexagram Forms)
struct ComputationView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var rotateAmount: Double = 0

    var vi: Bool { isVietnamese }

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 4, label: t(L.Step.computation, vi))
                .padding(.top, 60)

            Text(t(L.Computation.instruction, vi))
                .font(DS.Font.serif(14))
                .foregroundColor(DS.Color.ink.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

            Spacer().frame(height: 30)

            // Rotating Bagua compass background
            ZStack {
                BaguaCompass(size: 280)
                    .rotationEffect(.degrees(rotateAmount))
                    .opacity(0.25)

                Circle()
                    .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 240, height: 240)

                // Hexagram being formed
                VStack(spacing: 4) {
                    ForEach((0..<6).reversed(), id: \.self) { i in
                        lineView(position: 5 - i)
                    }
                }
            }
            .frame(width: 280, height: 280)

            // Status
            HStack(spacing: 8) {
                ProgressDots(progress: viewModel.computationProgress)
                Text("\(Int(viewModel.computationProgress * 100))%")
                    .font(DS.Font.mono(13, weight: .semibold))
                    .foregroundColor(DS.Color.gold)
            }
            .padding(.top, DS.Spacing.md)

            Text(t(L.Computation.speaking, vi))
                .font(DS.Font.serif(12))
                .foregroundColor(DS.Color.inkFaded)
                .italic()
                .padding(.top, 2)

            Spacer()

            Text(t(L.Computation.detail, vi))
                .font(DS.Font.serif(11))
                .foregroundColor(DS.Color.inkFaded.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: false)) {
                rotateAmount = 360
            }
        }
    }

    private func lineView(position: Int) -> some View {
        let isRevealed = position < viewModel.computedLines.count
        let value = isRevealed ? (viewModel.computedLines[safe: position] ?? .youngYin) : nil
        let isYang = value == .youngYang || value == .oldYang
        let isMoving = value == .oldYin || value == .oldYang

        return Group {
            if isRevealed {
                HexagramView(
                    lines: Array(repeating: true, count: 6),
                    movingLines: isMoving ? [position] : [],
                    width: 160
                )
                .mask(
                    // Mask shows only the line at this position
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { i in
                                Group {
                                    if i == position {
                                        Rectangle().fill(Color.white)
                                    } else {
                                        Color.clear
                                    }
                                }
                                .frame(height: geo.size.height / 6 - 4)
                            }
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                Capsule()
                    .stroke(DS.Color.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 140, height: 6)
            }
        }
    }
}

// MARK: - Progress Dots
struct ProgressDots: View {
    let progress: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<6, id: \.self) { i in
                let filled = Double(i) / 6.0 < progress
                Circle()
                    .fill(filled ? DS.Color.gold : DS.Color.divider)
                    .frame(width: 6, height: 6)
            }
        }
    }
}