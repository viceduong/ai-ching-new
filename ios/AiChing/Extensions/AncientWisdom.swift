import SwiftUI

// MARK: - Ancient Wisdom Aesthetic Components
/// Adds classical East Asian ink-wash aesthetic: seal stamps, aged paper, calligraphy borders.

// MARK: - Seal Stamp (red square with white carved characters)
struct SealStamp: View {
    let text: String         // Chinese characters
    let size: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.72, green: 0.12, blue: 0.10)) // cinnabar red
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
            Text(text)
                .font(.system(size: size * 0.35, weight: .bold, design: .serif))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Aged Paper Overlay
/// Subtle worn texture overlay to give backgrounds an aged scroll feel.
struct AgedPaperOverlay: View {
    var body: some View {
        Image(systemName: "circle.grid.cross")
            .font(.system(size: 300))
            .foregroundColor(.primary.opacity(0.03))
            .blur(radius: 2)
            .overlay(
                LinearGradient(
                    colors: [
                        .black.opacity(0.0),
                        .black.opacity(0.015),
                        .clear,
                        .black.opacity(0.01),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Decorative Top Border (classical Chinese scroll header)
struct ScrollTopBorder: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top decorative line
            HStack(spacing: 6) {
                ForEach(0..<3) { _ in
                    Rectangle().fill(Color.gold).frame(width: 20, height: 2)
                }
                Rectangle().fill(Color.gold).frame(height: 1)
                ForEach(0..<3) { _ in
                    Rectangle().fill(Color.gold).frame(width: 20, height: 2)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Decorative Bottom Border
struct ScrollBottomBorder: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { _ in
                Rectangle().fill(Color.gold).frame(width: 20, height: 2)
            }
            Rectangle().fill(Color.gold).frame(height: 1)
            ForEach(0..<3) { _ in
                Rectangle().fill(Color.gold).frame(width: 20, height: 2)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Hexagram Name with Seal
struct HexagramNameSeal: View {
    let chineseName: String
    let englishName: String
    let vietnameseName: String?
    let number: Int
    @AppStorage("lang_vi") var isVietnamese = false

    var vi: Bool { isVietnamese }

    var body: some View {
        HStack(spacing: 16) {
            // Hexagram number
            Text("\(number)")
                .font(DS.Font.serif(40, weight: .light))
                .foregroundColor(DS.Color.gold.opacity(0.3))

            VStack(alignment: .leading, spacing: 4) {
                Text(chineseName)
                    .font(DS.Font.chinese(28))
                    .foregroundColor(DS.Color.ink)

                HStack(spacing: 8) {
                    SealStamp(text: chineseName.prefix(1).description, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(englishName)
                            .font(DS.Font.serif(16, weight: .semibold))
                            .foregroundColor(DS.Color.ink)
                        if let viName = vietnameseName, vi {
                            Text(viName)
                                .font(DS.Font.serif(13))
                                .foregroundColor(DS.Color.gold.opacity(0.8))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
    }
}

// MARK: - Ancient Wisdom Text Style
/// Applies a classical ink-wash text treatment.
struct AncientText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DS.Font.serif())
            .lineSpacing(6)
            .tracking(0.5)
    }
}

extension View {
    func ancientText() -> some View {
        modifier(AncientText())
    }
}

// MARK: - Decorative Divider (classical Chinese pattern)
struct ClassicalDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.gold.opacity(0.3).frame(height: 1)
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(DS.Color.gold)
            Color.gold.opacity(0.3).frame(height: 1)
        }
        .padding(.horizontal, DS.Spacing.lg)
    }
}

// MARK: - Aged Card Background
/// Card with subtle wear and border that looks like aged paper
struct AgedCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(DS.Color.surfaceElevated)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(DS.Color.gold.opacity(0.15), lineWidth: 0.5)
                    )
            )
    }
}
