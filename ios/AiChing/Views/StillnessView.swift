import SwiftUI

// MARK: - Step 1: Stillness (Intention Anchor)
/// User must long-press a pulsing circle for 4–7 seconds.
/// Premature release resets with haptic rejection.
struct StillnessView: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var pulseAnimation = false
    @State private var inkSpread: CGFloat = 0.0

    // Minimum hold time before release is allowed
    private let minHoldDuration: Double = 4.0

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepProgressView(currentStep: .stillness)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Title
            Text("静 心")
                .font(.system(.title, design: .serif))
                .fontWeight(.light)
                .foregroundColor(.inkBlack)
                .opacity(0.7)

            Text("Stillness")
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.4))
                .italic()

            Spacer()

            // Instruction
            Text("Hold the circle until it fills completely.\nLet your mind settle.")
                .font(.system(.body, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Pulse circle — long press target
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.gold.opacity(0.3), .gold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)

                // Ink fill circle
                Circle()
                    .trim(from: 0, to: viewModel.holdProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.inkBlack, .inkBlack.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))

                // Ink pool (the hold target)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .inkBlack.opacity(0.3 + 0.5 * viewModel.holdProgress),
                                .inkBlack.opacity(0.1 + 0.2 * viewModel.holdProgress),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 160, height: 160)

                // Center text
                Text(viewModel.holdProgress > 0
                    ? "\(Int(viewModel.holdProgress * 100))%"
                    : "Hold")
                    .font(.system(.title3, design: .serif))
                    .foregroundColor(viewModel.holdProgress > 0.5 ? .ricePaper : .inkBlack)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !viewModel.isHolding {
                            viewModel.beginHold(at: value.location, force: 0.5)
                            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                pulseAnimation = true
                            }
                        }
                        viewModel.updateHold(at: value.location, force: 0.5)
                    }
                    .onEnded { _ in
                        pulseAnimation = false
                        let elapsed = Date().timeIntervalSince(viewModel.holdStartTime ?? Date())
                        if elapsed < minHoldDuration {
                            viewModel.cancelHold()
                        } else {
                            viewModel.completeHold()
                        }
                    }
            )
            .simultaneousGesture(
                // Allow tap to start as alternative
                LongPressGesture(minimumDuration: minHoldDuration)
                    .onChanged { _ in
                        if !viewModel.isHolding {
                            viewModel.beginHold(at: .zero, force: 0.5)
                        }
                    }
                    .onEnded { _ in
                        pulseAnimation = false
                    }
            )

            // Hold progress text
            if viewModel.holdProgress > 0 {
                Text("\(Int(viewModel.holdTargetDuration - Date().timeIntervalSince(viewModel.holdStartTime ?? Date())))s remaining")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.inkBlack.opacity(0.4))
                    .padding(.top, 16)
            }

            Spacer()

            // Hint
            Text("时长随机 4–7 秒 · 不可催促")
                .font(.system(.caption2, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.3))
                .padding(.bottom, 8)
        }
        .ritualBackground()
        .onAppear {
            viewModel.holdFailed = false
            viewModel.holdProgress = 0.0
        }
    }
}

// MARK: - Preview
struct StillnessView_Previews: PreviewProvider {
    static var previews: some View {
        StillnessView(viewModel: RitualViewModel.preview)
    }
}
