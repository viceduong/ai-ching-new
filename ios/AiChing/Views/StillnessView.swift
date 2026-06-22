import SwiftUI

// MARK: - Step 1: Stillness with Visual Ink Feedback
struct StillnessView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var breathScale: CGFloat = 1.0
    @State private var touchOffset: CGSize = .zero
    @State private var ripplePhase: CGFloat = 0

    var vi: Bool { isVietnamese }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                StepBadge(number: 1, label: t(L.Step.stillness, vi))
                    .padding(.top, 60)
                    .padding(.bottom, DS.Spacing.sm)

                Text(t(L.Stillness.instruction, vi))
                    .font(DS.Font.serif(15))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DS.Spacing.xl)

                Spacer()

                // Ink pool circle — visual feedback for all inputs
                ZStack {
                    // Outer breathing ring
                    Circle()
                        .stroke(DS.Color.gold.opacity(0.15), lineWidth: 1)
                        .frame(width: min(geo.size.width - 60, 260), height: min(geo.size.width - 60, 260))
                        .scaleEffect(breathScale)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: viewModel.holdProgress)
                        .stroke(
                            DS.Color.gold,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: min(geo.size.width - 80, 240), height: min(geo.size.width - 80, 240))
                        .rotationEffect(.degrees(-90))

                    // Ink pool — follows finger position, darkens with time
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DS.Color.ink.opacity(0.1 + 0.7 * viewModel.holdProgress),
                                    DS.Color.ink.opacity(0.05 + 0.3 * viewModel.holdProgress),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .frame(width: min(geo.size.width - 120, 200), height: min(geo.size.width - 120, 200))
                        .offset(touchOffset)

                    // Ripple overlay (accelerometer visualization)
                    if viewModel.isHolding {
                        Circle()
                            .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                            .frame(width: min(geo.size.width - 100, 220), height: min(geo.size.width - 100, 220))
                            .scaleEffect(1.0 + 0.04 * ripplePhase)
                            .opacity(0.5 + 0.5 * ripplePhase)
                            .offset(
                                x: CGFloat(viewModel.accelX * 8),
                                y: CGFloat(viewModel.accelY * 8)
                            )
                    }

                    // Center text
                    Text(viewModel.holdProgress > 0
                        ? "\(Int(viewModel.holdProgress * 100))%"
                        : (vi ? "Giữ" : "Hold"))
                        .font(DS.Font.serif(22, weight: .light))
                        .foregroundColor(viewModel.holdProgress > 0.6 ? DS.Color.surface : DS.Color.ink)
                }
                .frame(height: min(geo.size.width - 40, 280))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let center = CGPoint(x: (geo.size.width - 40) / 2, y: 140)
                            let offset = CGSize(
                                width: (value.location.x - center.x) * 0.3,
                                height: (value.location.y - center.y) * 0.3
                            )
                            touchOffset = offset
                            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                                ripplePhase = abs(viewModel.accelX) + abs(viewModel.accelY)
                            }
                            if !viewModel.isHolding {
                                viewModel.beginHold(at: value.location, force: 0.5)
                                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                    breathScale = 1.04
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(DS.Anim.default) {
                                touchOffset = .zero
                                breathScale = 1.0
                                ripplePhase = 0
                            }
                            let elapsed = Date().timeIntervalSince(viewModel.holdStartTime ?? Date())
                            if elapsed < 4.0 {
                                viewModel.cancelHold()
                            } else {
                                viewModel.completeHold()
                            }
                        }
                )

                if viewModel.holdFailed {
                    Text(t(L.Stillness.tooSoon, vi))
                        .font(DS.Font.serif(14))
                        .foregroundColor(DS.Color.crimson)
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
        }
        .background(RitualBackground())
        .onAppear { viewModel.holdFailed = false; viewModel.holdProgress = 0 }
        .onChange(of: viewModel.accelX) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                ripplePhase = min(abs(viewModel.accelX) + abs(viewModel.accelY), 1.0)
            }
        }
    }
}
