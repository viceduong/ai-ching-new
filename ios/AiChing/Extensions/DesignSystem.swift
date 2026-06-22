import SwiftUI

// MARK: - Theme Manager (Persistent Dark/Light Toggle)
/// Use ThemeManager.shared.isDark to read/write the override.
/// Falls back to system color scheme when no override is set.
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("theme_override") private var storedTheme: String = "system"
    @Published var isDark: Bool = false

    private init() {
        sync()
    }

    func setSystem() { storedTheme = "system"; sync() }
    func setLight()  { storedTheme = "light";  sync() }
    func setDark()   { storedTheme = "dark";   sync() }

    var effective: UIUserInterfaceStyle {
        switch storedTheme {
        case "dark":  return .dark
        case "light": return .light
        default:      return .unspecified
        }
    }

    var isOverride: Bool { storedTheme != "system" }

    private func sync() {
        switch storedTheme {
        case "dark":  isDark = true
        case "light": isDark = false
        default:      isDark = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// MARK: - Semantic Colors (Adaptive)
/// All colors adapt to dark/light mode automatically via Color("name") asset catalog
/// or via manual switching. We use the Environment-based approach.
enum Theme {

    // MARK: - Backgrounds
    static let background = AdaptiveColor(
        light: Color(red: 0.96, green: 0.94, blue: 0.89),   // warm rice paper
        dark: Color(red: 0.08, green: 0.075, blue: 0.07)     // deep warm charcoal
    )
    static let surface = AdaptiveColor(
        light: Color(red: 0.99, green: 0.98, blue: 0.95),   // off-white
        dark: Color(red: 0.13, green: 0.12, blue: 0.11)      // lifted dark
    )
    static let surfaceElevated = AdaptiveColor(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),       // white
        dark: Color(red: 0.18, green: 0.17, blue: 0.16)       // elevated dark
    )

    // MARK: - Text
    static let text = AdaptiveColor(
        light: Color(red: 0.10, green: 0.08, blue: 0.06),    // warm near-black
        dark: Color(red: 0.92, green: 0.90, blue: 0.85)       // warm white
    )
    static let textSecondary = AdaptiveColor(
        light: Color(red: 0.40, green: 0.38, blue: 0.34),
        dark: Color(red: 0.70, green: 0.68, blue: 0.63)
    )
    static let textTertiary = AdaptiveColor(
        light: Color(red: 0.55, green: 0.53, blue: 0.49),
        dark: Color(red: 0.55, green: 0.53, blue: 0.49)
    )

    // MARK: - Accents
    static let gold = AdaptiveColor(
        light: Color(red: 0.75, green: 0.58, blue: 0.20),
        dark: Color(red: 0.82, green: 0.68, blue: 0.32)
    )
    static let goldDim = AdaptiveColor(
        light: Color(red: 0.75, green: 0.58, blue: 0.20).opacity(0.6),
        dark: Color(red: 0.82, green: 0.68, blue: 0.32).opacity(0.7)
    )
    static let goldBright = AdaptiveColor(
        light: Color(red: 0.85, green: 0.72, blue: 0.35),
        dark: Color(red: 0.90, green: 0.78, blue: 0.45)
    )
    static let jade = AdaptiveColor(
        light: Color(red: 0.22, green: 0.48, blue: 0.38),
        dark: Color(red: 0.35, green: 0.65, blue: 0.50)
    )
    static let crimson = AdaptiveColor(
        light: Color(red: 0.70, green: 0.12, blue: 0.10),
        dark: Color(red: 0.82, green: 0.25, blue: 0.18)
    )

    // MARK: - Borders / Dividers
    static let divider = AdaptiveColor(
        light: Color.black.opacity(0.06),
        dark: Color.white.opacity(0.08)
    )
    static let stroke = AdaptiveColor(
        light: Color.black.opacity(0.10),
        dark: Color.white.opacity(0.12)
    )

    // MARK: - Shadows
    static let shadow = AdaptiveColor(
        light: Color.black.opacity(0.06),
        dark: Color.black.opacity(0.3)
    )
}

// MARK: - Adaptive Color Wrapper
struct AdaptiveColor {
    let light: Color
    let dark: Color

    func color(_ isDark: Bool) -> Color { isDark ? dark : light }
}

// MARK: - Convenience View Extension
extension View {
    func withTheme() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}

// MARK: - Theme Toggle View
struct ThemeToggleView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) var systemScheme

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if theme.isOverride {
                    theme.setSystem()
                } else {
                    theme.setDark()
                }
            }
        }) {
            Image(systemName: theme.isDark ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 14))
                .foregroundColor(Theme.text.color(theme.isDark))
                .padding(8)
                .background(
                    Circle()
                        .fill(Theme.surface.color(theme.isDark))
                        .overlay(Circle().stroke(Theme.stroke.color(theme.isDark), lineWidth: 1))
                )
        }
    }
}

