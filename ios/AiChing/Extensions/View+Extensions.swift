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
    var body: some View {
        Color.ricePaper
            .ignoresSafeArea()
            .overlay(
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 200))
                    .foregroundColor(.primary.opacity(0.03))
                    .blur(radius: 3)
            )
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
            .padding(.vertical, 2)
        }
    }

    private func stepColor(for step: Int) -> Color {
        if step < currentStep.rawValue {
            return .gold
        } else if step == currentStep.rawValue {
            return .gold
        } else {
            return .gray.opacity(0.2)
        }
    }
}

// MARK: - Color Extensions

// MARK: - Adaptive Colors (Auto Light/Dark via UIColor trait collection)
extension Color {
    /// Warm text color: near-black in light, warm white in dark
    static let inkBlack = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1)
        : UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1) })

    /// Background: warm rice paper in light, dark warm charcoal in dark
    static let ricePaper = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.08, green: 0.075, blue: 0.07, alpha: 1)
        : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1) })

    /// Elevated surface
    static let surfaceWhite = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 1)
        : UIColor(red: 0.99, green: 0.98, blue: 0.95, alpha: 1) })

    /// Gold accent — works in both modes (adjust brightness in dark)
    static let gold = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.82, green: 0.68, blue: 0.32, alpha: 1)
        : UIColor(red: 0.75, green: 0.58, blue: 0.20, alpha: 1) })

    /// Dark silk (replaced by adaptive)
    static let darkSilk = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1)
        : UIColor(red: 0.08, green: 0.06, blue: 0.10, alpha: 1) })

    /// Crimson — slightly brighter in dark for legibility
    static let crimson = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.85, green: 0.28, blue: 0.20, alpha: 1)
        : UIColor(red: 0.72, green: 0.15, blue: 0.12, alpha: 1) })

    /// Moving gold (used for changing lines) — bright enough in both modes
    static let movingGold = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.90, green: 0.75, blue: 0.35, alpha: 1)
        : UIColor(red: 0.85, green: 0.68, blue: 0.25, alpha: 1) })

    /// Jade — brighter in dark
    static let jade = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.38, green: 0.68, blue: 0.52, alpha: 1)
        : UIColor(red: 0.25, green: 0.51, blue: 0.43, alpha: 1) })

    /// Divider
    static let inkDivider = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 0.20, alpha: 0.6)
        : UIColor(white: 0.75, alpha: 0.4) })
}

// MARK: - Section Divider

struct RitualDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.inkDivider)
            .frame(height: 1)
            .padding(.horizontal)
    }
}

// MARK: - Calligraphy Title Style

struct CalligraphyTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title2, design: .serif).weight(.semibold))
            .foregroundColor(.primary)
    }
}

extension View {
    func calligraphyTitle() -> some View {
        modifier(CalligraphyTitle())
    }

    /// Hides scrollable content background (TextEditor etc).
    /// iOS 15: uses UITextView appearance; iOS 16+: uses native API.
    func hideScrollBackground() -> some View {
        if #available(iOS 16.0, *) {
            return AnyView(self.scrollContentBackground(.hidden))
        } else {
            UITextView.appearance().backgroundColor = .clear
            return AnyView(self)
        }
    }
}
