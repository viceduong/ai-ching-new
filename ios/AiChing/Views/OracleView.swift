import SwiftUI

// MARK: - Step 6: The Oracle (Revelation)
/// Displays the complete reading: primary hexagram, secondary, moving line texts.
/// Scrollable book-like layout with save and share actions.
struct OracleView: View {
    @ObservedObject var viewModel: RitualViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showSaveConfirmation = false
    @State private var showShareSheet = false
    @State private var shareContent = ""
    @State private var animateContent = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Step indicator (complete)
                StepProgressView(currentStep: .oracle)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                // Title
                Text("启 示")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.light)
                    .foregroundColor(.inkBlack)
                    .opacity(0.7)

                Text("The Oracle")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.4))
                    .italic()

                if let data = viewModel.oracleData {
                    // Question
                    VStack(spacing: 4) {
                        Text("Your Question")
                            .font(.system(.caption, design: .serif))
                            .foregroundColor(.inkBlack.opacity(0.4))

                        Text("\"\(viewModel.questionText)\"")
                            .font(.system(.body, design: .serif))
                            .italic()
                            .foregroundColor(.inkBlack.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 10)

                    // Divider
                    RitualDivider()
                        .padding(.vertical, 16)
                        .opacity(animateContent ? 1 : 0)

                    // Primary Hexagram
                    HexagramDisplayView(
                        hexagram: data.primaryHexagram,
                        index: data.primaryIndex,
                        isSecondary: false,
                        lineValues: data.lineValues,
                        movingPositions: data.movingLinePositions
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 15)

                    // Secondary Hexagram (if exists)
                    if let secondaryHex = data.secondaryHexagram,
                       let secondaryIdx = data.secondaryIndex {
                        RitualDivider()
                            .padding(.vertical, 16)

                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.triangle.swap")
                                    .font(.caption)
                                    .foregroundColor(.gold)
                                Text("Changing to")
                                    .font(.system(.caption, design: .serif))
                                    .foregroundColor(.inkBlack.opacity(0.5))
                            }

                            HexagramDisplayView(
                                hexagram: secondaryHex,
                                index: secondaryIdx,
                                isSecondary: true,
                                lineValues: nil,
                                movingPositions: []
                            )
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                    }

                    // Moving Line Texts
                    if !data.movingLineTexts.isEmpty {
                        RitualDivider()
                            .padding(.vertical, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Changing Lines")
                                .font(.system(.headline, design: .serif))
                                .foregroundColor(.movingGold)
                                .padding(.horizontal, 24)

                            ForEach(data.movingLineTexts, id: \.position) { lineText in
                                MovingLineCard(
                                    position: lineText.position,
                                    text: lineText.text,
                                    lineValue: data.lineValues[safe: lineText.position] ?? .oldYang
                                )
                            }
                        }
                        .padding(.bottom, 8)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                    }

                    // Hash seed
                    HStack {
                        Text("Seed:")
                            .font(.system(.caption2, design: .serif))
                            .foregroundColor(.inkBlack.opacity(0.3))

                        Text(viewModel.hashHex.prefix(16) + "...")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.inkBlack.opacity(0.25))
                    }
                    .padding(.top, 8)
                    .opacity(animateContent ? 1 : 0)
                }

                // Action buttons
                HStack(spacing: 20) {
                    // Save button
                    Button(action: {
                        viewModel.saveReading()
                        showSaveConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showSaveConfirmation = false
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: showSaveConfirmation ? "checkmark.circle.fill" : "bookmark")
                                .font(.title3)
                            Text(showSaveConfirmation ? "Saved" : "Save")
                                .font(.system(.caption2, design: .serif))
                        }
                        .foregroundColor(showSaveConfirmation ? .jade : .inkBlack.opacity(0.6))
                    }

                    // Share button
                    Button(action: {
                        shareContent = viewModel.shareText()
                        showShareSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                            Text("Share")
                                .font(.system(.caption2, design: .serif))
                        }
                        .foregroundColor(.inkBlack.opacity(0.6))
                    }

                    // New reading
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            viewModel.resetRitual()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                            Text("New")
                                .font(.system(.caption2, design: .serif))
                        }
                        .foregroundColor(.gold)
                    }
                }
                .padding(.vertical, 24)
                .opacity(animateContent ? 1 : 0)

                // Footer
                Text("古老的智慧 现代的启示")
                    .font(.system(.caption2, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.25))
                    .padding(.bottom, 32)
            }
        }
        .ritualBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareContent])
        }
    }
}

// MARK: - Hexagram Display Card
struct HexagramDisplayView: View {
    let hexagram: Hexagram?
    let index: Int
    let isSecondary: Bool
    let lineValues: [LineValue]?
    let movingPositions: [Int]

    private struct LineInfo {
        let isYang: Bool
        let isMoving: Bool
        let color: Color
    }

    private var lineInfos: [LineInfo] {
        (0..<6).map { i in
            let lineIdx = 5 - i
            var isYang = false
            var isMoving = false

            if let values = lineValues, lineIdx < values.count {
                let val = values[lineIdx]
                isYang = val == .youngYang || val == .oldYang
                isMoving = val == .oldYin || val == .oldYang
            } else if let hex = hexagram {
                let lines = hex.lines
                isYang = lineIdx < lines.count ? lines[lineIdx] == .yang : false
            }

            let color: Color = isMoving ? .movingGold : (isSecondary ? .gold.opacity(0.7) : .inkBlack)
            return LineInfo(isYang: isYang, isMoving: isMoving, color: color)
        }
    }

    var body: some View {
        let infos = lineInfos
        return VStack(spacing: 0) {
            // Hexagram number and name
            if let hex = hexagram {
                Text(hex.chineseName)
                    .font(.system(.title, design: .serif))
                    .fontWeight(.light)
                    .foregroundColor(isSecondary ? .gold : .inkBlack)
                    .opacity(0.7)

                Text(hex.displayName)
                    .font(.system(.title3, design: .serif))
                    .fontWeight(.medium)
                    .foregroundColor(.inkBlack.opacity(0.8))
                    .padding(.bottom, 12)
            }

            // Hexagram lines (vertical stack, top to bottom)
            VStack(spacing: 6) {
                ForEach(infos.indices.reversed(), id: \.self) { idx in
                    let info = infos[idx]
                    HexagramLineView(
                        isYang: info.isYang,
                        isMoving: info.isMoving,
                        color: info.color,
                        animated: !isSecondary,
                        width: 90
                    )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.ricePaper.opacity(0.3))
            )

            // Judgment
            if let hex = hexagram {
                Text(hex.judgment)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .fixedSize(horizontal: false, vertical: true)

                // Image text
                Text(hex.image)
                    .font(.system(.callout, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.5))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Moving Line Card
struct MovingLineCard: View {
    let position: Int
    let text: String
    let lineValue: LineValue

    private let positionNames = ["Bottom", "Second", "Third", "Fourth", "Fifth", "Top"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Line \(position + 1) (\(positionNames[safe: position] ?? ""))")
                    .font(.system(.subheadline, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundColor(.movingGold)

                Spacer()

                Text(lineValue.chineseChar)
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(.movingGold.opacity(0.7))
            }

            Text(text)
                .font(.system(.callout, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.movingGold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.movingGold.opacity(0.15), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - UIKit Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct OracleView_Previews: PreviewProvider {
    static var previews: some View {
        OracleView(viewModel: RitualViewModel.preview)
    }
}
