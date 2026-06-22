import SwiftUI

// MARK: - Step 1: Stillness
struct StillnessView: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var pulseAnimation = false
    @AppStorage("lang_vi") var isVietnamese = false

    var vi: Bool { isVietnamese }

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 1, label: t(L.Step.stillness, vi))
                .padding(.top, 60)

            // Instruction
            VStack(spacing: DS.Spacing.sm) {
                Text(t(L.Stillness.instruction, vi))
                    .font(DS.Font.serif(16))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)

            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.lg)

            Spacer()

            // Hold circle
            ZStack {
                // Outer ring
                Circle()
                    .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)

                // Progress ring
                Circle()
                    .trim(from: 0, to: viewModel.holdProgress)
                    .stroke(
                        LinearGradient(colors: [DS.Color.gold, DS.Color.goldLight],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                // Ink pool
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DS.Color.ink.opacity(0.15 + 0.6 * viewModel.holdProgress),
                                DS.Color.ink.opacity(0.05 + 0.2 * viewModel.holdProgress),
                                .clear,
                            ],
                            center: .center, startRadius: 10, endRadius: 100
                        )
                    )
                    .frame(width: 160, height: 160)

                // Center text
                Text(viewModel.holdProgress > 0
                    ? "\(Int(viewModel.holdProgress * 100))%"
                    : (vi ? "Giữ" : "Hold"))
                    .font(DS.Font.serif(20, weight: .light))
                    .foregroundColor(viewModel.holdProgress > 0.5 ? Color.white : DS.Color.ink)
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
                        if elapsed < 4.0 {
                            viewModel.cancelHold()
                        } else {
                            viewModel.completeHold()
                        }
                    }
            )

            // Status / sensor feedback
            if viewModel.holdFailed {
                Text(t(L.Stillness.tooSoon, vi))
                    .font(DS.Font.serif(14))
                    .foregroundColor(DS.Color.crimson)
                    .padding(.top, DS.Spacing.lg)
            } else if viewModel.holdProgress > 0 {
                VStack(spacing: 6) {
                    // Time remaining
                    Text("\(Int(viewModel.holdTargetDuration - Date().timeIntervalSince(viewModel.holdStartTime ?? Date())))s")
                        .font(DS.Font.serif(16, weight: .bold))
                        .foregroundColor(DS.Color.gold)

                    // Sensor live feed
                    HStack(spacing: 20) {
                        // Force
                        VStack(spacing: 2) {
                            Text("FORCE")
                                .font(DS.Font.mono(8))
                                .foregroundColor(DS.Color.inkFaded)
                            HStack(spacing: 2) {
                                ForEach(0..<5) { i in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Double(i) / 4.0 < viewModel.touchForce ? DS.Color.gold : DS.Color.divider)
                                        .frame(width: 8, height: 6)
                                }
                            }
                        }

                        // Jitter
                        VStack(spacing: 2) {
                            Text("JITTER")
                                .font(DS.Font.mono(8))
                                .foregroundColor(DS.Color.inkFaded)
                            HStack(spacing: 2) {
                                ForEach(0..<5) { i in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Double(i) / 4.0 < min(viewModel.jitterRadius / 30, 1) ? DS.Color.gold : DS.Color.divider)
                                        .frame(width: 8, height: 6)
                                }
                            }
                        }

                        // Accel X
                        VStack(spacing: 2) {
                            Text("X")
                                .font(DS.Font.mono(8))
                                .foregroundColor(DS.Color.inkFaded)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(abs(viewModel.accelX) > 0.05 ? DS.Color.gold : DS.Color.divider)
                                .frame(width: 8, height: 6)
                        }

                        // Accel Y
                        VStack(spacing: 2) {
                            Text("Y")
                                .font(DS.Font.mono(8))
                                .foregroundColor(DS.Color.inkFaded)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(abs(viewModel.accelY) > 0.05 ? DS.Color.gold : DS.Color.divider)
                                .frame(width: 8, height: 6)
                        }

                        // Accel Z
                        VStack(spacing: 2) {
                            Text("Z")
                                .font(DS.Font.mono(8))
                                .foregroundColor(DS.Color.inkFaded)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(abs(viewModel.accelZ) > 0.05 ? DS.Color.gold : DS.Color.divider)
                                .frame(width: 8, height: 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .fill(DS.Color.surface)
                            .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(DS.Color.gold.opacity(0.15), lineWidth: 0.5))
                    )
                }
                .padding(.top, DS.Spacing.md)
            }

            Spacer()

            Text(t(L.Stillness.hint, vi))
                .font(DS.Font.serif(12))
                .foregroundColor(DS.Color.inkFaded.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.md)
        }
        .background(RitualBackground())
    }
}
