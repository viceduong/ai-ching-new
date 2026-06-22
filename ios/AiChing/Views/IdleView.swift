import SwiftUI

// MARK: - Idle / Welcome Screen
struct IdleView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var rotation: Double = 0
    @State private var outerRotation: Double = 0

    var vi: Bool { isVietnamese }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            // Chinese title
            Text("易 經")
                .font(DS.Font.chinese(56))
                .foregroundColor(DS.Color.ink.opacity(0.6))
                .tracking(8)

            Text("AiChing")
                .font(DS.Font.serif(28, weight: .light))
                .foregroundColor(DS.Color.ink.opacity(0.7))
                .padding(.top, 2)

            Text(vi ? "Kinh Dịch — Sách của những biến đổi" : "The Book of Changes")
                .font(DS.Font.serif(13, weight: .light))
                .foregroundColor(DS.Color.inkFaded)
                .italic()
                .padding(.top, 2)

            Spacer()

            // Centerpiece: Yin-Yang with rotating Bagua
            ZStack {
                // Bagua compass (outer, rotating)
                BaguaCompass(size: 260)
                    .rotationEffect(.degrees(outerRotation))
                    .opacity(0.4)

                // Outer ring
                Circle()
                    .stroke(DS.Color.gold.opacity(0.25), lineWidth: 1)
                    .frame(width: 200, height: 200)

                // Inner ring
                Circle()
                    .stroke(DS.Color.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 160, height: 160)

                // Yin-Yang (rotating)
                YinYangView(size: 100)
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: DS.Color.ink.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .frame(width: 280, height: 280)

            Spacer()

            // Begin button
            PrimaryButton(
                title: t(L.Idle.begin, vi),
                subtitle: vi ? "Bắt đầu hành trình" : "Begin your journey"
            ) {
                withAnimation(.easeInOut(duration: 0.4)) { viewModel.beginRitual() }
            }

            Spacer().frame(height: 20)

            // History link
            HistoryLink(viewModel: viewModel)
                .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - History Link
struct HistoryLink: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var showHistory = false
    @AppStorage("lang_vi") var isVietnamese = false

    var vi: Bool { isVietnamese }

    var body: some View {
        Button(action: { showHistory = true }) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed")
                    .font(.caption)
                Text(vi ? "Lịch sử quẻ" : "Reading History")
                    .font(DS.Font.serif(13))
            }
            .foregroundColor(DS.Color.gold.opacity(0.7))
        }
        .sheet(isPresented: $showHistory) {
            JournalView(viewModel: viewModel)
        }
    }
}

// MARK: - Preview
struct IdleView_Previews: PreviewProvider {
    static var previews: some View {
        IdleView(viewModel: RitualViewModel.preview)
    }
}