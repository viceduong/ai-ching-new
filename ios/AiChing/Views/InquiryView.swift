import SwiftUI

// MARK: - Step 2: Inquiry (Crystallizing Intent)
/// User types their question (5–200 chars). Keystroke dynamics are collected as entropy.
struct InquiryView: View {
    @ObservedObject var viewModel: RitualViewModel
    @FocusState private var isTextFieldFocused: Bool

    private let minChars = 5
    private let maxChars = 200

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepProgressView(currentStep: .inquiry)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Title
            Text("问 卦")
                .font(.system(.title, design: .serif))
                .fontWeight(.light)
                .foregroundColor(.inkBlack)
                .opacity(0.7)

            Text("Inquiry")
                .font(.system(.subheadline, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.4))
                .italic()

            Spacer()

            // Instruction
            Text("Write your question with sincerity.")
                .font(.system(.body, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.6))
                .padding(.horizontal, 32)

            Spacer()

            // Text input card (paper-textured)
            VStack(alignment: .leading, spacing: 12) {
                // Paper texture background
                ZStack(alignment: .topLeading) {
                    // Paper card
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ricePaper)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 8) {
                        // Vietnamese instruction
                        Text("Viết câu hỏi của bạn")
                            .font(.system(.caption, design: .serif))
                            .foregroundColor(.inkBlack.opacity(0.35))
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // Text editor
                        TextEditor(text: $viewModel.questionText)
                            .font(.system(.body, design: .serif))
                            .foregroundColor(.inkBlack)
                            .hideScrollBackground()
                            .background(Color.clear)
                            .frame(minHeight: 100, maxHeight: 160)
                            .padding(.horizontal, 12)
                            .focused($isTextFieldFocused)
                            .onChange(of: viewModel.questionText) { newValue in
                                // Enforce max length
                                if newValue.count > maxChars {
                                    viewModel.questionText = String(newValue.prefix(maxChars))
                                }
                                viewModel.registerKeystroke(character: String(newValue.last ?? " "))
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isTextFieldFocused = true
                                }
                            }
                    }
                }
                .frame(height: 200)

                // Character count
                HStack {
                    Text("\(viewModel.questionText.count) / \(maxChars)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(viewModel.questionText.count < minChars
                            ? .crimson.opacity(0.6)
                            : .jade.opacity(0.6))

                    Spacer()

                    if viewModel.questionText.count < minChars {
                        Text("最少 \(minChars) 字")
                            .font(.system(.caption2, design: .serif))
                            .foregroundColor(.crimson.opacity(0.5))
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Submit button
            Button(action: {
                isTextFieldFocused = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.submitQuestion()
                }
            }) {
                Text("Next →")
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(viewModel.questionText.count >= minChars ? .ricePaper : .gray)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.questionText.count >= minChars
                                ? Color.inkBlack
                                : Color.gray.opacity(0.3))
                    )
            }
            .disabled(viewModel.questionText.count < minChars)
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 32)

            Spacer()
        }
        .ritualBackground()
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}

// MARK: - Preview
struct InquiryView_Previews: PreviewProvider {
    static var previews: some View {
        InquiryView(viewModel: RitualViewModel.preview)
    }
}

// MARK: - Hide Scroll Background (iOS 15+ compatibility)
extension View {
    /// Hides the scroll content background. Uses native API on iOS 16+
    /// and UITextView appearance workaround on iOS 15.
    func hideScrollBackground() -> some View {
        if #available(iOS 16.0, *) {
            return AnyView(self.scrollContentBackground(.hidden))
        } else {
            UITextView.appearance().backgroundColor = .clear
            return AnyView(self)
        }
    }
}