// MARK: - Typography
enum Fonts {
    static func serif(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func mono(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
    static func chinese(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .thin, design: .serif)
    }
}

// MARK: - Spacing
enum Gap {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum Corner {
    static let sm: CGFloat  = 6
    static let md: CGFloat  = 10
    static let lg: CGFloat  = 16
    static let pill: CGFloat = 999
}

// MARK: - Reusable Components

struct StepBadge: View {
    let number: Int
    let label: String
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.gold.color(isDark))
                .frame(width: 24, height: 24)
                .overlay(Text("\(number)").font(Fonts.serif(12, weight: .bold)).foregroundColor(.white))
            Text(label)
                .font(Fonts.serif(13))
                .foregroundColor(Theme.textSecondary.color(isDark))
        }
    }
}

struct InkDivider: View {
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        Rectangle()
            .fill(Theme.divider.color(isDark))
            .frame(height: 1)
            .padding(.horizontal, Gap.lg)
    }
}

struct SectionTitle: View {
    let chinese: String
    let english: String
    let vietnamese: String?
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        VStack(spacing: 4) {
            Text(chinese)
                .font(Fonts.chinese(42))
                .foregroundColor(Theme.text.color(isDark).opacity(0.5))
            Text(english)
                .font(Fonts.serif(22, weight: .light))
                .foregroundColor(Theme.text.color(isDark).opacity(0.6))
            if let vi = vietnamese {
                Text(vi)
                    .font(Fonts.serif(13))
                    .foregroundColor(Theme.goldDim.color(isDark))
                    .italic()
            }
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let subtitle: String?
    let action: () -> Void
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(Fonts.serif(17, weight: .semibold))
                if let sub = subtitle {
                    Text(sub)
                        .font(Fonts.serif(12))
                        .opacity(0.7)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, Gap.xxl)
            .padding(.vertical, Gap.md)
            .frame(minWidth: 220)
            .background(
                RoundedRectangle(cornerRadius: Corner.md, style: .continuous)
                    .fill(Theme.text.color(isDark))
                    .shadow(color: Theme.shadow.color(isDark), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct LanguageToggle: View {
    @Binding var isVietnamese: Bool
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) { isVietnamese.toggle() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 6) {
                Text("EN")
                    .font(Fonts.serif(12, weight: isVietnamese ? .regular : .semibold))
                    .foregroundColor(isVietnamese ? Theme.textSecondary.color(isDark) : Theme.gold.color(isDark))
                Text("|")
                    .font(Fonts.serif(11))
                    .foregroundColor(Theme.textTertiary.color(isDark))
                Text("VI")
                    .font(Fonts.serif(12, weight: isVietnamese ? .semibold : .regular))
                    .foregroundColor(isVietnamese ? Theme.gold.color(isDark) : Theme.textSecondary.color(isDark))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Corner.pill, style: .continuous)
                    .fill(Theme.surface.color(isDark))
                    .overlay(
                        RoundedRectangle(cornerRadius: Corner.pill, style: .continuous)
                            .stroke(Theme.stroke.color(isDark), lineWidth: 1)
                    )
            )
        }
    }
}

struct RitualBackground: View {
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        Theme.background.color(isDark)
            .ignoresSafeArea()
            .overlay(
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 300))
                    .foregroundColor(isDark ? .white.opacity(0.02) : .black.opacity(0.02))
                    .blur(radius: 4)
            )
    }
}

struct Card<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) var cs
    @EnvironmentObject var theme: ThemeManager
    var isDark: Bool { theme.effective == .dark || (theme.effective == .unspecified && cs == .dark) }

    var body: some View {
        content
            .padding(Gap.md)
            .background(
                RoundedRectangle(cornerRadius: Corner.md, style: .continuous)
                    .fill(Theme.surfaceElevated.color(isDark))
                    .shadow(color: Theme.shadow.color(isDark), radius: 8, x: 0, y: 2)
            )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
