import SwiftUI

// MARK: - Design System
/// App Store-quality design tokens for AiChing.
/// Inspired by Headspace (calm meditation), Day One (journaling), and classical sumi-e aesthetics.
enum DS {

    // MARK: - Colors
    enum Color {
        static let ink        = SwiftUI.Color(red: 0.08, green: 0.07, blue: 0.06)
        static let inkLight   = SwiftUI.Color(red: 0.20, green: 0.18, blue: 0.16)
        static let inkFaded   = SwiftUI.Color(red: 0.45, green: 0.42, blue: 0.38)
        static let ricePaper  = SwiftUI.Color(red: 0.97, green: 0.95, blue: 0.90)
        static let ricePaperDark = SwiftUI.Color(red: 0.12, green: 0.11, blue: 0.09)
        static let gold       = SwiftUI.Color(red: 0.78, green: 0.62, blue: 0.24)
        static let goldLight  = SwiftUI.Color(red: 0.90, green: 0.78, blue: 0.40)
        static let goldDark   = SwiftUI.Color(red: 0.55, green: 0.42, blue: 0.12)
        static let jade       = SwiftUI.Color(red: 0.25, green: 0.51, blue: 0.43)
        static let jadeLight  = SwiftUI.Color(red: 0.40, green: 0.70, blue: 0.55)
        static let crimson    = SwiftUI.Color(red: 0.72, green: 0.15, blue: 0.12)
        static let vermillion = SwiftUI.Color(red: 0.85, green: 0.30, blue: 0.15)
        static let silk       = SwiftUI.Color(red: 0.92, green: 0.88, blue: 0.82)
        static let silkDark   = SwiftUI.Color(red: 0.18, green: 0.16, blue: 0.14)
        static let surface    = SwiftUI.Color(red: 0.99, green: 0.98, blue: 0.95)
        static let surfaceDark = SwiftUI.Color(red: 0.10, green: 0.09, blue: 0.08)
    }

    // MARK: - Typography
    enum Font {
        /// Serif font for Chinese characters and ceremonial text
        static func serif(_ size: CGFloat = 17, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        /// Monospace for hash/seed display
        static func mono(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
        /// Display serif for large Chinese characters
        static func chinese(_ size: CGFloat = 48) -> SwiftUI.Font {
            .system(size: size, weight: .thin, design: .serif)
        }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat   = 4
        static let sm: CGFloat   = 8
        static let md: CGFloat   = 16
        static let lg: CGFloat   = 24
        static let xl: CGFloat   = 32
        static let xxl: CGFloat  = 48
        static let section: CGFloat = 40
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat  = 4
        static let md: CGFloat  = 8
        static let lg: CGFloat  = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows
    enum Shadow {
        static let subtle = SwiftUI.Color.black.opacity(0.04)
        static let soft   = SwiftUI.Color.black.opacity(0.08)
        static let medium = SwiftUI.Color.black.opacity(0.12)

        static func cardLight() -> some ViewModifier {
            CardShadowModifier(color: subtle, radius: 8, y: 2)
        }
        static func cardDark() -> some ViewModifier {
            CardShadowModifier(color: medium, radius: 12, y: 3)
        }
    }

    // MARK: - Animation
    enum Anim {
        static let `default` = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring    = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let slow      = SwiftUI.Animation.easeInOut(duration: 0.6)
        static let ritual    = SwiftUI.Animation.easeInOut(duration: 1.2)
    }
}

// MARK: - Shadow Modifier
struct CardShadowModifier: ViewModifier {
    let color: SwiftUI.Color
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: 0, y: y)
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(DS.Shadow.cardLight())
    }
}

// MARK: - Reusable Components

/// Ceremonial step number badge
struct StepBadge: View {
    let number: Int
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DS.Color.gold)
                .frame(width: 24, height: 24)
                .overlay(Text("\(number)").font(DS.Font.serif(12, weight: .bold)).foregroundColor(.white))
            Text(label)
                .font(DS.Font.serif(13))
                .foregroundColor(DS.Color.inkFaded)
        }
    }
}

/// Ink divider — thin gold line
struct InkDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Color.gold.opacity(0.3))
            .frame(height: 1)
            .padding(.horizontal, DS.Spacing.lg)
    }
}

/// Calligraphy title block
struct SectionTitle: View {
    let chinese: String
    let english: String
    let vietnamese: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(chinese)
                .font(DS.Font.chinese(42))
                .foregroundColor(DS.Color.ink.opacity(0.5))
            Text(english)
                .font(DS.Font.serif(22, weight: .light))
                .foregroundColor(DS.Color.ink.opacity(0.6))
            if let vi = vietnamese {
                Text(vi)
                    .font(DS.Font.serif(13))
                    .foregroundColor(DS.Color.gold.opacity(0.7))
                    .italic()
            }
        }
    }
}

/// Primary action button
struct PrimaryButton: View {
    let title: String
    let subtitle: String?
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(DS.Font.serif(17, weight: .semibold))
                if let sub = subtitle {
                    Text(sub)
                        .font(DS.Font.serif(12))
                        .opacity(0.7)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.vertical, DS.Spacing.md)
            .frame(minWidth: 220)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Color.ink)
                    .shadow(color: DS.Shadow.medium, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .stroke(DS.Color.gold.opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Ghost button (outlined)
struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.serif(15))
                .foregroundColor(DS.Color.inkFaded)
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .stroke(DS.Color.ink.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

/// Language toggle pill
struct LanguageToggle: View {
    @Binding var isVietnamese: Bool

    var body: some View {
        Button(action: {
            withAnimation(DS.Anim.spring) { isVietnamese.toggle() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 6) {
                Text("EN")
                    .font(DS.Font.serif(12, weight: isVietnamese ? .regular : .semibold))
                    .foregroundColor(isVietnamese ? DS.Color.inkFaded : DS.Color.gold)
                Text("|")
                    .font(DS.Font.serif(11))
                    .foregroundColor(DS.Color.inkFaded.opacity(0.4))
                Text("VI")
                    .font(DS.Font.serif(12, weight: isVietnamese ? .semibold : .regular))
                    .foregroundColor(isVietnamese ? DS.Color.gold : DS.Color.inkFaded)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.pill, style: .continuous)
                    .fill(DS.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.pill, style: .continuous)
                            .stroke(DS.Color.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Background
struct RitualBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        (colorScheme == .dark ? DS.Color.ricePaperDark : DS.Color.ricePaper)
            .ignoresSafeArea()
            .overlay(
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 300))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.02) : .black.opacity(0.02))
                    .blur(radius: 4)
            )
    }
}

// MARK: - Card
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Color.surface)
                    .shadow(color: DS.Shadow.subtle, radius: 8, x: 0, y: 2)
            )
    }
}
