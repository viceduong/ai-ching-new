import SwiftUI

// MARK: - Step 1: Stillness with Bagua Mandala
struct StillnessView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var breathScale: CGFloat = 1.0
    @State private var touchOffset: CGSize = .zero
    @State private var rippleOffset: CGSize = .zero
    @State private var outerRotation: Double = 0

    var vi: Bool { isVietnamese }

    // Four symbols (Tứ Tượng) at cardinal directions
    private let fourSymbols: [(name: String, lines: [Bool], angle: Double)] = [
        ("Thái Dương", [true, true, true], 270),    // ☰ Heaven, top
        ("Thiếu Âm",  [true, true, false], 0),       // ☱ Lake, right
        ("Thái Âm",   [false, false, false], 90),    // ☷ Earth, bottom
        ("Thiếu Dương", [false, true, true], 180),   // ☳ Thunder, left
    ]

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 1, label: t(L.Step.stillness, vi))
                .padding(.top, 60)

            Text(t(L.Stillness.instruction, vi))
                .font(DS.Font.serif(14))
                .foregroundColor(DS.Color.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

            Spacer().frame(height: 30)

            // Bagua Mandala: 4 trigrams around central hold circle
            ZStack {
                // Outer rotating ring with all 8 trigrams
                BaguaCompass(size: 280)
                    .rotationEffect(.degrees(outerRotation))
                    .opacity(0.35)

                // Decorative rings
                Circle()
                    .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 240, height: 240)
                    .scaleEffect(breathScale)

                Circle()
                    .stroke(DS.Color.gold.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(width: 220, height: 220)

                // Four Tứ Tượng trigrams at cardinal points
                ForEach(0..<fourSymbols.count, id: \.self) { idx in
                    let sym = fourSymbols[idx]
                    let rad = sym.angle * .pi / 180
                    let r: CGFloat = 130
                    let x = cos(rad) * r
                    let y = sin(rad) * r

                    VStack(spacing: 3) {
                        TrigramView(lines: sym.lines, width: 26, isHighlighted: false)
                        Text(sym.name)
                            .font(DS.Font.serif(7))
                            .foregroundColor(DS.Color.gold.opacity(0.5))
                    }
                    .offset(x: x, y: y)
                    .opacity(0.7)
                }

                // Progress arc
                Circle()
                    .trim(from: 0, to: viewModel.holdProgress)
                    .stroke(DS.Color.crimson, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                // Ripple ring (accelerometer)
                Circle()
                    .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1)
                    .frame(width: 180, height: 180)
                    .scaleEffect(1.0 + 0.05 * CGFloat(min(abs(viewModel.accelX) + abs(viewModel.accelY), 1.0)))
                    .offset(rippleOffset)
                    .opacity(viewModel.isHolding ? 0.6 : 0)

                // Ink pool (hold progress)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DS.Color.ink.opacity(0.3 + 0.55 * viewModel.holdProgress),
                                DS.Color.ink.opacity(0.15 + 0.25 * viewModel.holdProgress),
                                DS.Color.ink.opacity(0.05),
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)
                    .offset(touchOffset)

                // Yin-Yang center
                YinYangView(size: 50)
                    .opacity(0.85)

                // Hold progress text
                Text(viewModel.holdProgress > 0
                    ? "\(Int(viewModel.holdProgress * 100))%"
                    : (vi ? "Giữ" : "Hold"))
                    .font(DS.Font.serif(18, weight: .bold))
                    .foregroundColor(viewModel.holdProgress > 0.4
                        ? DS.Color.surface
                        : DS.Color.gold)
                    .offset(y: 75)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .frame(width: 300, height: 300)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let center = CGPoint(x: 150, y: 150)
                        let dx = (val.location.x - center.x) * 0.2
                        let dy = (val.location.y - center.y) * 0.2
                        touchOffset = CGSize(width: dx, height: dy)
                        if !viewModel.isHolding {
                            viewModel.beginHold(at: val.location, force: 0.5)
                            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
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
                    .font(DS.Font.serif(13))
                    .foregroundColor(DS.Color.crimson)
                    .padding(.top, DS.Spacing.sm)
            } else if viewModel.isHolding && viewModel.holdProgress > 0 {
                let remaining = Int(viewModel.holdTargetDuration - Date().timeIntervalSince(viewModel.holdStartTime ?? Date()))
                HStack(spacing: 8) {
                    Image(systemName: "timer").font(.caption)
                    Text("\(max(remaining, 0))s").font(DS.Font.serif(14, weight: .semibold))
                }
                .foregroundColor(DS.Color.crimson)
                .padding(.top, DS.Spacing.sm)
                .transition(.opacity)
            }

            Spacer()

            Text(t(L.Stillness.hint, vi))
                .font(DS.Font.serif(11))
                .foregroundColor(DS.Color.inkFaded.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
        .onAppear {
            viewModel.holdFailed = false
            viewModel.holdProgress = 0
            withAnimation(.easeInOut(duration: 30).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
        }
        .onChange(of: viewModel.accelX) { _ in
            rippleOffset = CGSize(
                width: CGFloat(viewModel.accelX * 5),
                height: CGFloat(viewModel.accelY * 5)
            )
        }
    }
}