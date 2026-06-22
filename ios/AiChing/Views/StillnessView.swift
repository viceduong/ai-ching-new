import SwiftUI

// MARK: - Step 1: Stillness
struct StillnessView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var breathScale: CGFloat = 1.0
    @State private var touchOffset: CGSize = .zero
    @State private var rippleOffset: CGSize = .zero

    var vi: Bool { isVietnamese }

    var body: some View {
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
                .padding(.bottom, DS.Spacing.sm)

            // Push circle up near center of remaining space
            // (asymmetric: small top gap, large bottom gap)
            Spacer().frame(minHeight: 10, maxHeight: 60)

            // Hold circle with Tá»© TÆ°á»£ng (Four Symbols) background
            ZStack {
                // Outer glow — visible touch target
                Circle()
                    .stroke(DS.Color.gold.opacity(0.4), lineWidth: 2)
                    .frame(width: 260, height: 260)
                    .scaleEffect(breathScale)

                // Tá»© TÆ°á»£ng — 4 circles at cardinal points, within visible frame
                circleAt(angle: 0, radius: 110, size: 20, color: DS.Color.gold.opacity(0.35))
                circleAt(angle: 90, radius: 110, size: 20, color: DS.Color.jade.opacity(0.3))
                circleAt(angle: 180, radius: 110, size: 20, color: DS.Color.crimson.opacity(0.3))
                circleAt(angle: 270, radius: 110, size: 20, color: DS.Color.gold.opacity(0.35))

                // Dashed ring — indicates tappable area
                Circle()
                    .stroke(DS.Color.gold.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .frame(width: 240, height: 240)

                // Progress arc
                Circle()
                    .trim(from: 0, to: viewModel.holdProgress)
                    .stroke(DS.Color.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))

                // Ripple ring (accelerometer)
                Circle()
                    .stroke(DS.Color.gold.opacity(0.25), lineWidth: 1)
                    .frame(width: 230, height: 230)
                    .scaleEffect(1.0 + 0.03 * CGFloat(min(abs(viewModel.accelX) + abs(viewModel.accelY), 1.0)))
                    .offset(rippleOffset)
                    .opacity(viewModel.isHolding ? 0.6 : 0)

                // Ink pool — always visible, darkens with hold
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DS.Color.ink.opacity(0.25 + 0.65 * viewModel.holdProgress),
                                DS.Color.ink.opacity(0.12 + 0.3 * viewModel.holdProgress),
                                DS.Color.ink.opacity(0.03),
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(touchOffset)
                    .animation(.interactiveSpring(), value: touchOffset)

                // Hold label
                Text(viewModel.holdProgress > 0
                    ? "\(Int(viewModel.holdProgress * 100))%"
                    : (vi ? "Giữ" : "Hold"))
                    .font(DS.Font.serif(20, weight: .semibold))
                    .foregroundColor(DS.Color.gold)
            }
            .frame(width: 280, height: 280)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let center = CGPoint(x: 130, y: 140)
                        let dx = (val.location.x - center.x) * 0.3
                        let dy = (val.location.y - center.y) * 0.3
                        touchOffset = CGSize(width: dx, height: dy)
                        if !viewModel.isHolding {
                            viewModel.beginHold(at: val.location, force: 0.5)
                            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                breathScale = 1.04
                            }
                        }
                    }
                    .onEnded { _ in
                        touchOffset = .zero
                        breathScale = 1.0
                        let elapsed = Date().timeIntervalSince(viewModel.holdStartTime ?? Date())
                        if elapsed < 4.0 { viewModel.cancelHold() }
                        else { viewModel.completeHold() }
                    }
            )

            // Status
            if viewModel.holdFailed {
                Text(t(L.Stillness.tooSoon, vi))
                    .font(DS.Font.serif(14))
                    .foregroundColor(DS.Color.crimson)
                    .padding(.top, DS.Spacing.md)
            } else if viewModel.isHolding && viewModel.holdProgress > 0 {
                let remaining = Int(viewModel.holdTargetDuration - Date().timeIntervalSince(viewModel.holdStartTime ?? Date()))
                Text("\(max(remaining, 0))s")
                    .font(DS.Font.serif(16, weight: .semibold))
                    .foregroundColor(DS.Color.gold)
                    .padding(.top, DS.Spacing.sm)
                    .transition(.opacity)
            }

            // Accelerometer live indicator
            if viewModel.isHolding {
                HStack(spacing: 6) {
                    Circle().fill(DS.Color.jade).frame(width: 4, height: 4)
                        .opacity(abs(viewModel.accelX) > 0.03 ? 0.8 : 0.2)
                    Circle().fill(DS.Color.jade).frame(width: 4, height: 4)
                        .opacity(abs(viewModel.accelY) > 0.03 ? 0.8 : 0.2)
                    Circle().fill(DS.Color.jade).frame(width: 4, height: 4)
                        .opacity(abs(viewModel.accelZ - 1.0) > 0.03 ? 0.8 : 0.2)
                }
                .padding(.top, DS.Spacing.xs)
                .transition(.opacity)
            }

            Spacer()

            Text(t(L.Stillness.hint, vi))
                .font(DS.Font.serif(12))
                .foregroundColor(DS.Color.inkFaded.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
        .onAppear { viewModel.holdFailed = false; viewModel.holdProgress = 0 }
        .onChange(of: viewModel.accelX) { _ in
            rippleOffset = CGSize(
                width: CGFloat(viewModel.accelX * 5),
                height: CGFloat(viewModel.accelY * 5)
            )
        }
    }

    /// Position a small circle at angle (degrees) and radius from center
    func circleAt(angle: Double, radius: CGFloat, size: CGFloat, color: Color) -> some View {
        let rad = angle * .pi / 180
        let x = cos(rad) * radius
        let y = sin(rad) * radius
        return Circle()
            .stroke(color, lineWidth: 1)
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }
}
