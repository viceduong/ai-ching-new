import SwiftUI

// MARK: - Step 5: Intuition Override
struct OverrideView: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var isVietnamese = false
    private let labels = [
        Localized("1st (Bottom)", "Sơ (Hào 1)"),
        Localized("2nd", "Nhị (Hào 2)"),
        Localized("3rd", "Tam (Hào 3)"),
        Localized("4th", "Tứ (Hào 4)"),
        Localized("5th", "Ngũ (Hào 5)"),
        Localized("6th (Top)", "Thượng (Hào 6)")
    ]
    var vi: Bool { isVietnamese }

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 5, label: t(L.Step.override, vi))
                .padding(.top, DS.Spacing.md)

            VStack(spacing: DS.Spacing.sm) {
                Text(t(L.Override.instruction, vi))
                    .font(DS.Font.serif(14))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                LanguageToggle(isVietnamese: $isVietnamese)
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.sm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DS.Spacing.sm) {
                    if let result = viewModel.computedResult {
                        HexagramNameView(index: result.primaryIndex, vi: vi)

                        VStack(spacing: 6) {
                            ForEach((0..<6).reversed(), id: \.self) { i in
                                let idx = 5 - i
                                let val = viewModel.overriddenLines[safe: idx] ?? .youngYin
                                OverrideLineRow(
                                    label: labels[safe: idx]?.text(vi) ?? "Line \(idx+1)",
                                    value: val,
                                    onTap: { viewModel.toggleLine(at: idx) }
                                )
                            }
                        }
                        .padding(DS.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                .fill(DS.Color.surface)
                                .cardShadow()
                        )
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)

                if let result = viewModel.computedResult, result.hasMovingLines {
                    VStack(spacing: 4) {
                        Text(t(L.Override.forming, vi))
                            .font(DS.Font.serif(12))
                            .foregroundColor(DS.Color.inkFaded)
                        if let secondaryIdx = result.secondaryIndex {
                            Text(HexagramService.shared.name(for: secondaryIdx))
                                .font(DS.Font.serif(17, weight: .semibold))
                                .foregroundColor(DS.Color.gold)
                        }
                    }
                    .padding(.vertical, DS.Spacing.sm)
                }
            }

            PrimaryButton(
                title: t(L.Override.accept, vi),
                subtitle: nil
            ) {
                withAnimation(DS.Anim.default) { viewModel.acceptOracle() }
            }
            .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
    }
}

struct HexagramNameView: View {
    let index: Int
    let vi: Bool
    var body: some View {
        if let hex = HexagramService.shared.hexagram(at: index) {
            Text(hex.chineseName)
                .font(DS.Font.chinese(36))
                .foregroundColor(DS.Color.ink.opacity(0.4))
            Text(vi ? (hex.nameVi ?? hex.name) : hex.name)
                .font(DS.Font.serif(18, weight: .semibold))
                .foregroundColor(DS.Color.ink.opacity(0.8))
        }
    }
}

struct OverrideLineRow: View {
    let label: String
    let value: LineValue
    let onTap: () -> Void

    var isMoving: Bool { value.isMoving }
    var isYang: Bool { value == .youngYang || value == .oldYang }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                    .font(DS.Font.serif(13))
                    .foregroundColor(DS.Color.inkFaded)
                    .frame(width: 90, alignment: .leading)

                Spacer()

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(isMoving ? DS.Color.gold : DS.Color.ink)
                        .opacity(isMoving ? 0.9 : 0.5)
                        .frame(width: isYang ? 60 : 28, height: 5)
                    if !isYang {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isMoving ? DS.Color.gold : DS.Color.ink)
                            .opacity(isMoving ? 0.9 : 0.5)
                            .frame(width: 28, height: 5)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(value.chineseChar)
                        .font(DS.Font.serif(11))
                        .foregroundColor(isMoving ? DS.Color.gold : DS.Color.inkFaded)
                    Text("\(value.rawValue)")
                        .font(DS.Font.mono(10))
                        .foregroundColor(isMoving ? DS.Color.gold : DS.Color.inkFaded.opacity(0.5))
                }

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundColor(isMoving ? DS.Color.gold : DS.Color.inkFaded.opacity(0.3))
                    .rotationEffect(.degrees(isMoving ? 180 : 0))
            }
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.sm)
            .background(isMoving ? DS.Color.gold.opacity(0.06) : Color.clear)
            .cornerRadius(DS.Radius.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
