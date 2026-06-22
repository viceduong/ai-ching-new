import SwiftUI

// MARK: - AiChing App Entry Point
/// The Book of Changes — a sacred divination ritual app.
/// Fully offline, privacy-first, iOS 15+ compatible.
@main
struct AiChingApp: App {
    @StateObject private var viewModel = RitualViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(nil) // Follow system
                .onAppear {
                    viewModel.checkMotionAuthorization()
                }
        }
    }
}

// MARK: - Content View: Ritual Flow Router
/// Routes between ritual steps based on ViewModel state.
struct ContentView: View {
    @ObservedObject var viewModel: RitualViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background
            RitualBackgroundView()

            // Step router
            Group {
                switch viewModel.currentStep {
                case .idle:
                    IdleView(viewModel: viewModel)
                        .transition(.opacity)

                case .stillness:
                    StillnessView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))

                case .inquiry:
                    InquiryView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))

                case .splits:
                    SplitsView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))

                case .computation:
                    ComputationView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))

                case .override:
                    OverrideView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))

                case .oracle:
                    OracleView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: viewModel.currentStep)

            // Reset button (visible for Steps 1–5)
            if viewModel.currentStep != .idle && viewModel.currentStep != .oracle {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.resetRitual()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.inkBlack.opacity(0.25))
                                .padding(16)
                        }
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(colorScheme)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: RitualViewModel.preview)
    }
}
