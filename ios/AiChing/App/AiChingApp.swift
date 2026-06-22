import SwiftUI

// MARK: - AiChing App Entry Point
/// The Book of Changes - a sacred divination ritual app.
/// Fully offline, privacy-first, iOS 15+ compatible.
@main
struct AiChingApp: App {
    @StateObject private var viewModel = RitualViewModel()
    @AppStorage("themeOverride") private var themeOverride: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(ThemeOverride.effective)
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
    @State private var showSettings = false

    var body: some View {
        ZStack {
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
                        .transition(.opacity)
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

            // Settings button (top-right, hidden during oracle)
            if viewModel.currentStep != .oracle {
                VStack {
                    HStack {
                        Spacer()
                        SettingsButton(showDrawer: $showSettings)
                    }
                    Spacer()
                }
            }

            // Settings drawer overlay
            SettingsDrawer(isOpen: $showSettings)
        }
        .ignoresSafeArea()
        .background(RitualBackground())
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: RitualViewModel.preview)
    }
}
