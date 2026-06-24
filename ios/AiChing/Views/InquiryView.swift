import SwiftUI

// MARK: - Step 2: Inquiry — Parchment
struct InquiryView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @FocusState private var isFocused: Bool

    var vi: Bool { isVietnamese }
    private let maxChars = 200

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Top decorative
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Rectangle().fill(DS.Color.gold.opacity(0.4)).frame(height: 0.5)
                    SealStampView(text: "問", size: 24)
                    Rectangle().fill(DS.Color.gold.opacity(0.4)).frame(height: 0.5)
                }
                .padding(.horizontal, DS.Spacing.xl)

                Text(t(L.Inquiry.instruction, vi))
                    .font(DS.Font.serif(15, weight: .light))
                    .foregroundColor(DS.Color.inkFaded)
                    .italic()
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.top, 6)
            }

            Spacer()

            // Parchment text input - centered
            VStack(spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if viewModel.questionText.isEmpty {
                        Text(t(L.Inquiry.placeholder, vi))
                            .font(DS.Font.serif(17, weight: .light))
                            .foregroundColor(DS.Color.inkFaded.opacity(0.4))
                            .italic()
                            .padding(.top, 16)
                            .padding(.leading, 16)
                    }

                    TextEditor(text: $viewModel.questionText)
                        .font(DS.Font.serif(20, weight: .light))
                        .foregroundColor(DS.Color.ink)
                        .hideScrollBackground()
                        .frame(minHeight: 140, maxHeight: 200)
                        .padding(12)
                        .focused($isFocused)
                        .onChange(of: viewModel.questionText) { newValue in
                            if newValue.count > maxChars {
                                viewModel.questionText = String(newValue.prefix(maxChars))
                            }
                            viewModel.registerKeystroke(character: String(newValue.last ?? " "))
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DS.Color.surface)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(DS.Color.gold.opacity(0.2), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, DS.Spacing.xl)

                // Character counter
                HStack {
                    Spacer()
                    Text("\(viewModel.questionText.count)/\(maxChars)")
                        .font(DS.Font.mono(11))
                        .foregroundColor(viewModel.questionText.count < 5 ? DS.Color.crimson.opacity(0.5) : DS.Color.jade)
                        .padding(.horizontal, DS.Spacing.xl)
                }
            }

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

            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RitualBackground())
        .onTapGesture { isFocused = false }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true }
        }
    }
}