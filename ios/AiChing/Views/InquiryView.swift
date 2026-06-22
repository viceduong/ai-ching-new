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
                .padding(.bottom, DS.Spacing.sm)

            VStack(spacing: DS.Spacing.sm) {
                Text(t(L.Inquiry.instruction, vi))
                    .font(DS.Font.serif(15))
                    .foregroundColor(DS.Color.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.bottom, DS.Spacing.sm)

            // Examples
            VStack(alignment: .leading, spacing: 10) {
                Text(t(L.Inquiry.examples, vi))
                    .font(DS.Font.serif(12, weight: .semibold))
                    .foregroundColor(DS.Color.inkFaded)
                    .padding(.horizontal, DS.Spacing.xl)

                // Ex1
                HStack(spacing: 8) {
                    Image(systemName: "text.quote").font(.system(size: 10)).foregroundColor(DS.Color.gold)
                    Text("What guidance do I need right now?").font(DS.Font.serif(13)).foregroundColor(DS.Color.ink).lineLimit(2).multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: DS.Radius.sm).fill(DS.Color.surface).overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(DS.Color.gold.opacity(0.2), lineWidth: 0.5)))
                .padding(.horizontal, DS.Spacing.xl)
                .onTapGesture { viewModel.questionText = "What guidance do I need right now?" }

                // Ex2
                HStack(spacing: 8) {
                    Image(systemName: "text.quote").font(.system(size: 10)).foregroundColor(DS.Color.gold)
                    Text("How can I find clarity in my work?").font(DS.Font.serif(13)).foregroundColor(DS.Color.ink).lineLimit(2).multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: DS.Radius.sm).fill(DS.Color.surface).overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(DS.Color.gold.opacity(0.2), lineWidth: 0.5)))
                .padding(.horizontal, DS.Spacing.xl)
                .onTapGesture { viewModel.questionText = "How can I find clarity in my work?" }

                // Ex3
                HStack(spacing: 8) {
                    Image(systemName: "text.quote").font(.system(size: 10)).foregroundColor(DS.Color.gold)
                    Text("What energy surrounds my relationship?").font(DS.Font.serif(13)).foregroundColor(DS.Color.ink).lineLimit(2).multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: DS.Radius.sm).fill(DS.Color.surface).overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(DS.Color.gold.opacity(0.2), lineWidth: 0.5)))
                .padding(.horizontal, DS.Spacing.xl)
                .onTapGesture { viewModel.questionText = "What energy surrounds my relationship?" }
            }

            // Text input
            VStack(spacing: DS.Spacing.sm) {
                TextEditor(text: $viewModel.questionText)
                    .font(DS.Font.serif(16))
                    .foregroundColor(DS.Color.ink)
                    .hideScrollBackground()
                    .frame(minHeight: 80, maxHeight: 130)
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
                .padding(.horizontal, 4)
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
            .opacity(viewModel.questionText.count >= 5 ? 1 : 0.5)
            .padding(.bottom, DS.Spacing.md)
        }
        .background(RitualBackground())
        .onTapGesture { isFocused = false }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { isFocused = true }}
    }
}
