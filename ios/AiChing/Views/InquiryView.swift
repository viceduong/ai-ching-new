import SwiftUI

// MARK: - Step 2: Inquiry
struct InquiryView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @FocusState private var isFocused: Bool

    var vi: Bool { isVietnamese }
    private let maxChars = 200

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 2, label: t(L.Step.inquiry, vi))
                .padding(.top, 60)

            VStack(spacing: DS.Spacing.sm) {
                Text(t(L.Inquiry.instruction, vi))
                    .font(DS.Font.serif(14))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.top, DS.Spacing.sm)
            }

            Spacer()

            // Scroll-like parchment text area
            VStack(spacing: DS.Spacing.sm) {
                // Decorative scroll top
                HStack(spacing: 6) {
                    Rectangle().fill(DS.Color.gold.opacity(0.4)).frame(height: 1)
                    TrigramView(lines: [true, true, true], width: 18, isHighlighted: true)
                    Rectangle().fill(DS.Color.gold.opacity(0.4)).frame(height: 1)
                }

                // Text input area with calligraphy styling
                ZStack(alignment: .topLeading) {
                    if viewModel.questionText.isEmpty {
                        Text(t(L.Inquiry.placeholder, vi))
                            .font(DS.Font.serif(15, weight: .light))
                            .foregroundColor(DS.Color.inkFaded.opacity(0.5))
                            .italic()
                            .padding(.top, 12)
                            .padding(.leading, 8)
                    }

                    TextEditor(text: $viewModel.questionText)
                        .font(DS.Font.serif(18, weight: .light))
                        .foregroundColor(DS.Color.ink)
                        .hideScrollBackground()
                        .frame(minHeight: 120, maxHeight: 180)
                        .padding(8)
                        .focused($isFocused)
                        .onChange(of: viewModel.questionText) { newValue in
                            if newValue.count > maxChars {
                                viewModel.questionText = String(newValue.prefix(maxChars))
                            }
                            viewModel.registerKeystroke(character: String(newValue.last ?? " "))
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DS.Color.gold.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                )

                // Decorative scroll bottom
                HStack(spacing: 6) {
                    Rectangle().fill(DS.Color.gold.opacity(0.4)).frame(height: 1)
                    SealStampView(text: "問", size: 18)
                    Rectangle().fill(DS.Color.gold.opacity(0.4)).frame(height: 1)
                }

                HStack {
                    Text("\(viewModel.questionText.count)/\(maxChars)")
                        .font(DS.Font.mono(11))
                        .foregroundColor(viewModel.questionText.count < 5
                            ? DS.Color.crimson.opacity(0.6)
                            : DS.Color.jade)
                    Spacer()
                    if viewModel.questionText.count < 5 {
                        Text(t(L.Inquiry.minChars, vi))
                            .font(DS.Font.serif(10))
                            .foregroundColor(DS.Color.crimson.opacity(0.6))
                    } else {
                        Text("✓ \(vi ? "Sẵn sàng" : "Ready")")
                            .font(DS.Font.serif(10))
                            .foregroundColor(DS.Color.jade)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            // Continue button
            PrimaryButton(
                title: t(L.Inquiry.next, vi),
                subtitle: nil
            ) {
                isFocused = false
                withAnimation(DS.Anim.default) { viewModel.submitQuestion() }
            }
            .disabled(viewModel.questionText.count < 5)
            .opacity(viewModel.questionText.count >= 5 ? 1 : 0.5)

            Spacer().frame(height: 40)
        }
        .background(RitualBackground())
        .onTapGesture { isFocused = false }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true }}
    }
}