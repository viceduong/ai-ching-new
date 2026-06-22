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
                .padding(.top, DS.Spacing.md)

            VStack(spacing: DS.Spacing.sm) {
                Text(t(L.Inquiry.instruction, vi))
                    .font(DS.Font.serif(15))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                LanguageToggle()
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.md)

            Spacer()

            // Examples
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text(t(L.Inquiry.examples, vi))
                    .font(DS.Font.serif(12, weight: .semibold))
                    .foregroundColor(DS.Color.inkFaded)

                let examples = [L.Inquiry.ex1, L.Inquiry.ex2, L.Inquiry.ex3]
                ForEach(0..<3, id: \.self) { idx in
                    Button(action: {
                        let q = examples[idx]
                        viewModel.questionText = t(q, vi)
                        viewModel.registerKeystroke(character: String(t(q, vi).last ?? " "))
                    }) {
                        Text(t(examples[idx], vi))
                            .font(DS.Font.serif(13))
                            .foregroundColor(DS.Color.gold)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            // Text input
            VStack(spacing: DS.Spacing.sm) {
                TextEditor(text: $viewModel.questionText)
                    .font(DS.Font.serif(16))
                    .foregroundColor(DS.Color.ink)
                    .hideScrollBackground()
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(DS.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                            .fill(DS.Color.surface)
                            .cardShadow()
                    )
                    .focused($isFocused)
                    .onChange(of: viewModel.questionText) { newValue in
                        if newValue.count > maxChars {
                            viewModel.questionText = String(newValue.prefix(maxChars))
                        }
                        viewModel.registerKeystroke(character: String(newValue.last ?? " "))
                    }

                HStack {
                    Text("\(viewModel.questionText.count)/\(maxChars)")
                        .font(DS.Font.mono(12))
                        .foregroundColor(viewModel.questionText.count < 5 ? DS.Color.crimson.opacity(0.6) : DS.Color.jade)
                    Spacer()
                    if viewModel.questionText.count < 5 {
                        Text(t(L.Inquiry.minChars, vi))
                            .font(DS.Font.serif(11))
                            .foregroundColor(DS.Color.crimson.opacity(0.6))
                    }
                }
                .padding(.horizontal, DS.Spacing.xs)
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            PrimaryButton(
                title: t(L.Inquiry.next, vi),
                subtitle: viewModel.questionText.count >= 5 ? nil : t(L.Inquiry.minChars, vi)
            ) {
                isFocused = false
                withAnimation(DS.Anim.default) { viewModel.submitQuestion() }
            }
            .disabled(viewModel.questionText.count < 5)
            .opacity(viewModel.questionText.count >= 5 ? 1 : 0.4)

            Spacer()
        }
        .background(RitualBackground())
        .onTapGesture { isFocused = false }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true }}
    }
}
