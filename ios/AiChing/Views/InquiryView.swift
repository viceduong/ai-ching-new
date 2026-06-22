import SwiftUI

// MARK: - Step 2: Inquiry
struct InquiryView: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var isVietnamese = false
    @FocusState private var isFocused: Bool

    var vi: Bool { isVietnamese }
    private let maxChars = 200

    var body: some View {
        VStack(spacing: 0) {
            StepBadge(number: 2, label: L.Step.inquiry.text(vi))
                .padding(.top, DS.Spacing.md)

            VStack(spacing: DS.Spacing.sm) {
                Text(L.Inquiry.instruction.text(vi))
                    .font(DS.Font.serif(15))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                LanguageToggle(isVietnamese: $isVietnamese)
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.md)

            Spacer()

            // Examples
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text(L.Inquiry.examples.text(vi))
                    .font(DS.Font.serif(12, weight: .semibold))
                    .foregroundColor(DS.Color.inkFaded)

                ForEach([L.Inquiry.ex1, L.Inquiry.ex2, L.Inquiry.ex3], id: \.en) { ex in
                    Button(action: {
                        viewModel.questionText = ex.text(vi)
                        viewModel.registerKeystroke(character: String(ex.text(vi).last ?? " "))
                    }) {
                        Text(ex.text(vi))
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
                        Text(L.Inquiry.minChars.text(vi))
                            .font(DS.Font.serif(11))
                            .foregroundColor(DS.Color.crimson.opacity(0.6))
                    }
                }
                .padding(.horizontal, DS.Spacing.xs)
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            PrimaryButton(
                title: L.Inquiry.next.text(vi),
                subtitle: viewModel.questionText.count >= 5 ? nil : L.Inquiry.minChars.text(vi)
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
