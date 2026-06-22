import SwiftUI

// MARK: - Step 3: Six Splits
struct SplitsView: View {
    @ObservedObject var viewModel: RitualViewModel
    @State private var isVietnamese = false
    @State private var dragOffset: CGFloat = 0
    @State private var dragTrajectory: [CGPoint] = []
    @State private var lastDragPosition: CGPoint?
    @State private var dragStartTime: Date?
    @State private var totalDragDistance: CGFloat = 0

    private let stalkCount = 50
    private let handleWidth: CGFloat = 44
    var vi: Bool { isVietnamese }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                StepBadge(number: 3, label: t(L.Step.splits, vi))
                    .padding(.top, DS.Spacing.md)

                VStack(spacing: DS.Spacing.sm) {
                    Text(t(L.Splits.instruction, vi))
                        .font(DS.Font.serif(15))
                        .foregroundColor(DS.Color.ink.opacity(0.7))
                        .multilineTextAlignment(.center)
                    LanguageToggle(isVietnamese: $isVietnamese)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.md)

                // Line counter
                Text("\(t(L.Splits.line, vi)) \(viewModel.currentSplitIndex + 1) \(t(L.Splits.of, vi)) 6")
                    .font(DS.Font.serif(16, weight: .semibold))
                    .foregroundColor(DS.Color.gold)
                    .padding(.top, DS.Spacing.lg)

                Spacer()

                // Stalk bundle
                VStack(spacing: 4) {
                    ZStack(alignment: .leading) {
                        HStack(spacing: 2) {
                            ForEach(0..<stalkCount, id: \.self) { i in
                                let splitIndex = Int(CGFloat(stalkCount) * viewModel.splitProgress[viewModel.currentSplitIndex])
                                let isLeft = i < splitIndex
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(isLeft ? DS.Color.ink.opacity(0.5) : DS.Color.ink.opacity(0.2))
                                    .frame(width: max(2, (geometry.size.width - 80) / CGFloat(stalkCount)), height: 180)
                            }
                        }
                        .padding(DS.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                                .fill(DS.Color.surface)
                                .cardShadow()
                        )

                        // Handle
                        RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                            .fill(
                                LinearGradient(colors: [DS.Color.goldLight, DS.Color.gold, DS.Color.goldDark],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: handleWidth, height: 190)
                            .shadow(color: DS.Color.gold.opacity(0.3), radius: 6, x: 0, y: 2)
                            .overlay(
                                Image(systemName: "line.horizontal.3")
                                    .font(.caption)
                                    .foregroundColor(DS.Color.ink.opacity(0.4))
                            )
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let maxOffset = geometry.size.width - 80 - handleWidth
                                        dragOffset = min(max(value.translation.width, 0), maxOffset)
                                        dragTrajectory.append(value.location)
                                        if let last = lastDragPosition {
                                            totalDragDistance += hypot(value.location.x - last.x, value.location.y - last.y)
                                        }
                                        lastDragPosition = value.location
                                        if dragStartTime == nil { dragStartTime = Date() }
                                        let percentage = maxOffset > 0 ? Double(dragOffset / maxOffset) : 0.5
                                        viewModel.updateSplit(percentage: percentage, speed: 0, jitter: [], trajectory: dragTrajectory)
                                    }
                                    .onEnded { _ in
                                        let maxOffset = geometry.size.width - 80 - handleWidth
                                        let percentage = maxOffset > 0 ? Double(dragOffset / maxOffset) : 0.5
                                        let duration = dragStartTime.map { Date().timeIntervalSince($0) } ?? 1
                                        let speed = duration > 0 ? Double(totalDragDistance) / duration : 0
                                        let xPositions = dragTrajectory.map(\.x)
                                        let meanX = xPositions.reduce(0, +) / max(1, Double(xPositions.count))
                                        let variance = xPositions.reduce(0) { $0 + ($1 - meanX) * ($1 - meanX) }
                                        let jitter: [Double] = xPositions.count > 0 ? [Double(variance / Double(xPositions.count))] : [0.0]
                                        viewModel.completeSplit(percentage: percentage, speed: speed, jitter: jitter, trajectory: dragTrajectory)
                                        dragOffset = 0; dragTrajectory = []; lastDragPosition = nil; dragStartTime = nil; totalDragDistance = 0
                                    }
                            )
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .frame(height: 220)

                Spacer()

                // Progress
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(0..<6, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < viewModel.currentSplitIndex ? DS.Color.gold
                                  : i == viewModel.currentSplitIndex ? DS.Color.gold.opacity(0.4)
                                  : DS.Color.ink.opacity(0.08))
                            .frame(width: 36, height: 5)
                    }
                }
                .padding(.bottom, DS.Spacing.sm)

                Text(t(L.Splits.hint, vi))
                    .font(DS.Font.serif(12))
                    .foregroundColor(DS.Color.inkFaded.opacity(0.4))
                    .padding(.bottom, DS.Spacing.md)
            }
        }
        .background(RitualBackground())
    }
}
