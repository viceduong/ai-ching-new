import SwiftUI

// MARK: - Trigram Drawing
/// Renders an I Ching trigram (3-line bagua symbol).
/// `lines`: array of 3 booleans. true = yang (solid), false = yin (broken)
struct TrigramView: View {
    let lines: [Bool]   // bottom to top: [0]=bottom, [2]=top
    let width: CGFloat
    let isHighlighted: Bool

    var body: some View {
        VStack(spacing: width * 0.1) {
            // Top line (lines[2]) drawn first in VStack
            ForEach((0..<3).reversed(), id: \.self) { idx in
                trigramLine(broken: !lines[idx], width: width * 0.8)
            }
        }
        .frame(width: width, height: width * 0.6)
        .opacity(isHighlighted ? 1.0 : 0.5)
    }

    private func trigramLine(broken: Bool, width: CGFloat) -> some View {
        HStack(spacing: width * 0.08) {
            RoundedRectangle(cornerRadius: 1)
                .fill(isHighlighted ? DS.Color.ink : DS.Color.inkFaded.opacity(0.4))
                .frame(width: broken ? width * 0.45 : width, height: 2.5)
            if broken {
                RoundedRectangle(cornerRadius: 1)
                    .fill(isHighlighted ? DS.Color.ink : DS.Color.inkFaded.opacity(0.4))
                    .frame(width: width * 0.45, height: 2.5)
            }
        }
    }
}

// MARK: - Hexagram Drawing (6 lines)
struct HexagramView: View {
    let lines: [Bool]   // bottom to top: [0]=bottom line, [5]=top line
    let movingLines: [Int]  // indices of moving (changing) lines
    let width: CGFloat

    var body: some View {
        VStack(spacing: width * 0.08) {
            ForEach((0..<6).reversed(), id: \.self) { idx in
                hexagramLine(
                    broken: !lines[idx],
                    isMoving: movingLines.contains(idx),
                    width: width * 0.8
                )
            }
        }
        .frame(width: width, height: width * 0.65)
    }

    private func hexagramLine(broken: Bool, isMoving: Bool, width: CGFloat) -> some View {
        HStack(spacing: width * 0.06) {
            // Solid or broken line
            if broken {
                RoundedRectangle(cornerRadius: 1)
                    .fill(lineColor(isMoving: isMoving))
                    .frame(width: width * 0.45, height: isMoving ? 3.5 : 2.5)
                RoundedRectangle(cornerRadius: 1)
                    .fill(lineColor(isMoving: isMoving))
                    .frame(width: width * 0.45, height: isMoving ? 3.5 : 2.5)
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(lineColor(isMoving: isMoving))
                    .frame(width: width, height: isMoving ? 3.5 : 2.5)
            }
        }
        .overlay(alignment: .trailing) {
            if isMoving {
                // Small indicator dot for moving line
                Circle()
                    .fill(DS.Color.crimson.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(x: 6)
            }
        }
    }

    private func lineColor(isMoving: Bool) -> Color {
        if isMoving {
            return DS.Color.crimson
        }
        return DS.Color.ink
    }
}

// MARK: - Yin-Yang (Tai Chi) Symbol
struct YinYangView: View {
    let size: CGFloat
    var rotation: Double = 0

    var body: some View {
        ZStack {
            // Black half (right)
            Path { p in
                let r = size / 2
                p.addArc(center: .init(x: r, y: r), radius: r,
                         startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                p.addArc(center: .init(x: r, y: r/2), radius: r/2,
                         startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
                p.addArc(center: .init(x: r, y: 3*r/2), radius: r/2,
                         startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
                p.closeSubpath()
            }
            .fill(DS.Color.ink)

            // White half (left)
            Path { p in
                let r = size / 2
                p.addArc(center: .init(x: r, y: r), radius: r,
                         startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: false)
                p.addArc(center: .init(x: r, y: r/2), radius: r/2,
                         startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                p.addArc(center: .init(x: r, y: 3*r/2), radius: r/2,
                         startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: false)
                p.closeSubpath()
            }
            .fill(DS.Color.surface)

            // Black dot in white half
            Circle()
                .fill(DS.Color.ink)
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(y: -size * 0.25)

            // White dot in black half
            Circle()
                .fill(DS.Color.surface)
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(y: size * 0.25)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Bagua Compass (8 trigrams arranged in circle)
struct BaguaCompass: View {
    let size: CGFloat

    // 8 trigrams arranged around compass
    // Order matches King Wen sequence
    private let trigramData: [(name: String, lines: [Bool])] = [
        ("Càn", [true, true, true]),       // ☰ Heaven (top)
        ("Đoài", [true, true, false]),     // ☱ Lake (NE)
        ("Ly", [true, false, true]),       // ☲ Fire (E)
        ("Chấn", [false, true, true]),     // ☳ Thunder (SE)
        ("Tốn", [false, false, true]),     // ☴ Wind (S)
        ("Khảm", [true, false, false]),    // ☵ Water (SW)
        ("Cấn", [false, true, false]),     // ☶ Mountain (W)
        ("Khôn", [false, false, false]),    // ☷ Earth (NW)
    ]

    var body: some View {
        ZStack {
            // Outer ring (subtle)
            Circle()
                .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                .frame(width: size, height: size)

            // 8 trigrams at compass positions
            ForEach(0..<8, id: \.self) { idx in
                let angle = Double(idx) * 45.0 - 90.0  // Start at top, go clockwise
                let rad = angle * .pi / 180
                let r = size * 0.35
                let x = cos(rad) * r
                let y = sin(rad) * r

                VStack(spacing: 2) {
                    TrigramView(lines: trigramData[idx].lines, width: 24, isHighlighted: false)
                    Text(trigramData[idx].name)
                        .font(DS.Font.serif(8))
                        .foregroundColor(DS.Color.gold.opacity(0.5))
                }
                .offset(x: x, y: y)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Decorative Divider with Seal
struct ScrollDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(DS.Color.gold.opacity(0.3)).frame(height: 1)
            SealStampView(text: "易", size: 22)
            Rectangle().fill(DS.Color.gold.opacity(0.3)).frame(height: 1)
        }
        .padding(.horizontal, DS.Spacing.lg)
    }
}

// MARK: - Seal Stamp (Cinnabar red with carved white text)
struct SealStampView: View {
    let text: String
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer border
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.72, green: 0.13, blue: 0.10))
                )

            // Character
            Text(text)
                .font(.system(size: size * 0.55, weight: .black, design: .serif))
                .foregroundColor(Color.white.opacity(0.92))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Breathing Circle
/// A circle that gently breathes (scales 0.95-1.05) for meditation.
struct BreathingCircle: View {
    let color: Color
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    @State private var scale: CGFloat = 1.0
    @State private var isInhaling = true

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 1.5)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = isInhaling ? maxScale : minScale
                }
                Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
                    isInhaling.toggle()
                    withAnimation(
                        .easeInOut(duration: duration)
                    ) {
                        scale = isInhaling ? maxScale : minScale
                    }
                }
            }
    }
}