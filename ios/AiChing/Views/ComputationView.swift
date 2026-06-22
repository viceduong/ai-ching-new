import SwiftUI

// MARK: - Step 4: Computation (The Black Box)
/// Shows the hexagram assembling line-by-line from bottom to top.
/// Deliberate 3-4 second pause for anticipation.
struct ComputationView: View {
    @ObservedObject var viewModel: RitualViewModel

    @State private var showText = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepProgressView(currentStep: .computation)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Title
            Text("演 卦")
                .font(.system(.title, design: .serif))
                .fontWeight(.light)
                .foregroundColor(.inkBlack)
                .opacity(0.7)

            Spacer()

            // Animated hexagram assembly
            VStack(spacing: 8) {
                // Revealed lines (shown from bottom to top as computation progresses)
                let revealedCount = viewModel.computedLines.count

                // Render from top (line 5) to bottom (line 0)
                // So new lines appear at the bottom
                ForEach((0..<6).reversed(), id: \.self) { i in
                    let lineIndex = 5 - i // 5 (top) → 0 (bottom)
                    let isRevealed = lineIndex < revealedCount

                    if isRevealed {
                        let value = viewModel.computedLines[lineIndex]
                        let isYang = value == .youngYang || value == .oldYang
                        let isMoving = value == .oldYin || value == .oldYang

                        HexagramLineView(
                            isYang: isYang,
                            isMoving: isMoving,
                            color: .inkBlack,
                            animated: true,
                            width: 100
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.5, anchor: .bottom)))
                    } else {
                        // Empty placeholder
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.inkBlack.opacity(0.06))
                            .frame(width: 100, height: 6)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.ricePaper.opacity(0.5))
                    .shadow(color: .black.opacity(0.03), radius: 4)
            )

            Spacer()

            // Status text
            if viewModel.computedLines.count < 6 {
                HStack(spacing: 12) {
                    // Animated dots
                    Circle()
                        .fill(Color.gold.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(glowPulse ? 1.2 : 0.8)

                    Text("The stalks are speaking...")
                        .font(.system(.body, design: .serif))
                        .italic()
                        .foregroundColor(.inkBlack.opacity(0.6))

                    Circle()
                        .fill(Color.gold.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .scaleEffect(glowPulse ? 0.8 : 1.2)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        glowPulse.toggle()
                    }
                }
            } else {
                Text("Hexagram complete")
                    .font(.system(.body, design: .serif))
                    .foregroundColor(.jade.opacity(0.7))
            }

            Spacer()
        }
        .ritualBackground()
        .onAppear {
            showText = true
        }
    }
}

// MARK: - Preview
struct ComputationView_Previews: PreviewProvider {
    static var previews: some View {
        ComputationView(viewModel: RitualViewModel.preview)
    }
}
