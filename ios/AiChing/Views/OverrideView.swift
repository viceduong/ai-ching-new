import SwiftUI

// MARK: - Step 5: Intuition Override
struct OverrideView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false

    var vi: Bool { isVietnamese }

    private let labels = [
        Localized("Bottom (1st)", "Sơ (Hào 1)"),
        Localized("2nd", "Nhị (Hào 2)"),
        Localized("3rd", "Tam (Hào 3)"),
        Localized("4th", "Tứ (Hào 4)"),
        Localized("5th", "Ngũ (Hào 5)"),
        Localized("Top (6th)", "Thượng (Hào 6)")
    ]

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 5, label: t(L.Step.override, vi))
                .padding(.top, 60)

            Text(t(L.Override.instruction, vi))
                .font(DS.Font.serif(13))
                .foregroundColor(DS.Color.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DS.Spacing.md) {
                    if let result = viewModel.computedResult {
                        HexagramHeader(index: result.primaryIndex, vi: vi)

                        // Lines using HexagramView
                        VStack(spacing: 8) {
                            ForEach((0..<6).reversed(), id: \.self) { i in
                                let displayIdx = 5 - i
                                let val = viewModel.overriddenLines[safe: displayIdx] ?? .youngYin
                                let isYang = val == .youngYang || val == .oldYang
                                let isMoving = val == .oldYin || val == .oldYang

                                Button(action: { viewModel.toggleLine(at: displayIdx) }) {
                                    HStack {
                                        Text(labels[safe: displayIdx]?.text(vi) ?? "Line \(displayIdx+1)")
                                            .font(DS.Font.serif(12))
                                            .foregroundColor(DS.Color.inkFaded)
                                            .frame(width: 80, alignment: .leading)

                                        Spacer()

                                        HStack(spacing: 4) {
                                            if isYang {
                                                Capsule().fill(isMoving ? DS.Color.crimson : DS.Color.ink)
                                                    .frame(width: 56, height: 4)
                                            } else {
                                                Capsule().fill(isMoving ? DS.Color.crimson : DS.Color.ink)
                                                    .opacity(isMoving ? 0.9 : 0.5)
                                                    .frame(width: 26, height: 4)
                                                Capsule().fill(isMoving ? DS.Color.crimson : DS.Color.ink)
                                                    .opacity(isMoving ? 0.9 : 0.5)
                                                    .frame(width: 26, height: 4)
                                            }
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text(val.chineseChar)
                                                .font(DS.Font.serif(10))
                                                .foregroundColor(isMoving ? DS.Color.crimson : DS.Color.inkFaded)
                                            Text("\(val.rawValue)")
                                                .font(DS.Font.mono(9))
                                                .foregroundColor(DS.Color.inkFaded.opacity(0.5))
                                        }
                                    }
                                    .padding(.horizontal, DS.Spacing.sm)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                                            .fill(isMoving ? DS.Color.crimson.opacity(0.06) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(DS.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(DS.Color.surfaceElevated)
                                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                        )
                        .padding(.horizontal, DS.Spacing.lg)
                    }
                }
                .padding(.vertical, DS.Spacing.md)
            }

            // Secondary hexagram preview
            if let result = viewModel.computedResult, result.hasMovingLines {
                HStack(spacing: 6) {
                    Text(t(L.Override.forming, vi))
                        .font(DS.Font.serif(12))
                        .foregroundColor(DS.Color.inkFaded)
                    Image(systemName: "arrow.right").font(.caption).foregroundColor(DS.Color.gold)
                    Text(HexagramService.shared.name(for: result.secondaryIndex ?? 0))
                        .font(DS.Font.serif(13, weight: .semibold))
                        .foregroundColor(DS.Color.gold)
                }
                .padding(.top, DS.Spacing.xs)
            }

            Spacer()

            PrimaryButton(title: t(L.Override.accept, vi), subtitle: nil) {
                withAnimation(DS.Anim.default) { viewModel.acceptOracle() }
            }
            .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
    }
}

// MARK: - Hexagram Header with Chinese name + seal
struct HexagramHeader: View {
    let index: Int
    let vi: Bool

    var body: some View {
        if let hex = HexagramService.shared.hexagram(at: index) {
            VStack(spacing: 8) {
                Text(hex.chineseName)
                    .font(DS.Font.chinese(40))
                    .foregroundColor(DS.Color.ink.opacity(0.6))

                HStack(spacing: 10) {
                    SealStampView(text: hex.chineseName, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hex.name)
                            .font(DS.Font.serif(15, weight: .semibold))
                            .foregroundColor(DS.Color.ink)
                        if let viName = hex.nameVi {
                            Text(viName)
                                .font(DS.Font.serif(12))
                                .foregroundColor(DS.Color.gold.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.top, DS.Spacing.sm)
        }
    }
}