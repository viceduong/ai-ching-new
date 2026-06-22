import SwiftUI

// MARK: - Step 0: Idle / Welcome Screen
/// Entry point of the ritual. A calm, meditative landing page.
struct IdleView: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var brushPulse: CGFloat = 1.0
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: 4) {
                Text("易 經")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(.inkBlack)
                    .opacity(0.6)

                Text("AiChing")
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.light)
                    .foregroundColor(.inkBlack)

                Text("The Book of Changes")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.5))
                    .italic()
            }

            Spacer()

            // Central ink-brush circle
            ZStack {
                Circle()
                    .stroke(Color.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(Color.gold.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 130, height: 130)
                    .scaleEffect(brushPulse)

                // Ink brush circle
                Circle()
                    .fill(Color.inkBlack)
                    .frame(width: 100, height: 100)
                    .scaleEffect(brushPulse)
                    .opacity(0.85)

                // Gold inner ring
                Circle()
                    .stroke(Color.gold.opacity(0.5), lineWidth: 1)
                    .frame(width: 70, height: 70)
                    .scaleEffect(1.0 + 0.1 * sin(Date().timeIntervalSince1970 * 1.5))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    brushPulse = 1.03
                }
            }

            Spacer()

            // Begin button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.beginRitual()
                }
            }) {
                Text("Begin Reading")
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(.ricePaper)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.inkBlack)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gold.opacity(0.3), lineWidth: 0.5)
                    )
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // Footer
            VStack(spacing: 4) {
                Text("古老的智慧 现代的启示")
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.4))

                Button(action: { showHistory = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.caption)
                        Text("Reading History")
                            .font(.system(.caption, design: .serif))
                    }
                    .foregroundColor(.gold.opacity(0.7))
                }
                .padding(.top, 8)
            }
        }
        .ritualBackground()
        .sheet(isPresented: $showHistory) {
            JournalView(viewModel: viewModel)
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct IdleView_Previews: PreviewProvider {
    static var previews: some View {
        IdleView(viewModel: RitualViewModel.preview)
    }
}
