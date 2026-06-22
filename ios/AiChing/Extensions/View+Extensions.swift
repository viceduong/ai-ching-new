import SwiftUI

// MARK: - View Extensions

extension View {
    /// Conditional view modifier for iOS version compatibility
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply a subtle sakura/ink background
    func ritualBackground() -> some View {
        self.background(
            RitualBackgroundView()
        )
    }
}

// MARK: - Ritual Background

struct RitualBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Color(red: 0.08, green: 0.06, blue: 0.10)
                // Subtle silk texture overlay
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 200))
                    .opacity(0.03)
                    .blur(radius: 3)
            } else {
                Color(red: 0.97, green: 0.95, blue: 0.90)
                // Subtle rice paper texture
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 200))
                    .opacity(0.04)
                    .blur(radius: 2)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hexagram Line Drawing

/// Renders a single hexagram line (yang or yin) as a brush-stroke style horizontal bar.
struct HexagramLineView: View {
    let isYang: Bool
    let isMoving: Bool
    let color: Color
    let animated: Bool
    let width: CGFloat

    @State private var drawProgress: CGFloat = 0

    init(isYang: Bool, isMoving: Bool = false,
         color: Color = .black, animated: Bool = true,
         width: CGFloat = 120) {
        self.isYang = isYang
        self.isMoving = isMoving
        self.color = color
        self.animated = animated
        self.width = width
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .opacity(isMoving ? 0.85 : 0.7)
                .frame(width: isYang ? width : width * 0.45, height: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
                .scaleEffect(x: drawProgress, y: 1, anchor: .leading)

            if !isYang {
                Spacer().frame(width: width * 0.1)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .opacity(isMoving ? 0.85 : 0.7)
                    .frame(width: width * 0.45, height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
                    .scaleEffect(x: drawProgress, y: 1, anchor: .leading)
            }
        }
        .frame(width: width, height: 10)
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                    drawProgress = 1.0
                }
            } else {
                drawProgress = 1.0
            }
        }
    }
}

// MARK: - Step Progress Indicator

struct StepProgressView: View {
    let currentStep: RitualStep
    let totalSteps: Int = 6

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(currentStep.rawValue == step ? Color.gold : Color.clear, lineWidth: 1.5)
                    )
            }
        }
    }

    private func stepColor(for step: Int) -> Color {
        if step < currentStep.rawValue {
            return .gold
        } else if step == currentStep.rawValue {
            return .gold.opacity(0.7)
        } else {
            return .gray.opacity(0.25)
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let gold = Color(red: 0.83, green: 0.67, blue: 0.22)
    static let inkBlack = Color(red: 0.12, green: 0.10, blue: 0.08)
    static let ricePaper = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let darkSilk = Color(red: 0.08, green: 0.06, blue: 0.10)
    static let crimson = Color(red: 0.72, green: 0.15, blue: 0.12)
    static let movingGold = Color(red: 0.90, green: 0.73, blue: 0.30)
    static let jade = Color(red: 0.25, green: 0.51, blue: 0.43)
}

// MARK: - Section Divider

struct RitualDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.gold.opacity(0.4))
            .frame(height: 1)
            .padding(.horizontal)
    }
}

// MARK: - Calligraphy Title Style

struct CalligraphyTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title2, design: .serif).weight(.semibold))
            .foregroundColor(.inkBlack)
    }
}

extension View {
    func calligraphyTitle() -> some View {
        modifier(CalligraphyTitle())
    }
}
