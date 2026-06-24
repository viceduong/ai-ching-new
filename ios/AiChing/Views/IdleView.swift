import SwiftUI

// MARK: - Idle / Welcome — Single Beautiful Stalk Bundle
struct IdleView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var showUI = false
    @State private var sway: Double = 0

    var vi: Bool { isVietnamese }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // The single, centered, beautiful element: a yarrow stalk bundle
            ZStack {
                // Outer breathing ring
                Circle()
                    .stroke(DS.Color.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 320, height: 320)
                    .scaleEffect(1.0 + 0.015 * sin(sway))

                // Inner thin ring
                Circle()
                    .stroke(DS.Color.gold.opacity(0.08), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    .frame(width: 280, height: 280)

                // 50 yarrow stalks drawn vertically
                YarrowStalkBundle(swayOffset: sin(sway) * 1.5)
                    .frame(width: 200, height: 240)

                // Faint glow at center when not yet tapped
                Circle()
                    .fill(DS.Color.gold.opacity(0.04))
                    .frame(width: 140, height: 140)
                    .scaleEffect(1.0 + 0.05 * sin(sway * 1.3))

                // Center seal
                Text("易")
                    .font(DS.Font.chinese(56))
                    .foregroundColor(DS.Color.ink.opacity(0.6))
                    .offset(y: 100)
            }
            .frame(width: 320, height: 320)
            .contentShape(Circle())
            .onTapGesture {
                if !showUI {
                    withAnimation(.easeOut(duration: 0.4)) { showUI = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(DS.Anim.default) { viewModel.beginRitual() }
                    }
                }
            }

            Spacer()

            // Chinese title (only shown after tap)
            VStack(spacing: 4) {
                Text("易 經")
                    .font(DS.Font.chinese(40))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .tracking(6)

                Text(vi ? "Kinh Dịch" : "The Book of Changes")
                    .font(DS.Font.serif(14, weight: .light))
                    .foregroundColor(DS.Color.inkFaded)
                    .italic()
            }
            .opacity(showUI ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: showUI)

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RitualBackground())
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                sway = 1
            }
        }
    }
}

// MARK: - Yarrow Stalk Bundle
struct YarrowStalkBundle: View {
    let swayOffset: Double
    let stalkCount = 50

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Bundle container background
                RoundedRectangle(cornerRadius: 6)
                    .fill(DS.Color.surface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DS.Color.gold.opacity(0.1), lineWidth: 0.5)
                    )
                    .frame(width: 160, height: 200)
                    .offset(x: 0, y: -10)
                    .blur(radius: 0.5)

                // 50 vertical stalks
                ForEach(0..<stalkCount, id: \.self) { i in
                    let xPos = (CGFloat(i) / CGFloat(stalkCount - 1)) * 180 - 90
                    let yOffset = CGFloat(swayOffset) * CGFloat((i % 3) - 1) * 0.5

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DS.Color.ink.opacity(0.85),
                                    DS.Color.ink.opacity(0.5),
                                    DS.Color.ink.opacity(0.7),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1.5 + CGFloat(i % 3) * 0.5, height: 170 + CGFloat(i % 5) * 3)
                        .offset(x: xPos, y: yOffset - 20)
                }

                // Tie at middle
                Rectangle()
                    .fill(DS.Color.crimson.opacity(0.7))
                    .frame(width: 165, height: 3)
                    .offset(y: 15)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}