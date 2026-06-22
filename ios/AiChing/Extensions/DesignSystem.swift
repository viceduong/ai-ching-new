import SwiftUI

// MARK: - Theme Override (Persistent Light/Dark Toggle)
/// Set via `@AppStorage("themeOverride")` in AiChingApp.
/// Views read `@Environment(\.colorScheme)` for automatic adaptation.

// MARK: - DS: Backward-Compatible Design Tokens
/// All colors adapt automatically to dark/light mode via SwiftUI environment.
/// Views keep using `DS.Color.ink` etc. — no changes needed.
enum DS {

    // MARK: - Adaptive Colors (auto-switch with system/override)
    enum Color {
        static let ink        = SwiftUI.Color.primary
        static let inkLight   = SwiftUI.Color.primary.opacity(0.8)
        static let inkFaded   = SwiftUI.Color.secondary
        static let inkVeryFaded = SwiftUI.Color.secondary.opacity(0.5)

        static let background = SwiftUI.Color("background") ?? SwiftUI.Color(.systemBackground)
        static let surface    = SwiftUI.Color("surface") ?? SwiftUI.Color(.secondarySystemBackground)
        static let surfaceElevated = SwiftUI.Color("surfaceElevated") ?? SwiftUI.Color(.tertiarySystemBackground)

        static let gold       = SwiftUI.Color("gold") ?? SwiftUI.Color(red: 0.75, green: 0.58, blue: 0.20)
        static let goldLight  = SwiftUI.Color("goldLight") ?? SwiftUI.Color(red: 0.82, green: 0.68, blue: 0.32)
        static let goldDark   = SwiftUI.Color("goldDark") ?? SwiftUI.Color(red: 0.55, green: 0.42, blue: 0.12)
        static let jade       = SwiftUI.Color("jade") ?? SwiftUI.Color(red: 0.22, green: 0.48, blue: 0.38)
        static let jadeLight  = SwiftUI.Color("jadeLight") ?? SwiftUI.Color(red: 0.35, green: 0.65, blue: 0.50)
        static let crimson    = SwiftUI.Color("crimson") ?? SwiftUI.Color(red: 0.70, green: 0.12, blue: 0.10)
        static let vermillion = SwiftUI.Color("vermillion") ?? SwiftUI.Color(red: 0.80, green: 0.25, blue: 0.15)
        static let divider    = SwiftUI.Color("divider") ?? SwiftUI.Color.gray.opacity(0.2)
    }

    // MARK: - Typography
    enum Font {
        static func serif(_ size: CGFloat = 17, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        static func mono(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .monospaced)
        }
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

    // MARK: - Radius
    enum Radius {
        static let sm: CGFloat  = 6
        static let md: CGFloat  = 10
        static let lg: CGFloat  = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows
    enum Shadow {
        static let subtle = SwiftUI.Color.black.opacity(0.04)
        static let soft   = SwiftUI.Color.black.opacity(0.08)
        static let medium = SwiftUI.Color.black.opacity(0.12)
    }

    // MARK: - Animation
    enum Anim {
        static let `default` = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring    = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let slow      = SwiftUI.Animation.easeInOut(duration: 0.6)
        static let ritual    = SwiftUI.Animation.easeInOut(duration: 1.2)
    }
}

// MARK: - Reusable Components

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

struct InkDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Color.divider)
            .frame(height: 1)
            .padding(.horizontal, DS.Spacing.lg)
    }
}

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
                    .foregroundColor(DS.Color.goldLight)
                    .italic()
            }
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let subtitle: String?
    let action: () -> Void
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

struct LanguageToggle: View {
    @AppStorage("lang_vi") var isVietnamese = false

    var body: some View {
        HStack(spacing: 0) {
            // EN button
            Button(action: {
                withAnimation(DS.Anim.spring) { isVietnamese = false }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text("EN")
                    .font(DS.Font.serif(13, weight: isVietnamese ? .regular : .semibold))
                    .foregroundColor(isVietnamese ? DS.Color.inkFaded : Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.pill)
                            .fill(isVietnamese ? Color.clear : DS.Color.ink)
                    )
            }

            // VI button
            Button(action: {
                withAnimation(DS.Anim.spring) { isVietnamese = true }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text("VI")
                    .font(DS.Font.serif(13, weight: isVietnamese ? .semibold : .regular))
                    .foregroundColor(isVietnamese ? Color.white : DS.Color.inkFaded)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.pill)
                            .fill(isVietnamese ? DS.Color.ink : Color.clear)
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.pill)
                .stroke(DS.Color.gold.opacity(0.4), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.pill)
                        .fill(DS.Color.surface)
                )
        )
    }
}

struct RitualBackground: View {
    var body: some View {
        DS.Color.background
            .ignoresSafeArea()
            .overlay(
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 300))
                    .foregroundColor(DS.Color.inkVeryFaded)
                    .blur(radius: 4)
            )
    }
}

struct Card<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .fill(DS.Color.surfaceElevated)
                    .shadow(color: DS.Shadow.subtle, radius: 8, x: 0, y: 2)
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardShadow() -> some View {
        self.shadow(color: DS.Shadow.subtle, radius: 8, x: 0, y: 2)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - ThemeToggle View
// MARK: - Global Vietnamese Preference (via UserDefaults)
var isVietnamesePref: Bool {
    get { UserDefaults.standard.bool(forKey: "lang_vi") }
    set { UserDefaults.standard.set(newValue, forKey: "lang_vi") }
}

struct ThemeToggleView: View {
    @AppStorage("themeOverride") private var themeOverride: String = "system"

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                switch themeOverride {
                case "dark": themeOverride = "light"
                case "light": themeOverride = "system"
                default: themeOverride = "dark"
                }
            }
        }) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(DS.Color.ink)
                .padding(8)
                .background(
                    Circle()
                        .fill(DS.Color.surface)
                        .overlay(Circle().stroke(DS.Color.divider, lineWidth: 1))
                )
        }
    }

    var iconName: String {
        switch themeOverride {
        case "dark": return "sun.max.fill"
        case "light": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Override color scheme from AppStorage
/// Call from AiChingApp: `preferredColorScheme(ThemeOverride.effective)`
enum ThemeOverride {
    @AppStorage("themeOverride") static var stored: String = "system"

    static var effective: ColorScheme? {
        switch stored {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil
        }
    }
}
