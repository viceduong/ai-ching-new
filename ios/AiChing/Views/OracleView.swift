import SwiftUI

// MARK: - Oracle View — Complete Rewrite with Bilingual Analysis
struct OracleView: View {
    @ObservedObject var viewModel: RitualViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isVietnamese = false
    @State private var showSaveConfirmation = false
    @State private var showShareSheet = false
    @State private var animateContent = false
    @Environment(\.localePreference) var localePref

    var vi: Bool { isVietnamese }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(t(L.Oracle.title, vi))
                        .font(DS.Font.serif(24, weight: .light))
                        .foregroundColor(DS.Color.ink.opacity(0.7))
                    Text(t(L.Step.oracleSub, vi))
                        .font(DS.Font.serif(13))
                        .foregroundColor(DS.Color.inkFaded)
                        .italic()
                }
                .padding(.top, DS.Spacing.lg)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)

                // Language toggle
                LanguageToggle(isVietnamese: $isVietnamese)
                    .padding(.top, DS.Spacing.sm)
                    .opacity(animateContent ? 1 : 0)

                if let data = viewModel.oracleData {
                    // Question card
                    Card {
                        VStack(spacing: 8) {
                            Text(t(L.Oracle.yourQuestion, vi))
                                .font(DS.Font.serif(12))
                                .foregroundColor(DS.Color.inkFaded)
                            Text("\"\(viewModel.questionText)\"")
                                .font(DS.Font.serif(17))
                                .italic()
                                .foregroundColor(DS.Color.ink)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.md)
                    .opacity(animateContent ? 1 : 0)

                    // Primary Hexagram
                    InkDivider()
                        .padding(.vertical, DS.Spacing.lg)
                        .opacity(animateContent ? 1 : 0)

                    hexagramAnalysis(data: data, isSecondary: false)

                    // Secondary hexagram
                    if let secondaryIdx = data.secondaryIndex {
                        InkDivider()
                            .padding(.vertical, DS.Spacing.lg)

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.triangle.swap")
                                    .font(.caption)
                                    .foregroundColor(DS.Color.gold)
                                Text(t(L.Oracle.changingTo, vi))
                                    .font(DS.Font.serif(15, weight: .semibold))
                                    .foregroundColor(DS.Color.inkFaded)
                            }
                            .opacity(animateContent ? 1 : 0)

                            hexagramAnalysis(data: data, isSecondary: true)
                        }
                    }

                    // Changing Lines
                    if !data.movingLineTexts.isEmpty {
                        InkDivider()
                            .padding(.vertical, DS.Spacing.lg)

                        VStack(alignment: .leading, spacing: DS.Spacing.md) {
                            Text(t(L.Oracle.changingLines, vi))
                                .font(DS.Font.serif(18, weight: .semibold))
                                .foregroundColor(DS.Color.crimson)
                                .padding(.horizontal, DS.Spacing.lg)

                            ForEach(data.movingLineTexts, id: \.position) { lineText in
                                movingLineCard(
                                    position: lineText.position,
                                    text: lineText.text,
                                    value: data.lineValues[safe: lineText.position] ?? .oldYang
                                )
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                    }

                    // Interpretation section
                    if let hex = data.primaryHexagram {
                        InkDivider()
                            .padding(.vertical, DS.Spacing.lg)

                        interpretationSection(hex: hex, data: data)
                            .opacity(animateContent ? 1 : 0)
                    }

                    // Seed hash
                    HStack {
                        Text("\(t(L.Oracle.seed, vi)):")
                            .font(DS.Font.mono(11))
                            .foregroundColor(DS.Color.inkFaded.opacity(0.4))
                        Text(viewModel.hashHex.prefix(16) + "...")
                            .font(DS.Font.mono(11))
                            .foregroundColor(DS.Color.inkFaded.opacity(0.3))
                    }
                    .padding(.top, DS.Spacing.sm)
                }

                // Action buttons
                HStack(spacing: DS.Spacing.xl) {
                    actionButton(
                        icon: showSaveConfirmation ? "checkmark.circle.fill" : "bookmark",
                        label: showSaveConfirmation ? t(L.Oracle.saved, vi) : t(L.Oracle.save, vi),
                        color: showSaveConfirmation ? DS.Color.jade : DS.Color.inkFaded
                    ) {
                        viewModel.saveReading()
                        showSaveConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showSaveConfirmation = false }
                    }

                    actionButton(
                        icon: "square.and.arrow.up",
                        label: t(L.Oracle.share, vi),
                        color: DS.Color.inkFaded
                    ) {
                        shareContent = viewModel.shareText()
                        showShareSheet = true
                    }

                    actionButton(
                        icon: "plus.circle",
                        label: t(L.Oracle.newReading, vi),
                        color: DS.Color.gold
                    ) {
                        withAnimation(DS.Anim.default) { viewModel.resetRitual() }
                    }
                }
                .padding(.vertical, DS.Spacing.xl)

                // Footer
                Text(t(L.App.footer, vi))
                    .font(DS.Font.serif(11))
                    .foregroundColor(DS.Color.inkFaded.opacity(0.3))
                    .padding(.bottom, DS.Spacing.xl)
            }
        }
        .background(RitualBackground())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) { animateContent = true }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareContent])
        }
    }

    // MARK: - Hexagram Analysis Block
    func hexagramAnalysis(data: OracleDisplayData, isSecondary: Bool) -> AnyView {
        let hex = isSecondary ? data.secondaryHexagram : data.primaryHexagram
        guard let h = hex else { return AnyView(EmptyView()) }

        return AnyView(VStack(spacing: DS.Spacing.md) {
                // Chinese name
                Text(h.chineseName)
                    .font(DS.Font.chinese(52))
                    .foregroundColor(isSecondary ? DS.Color.gold : DS.Color.ink)
                    .opacity(0.6)

                // Name (bilingual)
                VStack(spacing: 2) {
                    Text(h.name)
                        .font(DS.Font.serif(20, weight: .semibold))
                        .foregroundColor(DS.Color.ink)
                    if let viName = h.nameVi {
                        Text(viName)
                            .font(DS.Font.serif(15))
                            .foregroundColor(DS.Color.gold)
                            .opacity(isVietnamese ? 1 : 0.4)
                    }
                }

                // Hexagram number
                Text("Hexagram \(h.id + 1)")
                    .font(DS.Font.mono(12))
                    .foregroundColor(DS.Color.inkFaded.opacity(0.4))

                // Lines (top to bottom)
                VStack(spacing: 8) {
                    ForEach((0..<6).reversed(), id: \.self) { i in
                        let idx = 5 - i
                        let val = isSecondary ? nil : data.lineValues[safe: idx]
                        let isYang: Bool
                        let isMoving: Bool
                        if let v = val {
                            isYang = v == .youngYang || v == .oldYang
                            isMoving = v == .oldYin || v == .oldYang
                        } else {
                            isYang = h.lines[idx] == .yang
                            isMoving = false
                        }
                        HexagramLineView(
                            isYang: isYang,
                            isMoving: isMoving,
                            color: isMoving ? DS.Color.gold : (isSecondary ? DS.Color.gold.opacity(0.6) : DS.Color.ink),
                            animated: !isSecondary,
                            width: 100
                        )
                    }
                }
                .padding(DS.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                        .fill(DS.Color.surface)
                        .cardShadow()
                )
                .padding(.horizontal, DS.Spacing.lg)

                // Judgment
                VStack(spacing: 8) {
                    Text(t(L.Oracle.judgment, vi))
                        .font(DS.Font.serif(13, weight: .semibold))
                        .foregroundColor(DS.Color.inkFaded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Spacing.lg)

                    let judgmentText = vi && h.judgmentVi != nil ? h.judgmentVi! : h.judgment
                    Text(judgmentText)
                        .font(DS.Font.serif(16))
                        .foregroundColor(DS.Color.ink)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.lg)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Image
                VStack(spacing: 8) {
                    Text(t(L.Oracle.image, vi))
                        .font(DS.Font.serif(13, weight: .semibold))
                        .foregroundColor(DS.Color.inkFaded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Spacing.lg)

                    let imageText = vi && h.imageVi != nil ? h.imageVi! : h.image
                    Text(imageText)
                        .font(DS.Font.serif(14))
                        .foregroundColor(DS.Color.inkFaded)
                        .italic()
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.lg)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        )
    }

    // MARK: - Moving Line Card
    func movingLineCard(position: Int, text: String, value: LineValue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(DS.Color.crimson).frame(width: 6, height: 6)
                Text("\(t(L.Oracle.changingLines, vi)) \(position + 1)")
                    .font(DS.Font.serif(14, weight: .semibold))
                    .foregroundColor(DS.Color.crimson)
                Spacer()
                Text(value.chineseChar)
                    .font(DS.Font.serif(12))
                    .foregroundColor(DS.Color.gold)
            }
            Text(text)
                .font(DS.Font.serif(15))
                .foregroundColor(DS.Color.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text(analysis)
                .font(DS.Font.serif(13))
                .foregroundColor(DS.Color.jade)
                .italic()
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(DS.Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                        .stroke(DS.Color.crimson.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, DS.Spacing.lg)
    }

    // MARK: - Interpretation Section
    func interpretationSection(hex: Hexagram, data: OracleDisplayData) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(t(L.Oracle.interpretation, vi))
                .font(DS.Font.serif(18, weight: .semibold))
                .foregroundColor(DS.Color.ink)
                .padding(.horizontal, DS.Spacing.lg)

            let interpretation = vi ? vietnameseInterpretation(hex: hex, data: data) : englishInterpretation(hex: hex, data: data)
            Text(interpretation)
                .font(DS.Font.serif(15))
                .foregroundColor(DS.Color.ink.opacity(0.8))
                .lineSpacing(6)
                .padding(.horizontal, DS.Spacing.lg)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Line Analysis
    func lineAnalysisEn(position: Int, value: LineValue) -> String {
        let lineNum = position + 1
        if value == .oldYin || value == .oldYang {
            return "This is a moving line — it will transform into its opposite in the secondary hexagram. The energy here is at a tipping point."
        }
        return "This line is stable. Its energy is settled and reliable."
    }

    func lineAnalysisVi(position: Int, value: LineValue) -> String {
        let lineNum = position + 1
        if value == .oldYin || value == .oldYang {
            return "Hào này là hào động — nó sẽ biến đổi thành hào đối lập trong quẻ biến. Năng lượng ở đây đang ở điểm chuyển giao."
        }
        return "Hào này ổn định. Năng lượng của nó đã lắng đọng và đáng tin cậy."
    }

    // MARK: - Interpretation
    func englishInterpretation(hex: Hexagram, data: OracleDisplayData) -> String {
        var text = "This hexagram reveals the energy of your present situation. "
        text += "The Judgment speaks directly to your question — read it as a mirror of your current state. "

        if hex.id == 63 || hex.id == 46 {
            text += "This hexagram carries special weight: "
            text += hex.id == 63
                ? "it represents completion, but warns that the end of one cycle is the beginning of another."
                : "it represents the liminal space before completion — everything is in motion, not yet resolved."
        }

        if !data.movingLineTexts.isEmpty {
            text += "\n\nThe moving lines indicate areas of transformation. "
            text += "They point to where change is actively working in your life. "
            text += data.movingLineTexts.count == 1
                ? "One line moves — a focused shift in one area."
                : data.movingLineTexts.count == 6
                ? "All lines move — a complete transformation is underway."
                : "\(data.movingLineTexts.count) lines move — significant change in multiple areas."
        }

        if let secondaryIdx = data.secondaryIndex {
            let secondaryHex = HexagramService.shared.hexagram(at: secondaryIdx)
            text += "\n\nThe secondary hexagram — \(secondaryHex?.name ?? "transformed state") — shows the outcome toward which the current energy is evolving."
        }

        text += "\n\nRead the Image text as guidance for how to embody the wisdom of this hexagram in your daily life."
        return text
    }

    func vietnameseInterpretation(hex: Hexagram, data: OracleDisplayData) -> String {
        var text = "Quẻ này tiết lộ năng lượng của tình huống hiện tại của bạn. "
        text += "Thoán từ nói trực tiếp với câu hỏi của bạn — hãy đọc nó như tấm gương phản chiếu trạng thái hiện tại. "

        if hex.id == 63 || hex.id == 46 {
            text += "Quẻ này mang ý nghĩa đặc biệt: "
            text += hex.id == 63
                ? "nó đại diện cho sự hoàn thành, nhưng cảnh báo rằng kết thúc của một chu kỳ là khởi đầu của chu kỳ khác."
                : "nó đại diện cho không gian giữa trước khi hoàn thành — mọi thứ đang chuyển động, chưa kết thúc."
        }

        if !data.movingLineTexts.isEmpty {
            text += "\n\nCác hào động chỉ ra những lĩnh vực chuyển hóa. "
            text += "Chúng chỉ ra nơi thay đổi đang tích cực diễn ra trong cuộc sống bạn."
        }

        if let secondaryIdx = data.secondaryIndex {
            let secondaryHex = HexagramService.shared.hexagram(at: secondaryIdx)
            text += "\n\nQuẻ biến — \(secondaryHex?.nameVi ?? "trạng thái chuyển hóa") — cho thấy kết quả mà năng lượng hiện tại đang hướng tới."
        }

        text += "\n\nHãy đọc Tượng truyện như lời chỉ dẫn cho cách thể hiện sự minh triết của quẻ này trong cuộc sống hàng ngày."
        return text
    }

    @State private var shareContent = ""
}

// MARK: - Action Button Helper
@ViewBuilder
func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(label)
                .font(DS.Font.serif(12))
        }
        .foregroundColor(color)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
