import SwiftUI

// MARK: - Step 5: Intuition Override (Consciousness Check)
/// User reviews the 6 generated lines and can toggle any line's moving/static nature.
/// This is the critical innovation — conscious intuition can correct mechanical output.
struct OverrideView: View {
    @ObservedObject var viewModel: RitualViewModel

    private let lineLabels = ["1st (bottom)", "2nd", "3rd", "4th", "5th", "6th (top)"]

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepProgressView(currentStep: .override)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Title
            Text("感 应")
                .font(.system(.title, design: .serif))
                .fontWeight(.light)
                .foregroundColor(.inkBlack)
                .opacity(0.7)

            Text("Intuition Override")
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.4))
                .italic()

            // Subtitle
            Text("If a line feels charged, tap to toggle it.")
                .font(.system(.caption, design: .serif))
                .foregroundColor(.gold.opacity(0.7))
                .padding(.top, 4)
                .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Hexagram display
                    VStack(spacing: 8) {
                        // Show hexagram number and name
                        if let result = viewModel.computedResult {
                            Text(hexagramName(index: result.primaryIndex))
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(.inkBlack.opacity(0.7))

                            // Render lines bottom→top, but display top→bottom
                            ForEach((0..<6).reversed(), id: \.self) { i in
                                let displayIndex = 5 - i // 5→0
                                let value = viewModel.overriddenLines[safe: displayIndex] ?? .youngYin
                                let isMoving = value == .oldYin || value == .oldYang
                                let isYang = value == .youngYang || value == .oldYang

                                OverrideLineRow(
                                    position: displayIndex,
                                    label: lineLabels[displayIndex],
                                    value: value,
                                    isMoving: isMoving,
                                    isYang: isYang,
                                    onTap: { viewModel.toggleLine(at: displayIndex) }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ricePaper.opacity(0.6))
                    )
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            // Secondary hexagram preview (if moving lines exist)
            if let result = viewModel.computedResult, result.hasMovingLines {
                VStack(spacing: 4) {
                    Text("Secondary hexagram will form:")
                        .font(.system(.caption2, design: .serif))
                        .foregroundColor(.inkBlack.opacity(0.4))

                    if let secondaryIdx = result.secondaryIndex {
                        Text(hexagramName(index: secondaryIdx))
                            .font(.system(.subheadline, design: .serif))
                            .foregroundColor(.gold.opacity(0.7))
                    }
                }
                .padding(.bottom, 8)
            }

            // Accept button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.acceptOracle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised")
                        .font(.caption)
                    Text("Accept & Receive Oracle")
                        .font(.system(.headline, design: .serif))
                }
                .foregroundColor(.ricePaper)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.inkBlack)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gold.opacity(0.3), lineWidth: 0.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 24)
        }
        .ritualBackground()
    }

    private func hexagramName(index: Int) -> String {
        HexagramService.shared.name(for: index)
    }
}

// MARK: - Override Line Row
struct OverrideLineRow: View {
    let position: Int
    let label: String
    let value: LineValue
    let isMoving: Bool
    let isYang: Bool
    let onTap: () -> Void

    @State private var pulseGlow = false

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Line label
                Text(label)
                    .font(.system(.caption2, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.4))
                    .frame(width: 80, alignment: .leading)

                Spacer()

                // Line visual
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(isMoving ? Color.movingGold : Color.inkBlack)
                        .opacity(isMoving ? 0.9 : 0.6)
                        .frame(width: isYang ? 60 : 28, height: 5)

                    if !isYang {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isMoving ? Color.movingGold : Color.inkBlack)
                            .opacity(isMoving ? 0.9 : 0.6)
                            .frame(width: 28, height: 5)
                    }
                }

                Spacer()

                // Value indicator
                VStack(alignment: .trailing, spacing: 1) {
                    Text(value.chineseChar)
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(isMoving ? .movingGold : .inkBlack.opacity(0.5))

                    Text("\(value.rawValue)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(isMoving ? .movingGold : .inkBlack.opacity(0.3))
                }

                // Toggle hint
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundColor(.gold.opacity(isMoving ? 0.8 : 0.3))
                    .rotationEffect(.degrees(isMoving ? 180 : 0))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isMoving
                        ? Color.movingGold.opacity(0.08)
                        : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isMoving
                        ? Color.movingGold.opacity(0.3)
                        : Color.inkBlack.opacity(0.06),
                        lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isMoving {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseGlow.toggle()
                }
            }
        }
    }
}

// MARK: - Preview
struct OverrideView_Previews: PreviewProvider {
    static var previews: some View {
        OverrideView(viewModel: RitualViewModel.preview)
    }
}
