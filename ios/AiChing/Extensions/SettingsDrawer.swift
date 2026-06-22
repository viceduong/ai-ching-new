import SwiftUI

// MARK: - Unified Settings Drawer
/// Slides up from bottom. Contains theme toggle + language toggle.
/// Accessed via gear icon on every ritual step.

struct SettingsDrawer: View {
    @Binding var isOpen: Bool
    @AppStorage("themeOverride") private var themeOverride: String = "system"
    @AppStorage("lang_vi") private var isVietnamese = false
    @Environment(\.colorScheme) var cs

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop
            if isOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeOut(duration: 0.25)) { isOpen = false } }
                    .transition(.opacity)
            }

            // Drawer panel
            if isOpen {
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 16)

                    Text("Settings".uppercased())
                        .font(DS.Font.serif(12, weight: .semibold))
                        .foregroundColor(DS.Color.inkFaded)
                        .tracking(2)
                        .padding(.bottom, DS.Spacing.md)

                    // Language
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                                .foregroundColor(DS.Color.gold)
                            Text("Language")
                                .font(DS.Font.serif(16))
                                .foregroundColor(DS.Color.ink)
                            Spacer()
                            LanguageToggle()
                        }
                        .padding(.horizontal, DS.Spacing.lg)
                    }

                    Divider().padding(.vertical, DS.Spacing.sm)

                    // Theme
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 14))
                                .foregroundColor(DS.Color.gold)
                            Text("Appearance")
                                .font(DS.Font.serif(16))
                                .foregroundColor(DS.Color.ink)
                            Spacer()
                        }
                        .padding(.horizontal, DS.Spacing.lg)

                        HStack(spacing: 0) {
                            themeButton("System", icon: "circle.lefthalf.filled", key: "system")
                            themeButton("Light", icon: "sun.max.fill", key: "light")
                            themeButton("Dark", icon: "moon.fill", key: "dark")
                        }
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.bottom, DS.Spacing.sm)
                    }

                    Spacer().frame(height: DS.Spacing.lg)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cs == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : Color(red: 0.99, green: 0.98, blue: 0.95))
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .animation(.easeOut(duration: 0.3), value: isOpen)
        .ignoresSafeArea(edges: .bottom)
    }

    func themeButton(_ label: String, icon: String, key: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                themeOverride = key
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(DS.Font.serif(11))
            }
            .foregroundColor(themeOverride == key ? Color.white : DS.Color.inkFaded)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(themeOverride == key ? DS.Color.ink : Color.clear)
            )
        }
    }
}

// MARK: - Settings Button (gear icon)
struct SettingsButton: View {
    @Binding var showDrawer: Bool

    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.2)) { showDrawer.toggle() }
        }) {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundColor(DS.Color.inkFaded)
                .padding(10)
        }
    }
}
