import SwiftUI

// MARK: - Step 3: The Six Splits (Yarrow Stalk Casting - CEREMONIAL)
struct SplitsView: View {
    @ObservedObject var viewModel: RitualViewModel
    @AppStorage("lang_vi") var isVietnamese = false
    @State private var currentSplitPercent: Double = 0.5
    @State private var showingResult: Bool = false
    @State private var lastResultIndex: Int = -1
    @State private var stampScale: CGFloat = 0.0
    @State private var inkSway: Double = 0

    var vi: Bool { isVietnamese }
    private let totalLines = 6

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            // Step header
            StepBadge(number: 3, label: t(L.Step.splits, vi))

            // Counter
            HStack(spacing: 8) {
                TrigramView(lines: Array(repeating: viewModel.currentSplitIndex >= 0, count: 1), width: 18, isHighlighted: true)
                Text("\(viewModel.currentSplitIndex + 1) / \(totalLines)")
                    .font(DS.Font.serif(20, weight: .semibold))
                    .foregroundColor(DS.Color.ink)
            }
            .padding(.top, DS.Spacing.md)

            // Instruction
            Text(t(L.Splits.instruction, vi))
                .font(DS.Font.serif(14))
                .foregroundColor(DS.Color.inkFaded)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)

            Spacer()

            // CENTRAL CEREMONIAL: Yarrow stalk bundle with tap interaction
            ZStack {
                // Outer decorative ring with breath
                Circle()
                    .stroke(DS.Color.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 280, height: 280)
                    .scaleEffect(1.0 + 0.02 * sin(inkSway))

                // Inner ring
                Circle()
                    .stroke(DS.Color.gold.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .frame(width: 240, height: 240)

                // Yarrow stalk bundle — drawn as vertical lines
                // Group A (left): below threshold, Group B (right): above
                StalkBundleView(
                    splitPercentage: currentSplitPercent,
                    isAnimating: showingResult,
                    lineCount: 50
                )
                .frame(width: 200, height: 200)
                .offset(x: sin(inkSway) * 2) // subtle sway

                // Result trigram (appears after each split)
                if showingResult {
                    let lineIdx = viewModel.currentSplitIndex
                    let lineVal = lineIdx < viewModel.overriddenLines.count
                        ? viewModel.overriddenLines[lineIdx]
                        : .youngYin
                    let isYang = lineVal == .youngYang || lineVal == .oldYang
                    VStack(spacing: 4) {
                        TrigramView(
                            lines: [isYang, isYang, isYang], // placeholder
                            width: 50,
                            isHighlighted: true
                        )
                        Text(lineVal.chineseChar)
                            .font(DS.Font.serif(16, weight: .bold))
                            .foregroundColor(lineVal.isMoving ? DS.Color.crimson : DS.Color.ink)
                    }
                    .offset(y: -110)
                    .transition(.scale.combined(with: .opacity))
                    .scaleEffect(stampScale)
                }

                // Cinnabar seal stamp
                if stampScale > 0.01 {
                    SealStampView(text: "易", size: 36)
                        .offset(x: 100, y: 90)
                        .scaleEffect(stampScale)
                        .rotationEffect(.degrees(-12))
                }
            }
            .frame(height: 300)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Calculate split percentage from X position
                        let progress = max(0, min(1, value.location.x / 200))
                        currentSplitPercent = progress
                    }
                    .onEnded { _ in
                        performSplit()
                    }
            )

            // Position indicator
            HStack(spacing: 4) {
                Text(vi ? "Trái" : "Left")
                    .font(DS.Font.serif(10))
                    .foregroundColor(DS.Color.inkFaded)
                Capsule()
                    .fill(DS.Color.gold.opacity(0.2))
                    .frame(width: 200, height: 3)
                Text(vi ? "Phải" : "Right")
                    .font(DS.Font.serif(10))
                    .foregroundColor(DS.Color.inkFaded)
            }
            .padding(.top, DS.Spacing.md)

            // Progress dots
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < viewModel.currentSplitIndex ? DS.Color.gold
                              : i == viewModel.currentSplitIndex ? DS.Color.crimson
                              : DS.Color.divider)
                        .frame(width: i == viewModel.currentSplitIndex ? 12 : 8, height: i == viewModel.currentSplitIndex ? 12 : 8)
                        .scaleEffect(i == viewModel.currentSplitIndex ? 1.2 : 1.0)
                        .animation(DS.Anim.spring, value: viewModel.currentSplitIndex)
                }
            }
            .padding(.top, DS.Spacing.lg)

            Spacer()

            // Hint
            Text(t(L.Splits.hint, vi))
                .font(DS.Font.serif(12))
                .foregroundColor(DS.Color.inkFaded.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.lg)
        }
        .background(RitualBackground())
        .onAppear {
            // Gentle ink sway animation
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                inkSway = 1
            }
        }
        .onChange(of: viewModel.currentSplitIndex) { _ in
            if viewModel.currentSplitIndex > lastResultIndex {
                lastResultIndex = viewModel.currentSplitIndex
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    stampScale = 1.0
                }
                // Show result trigram
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingResult = true
                }
                // Fade out stamp and hide result after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        stampScale = 0
                    }
                    withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                        showingResult = false
                    }
                }
            }
        }
    }

    private func performSplit() {
        // Commit the current position
        viewModel.updateSplit(percentage: currentSplitPercent, speed: 0, jitter: [], trajectory: [])
        // Complete this line and auto-advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(DS.Anim.spring) {
                viewModel.completeSplit(percentage: currentSplitPercent, speed: 0, jitter: [], trajectory: [])
            }
            // Reset for next
            currentSplitPercent = 0.5
        }
    }
}

// MARK: - Yarrow Stalk Bundle Visualization
struct StalkBundleView: View {
    let splitPercentage: Double  // 0-1, 0 = all left, 1 = all right
    let isAnimating: Bool
    let lineCount: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Bundle background
                RoundedRectangle(cornerRadius: 8)
                    .fill(DS.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DS.Color.gold.opacity(0.15), lineWidth: 0.5)
                    )
                    .frame(width: geo.size.width, height: geo.size.height)

                // Stalks — render as 50 vertical lines
                ForEach(0..<lineCount, id: \.self) { i in
                    let xPos = (CGFloat(i) / CGFloat(lineCount - 1)) * (geo.size.width - 20) + 10
                    let splitIndex = Int(CGFloat(lineCount) * splitPercentage)
                    let isLeft = i < splitIndex
                    let isHighlighted = (isLeft && i == splitIndex - 1) || (!isLeft && i == splitIndex)

                    Capsule()
                        .fill(isLeft ? DS.Color.ink.opacity(0.7) : DS.Color.ink.opacity(0.3))
                        .frame(width: 2.5, height: geo.size.height * 0.7)
                        .offset(x: xPos - geo.size.width / 2, y: 0)
                        .scaleEffect(x: isHighlighted ? 1.5 : 1.0, y: isHighlighted ? 1.05 : 1.0)
                        .animation(.interactiveSpring(), value: splitPercentage)
                }

                // Center line (the "split boundary")
                Rectangle()
                    .fill(DS.Color.gold.opacity(0.4))
                    .frame(width: 1, height: geo.size.height * 0.85)
                    .offset(x: CGFloat(splitPercentage) * (geo.size.width - 20) + 10 - geo.size.width / 2)

                // Subtle bamboo texture lines
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(DS.Color.divider)
                        .frame(width: geo.size.width - 4, height: 0.5)
                        .offset(y: CGFloat(i - 1) * 30)
                }
            }
        }
    }
}