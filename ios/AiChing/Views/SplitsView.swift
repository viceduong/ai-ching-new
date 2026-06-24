import SwiftUI

// MARK: - Step 3: The Six Splits (Virtual Yarrow Ritual)
/// User drags a golden handle across a bundle of 50 stalks, 6 times (once per line).
/// Each split captures fine motor entropy: position, speed, jitter, trajectory.
struct SplitsView: View {
    @ObservedObject var viewModel: RitualViewModel

    @State private var dragOffset: CGFloat = 0
    @State private var dragTrajectory: [CGPoint] = []
    @State private var lastDragPosition: CGPoint?
    @State private var dragStartTime: Date?
    @State private var totalDragDistance: CGFloat = 0
    @State private var stalkWidth: CGFloat = 0

    private let stalkCount = 50
    private let handleWidth: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Step indicator
                StepProgressView(currentStep: .splits)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                // Title
                Text("分 蓍")
                    .font(.system(.title, design: .serif))
                    .fontWeight(.light)
                    .foregroundColor(.inkBlack)
                    .opacity(0.7)

                Text("Splitting the Stalks")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.4))
                    .italic()

                // Line counter
                Text("Line \(viewModel.currentSplitIndex + 1) of 6")
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(.gold.opacity(0.7))
                    .padding(.top, 12)

                Spacer()

                // Instruction
                Text("Drag the handle to where it feels right.")
                    .font(.system(.body, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.6))
                    .padding(.horizontal, 32)

                Spacer()

                // Stalk bundle
                VStack(spacing: 4) {
                    ZStack(alignment: .leading) {
                        // Stalk lines
                        HStack(spacing: 2) {
                            ForEach(0..<stalkCount, id: \.self) { i in
                                // Determine if this stalk is on left or right of split
                                let splitIndex = Int(
                                    (CGFloat(stalkCount)) * (viewModel.splitProgress[viewModel.currentSplitIndex])
                                )
                                let isLeft = i < splitIndex

                                Rectangle()
                                    .fill(isLeft
                                        ? Color.inkBlack.opacity(0.6)
                                        : Color.inkBlack.opacity(0.3))
                                    .frame(width: max(1, (geometry.size.width - 80) / CGFloat(stalkCount)))
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.ricePaper)
                                .shadow(color: .black.opacity(0.05), radius: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.inkBlack.opacity(0.1), lineWidth: 0.5)
                        )

                        // Golden drag handle
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.gold, .gold.opacity(0.7), .gold],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: handleWidth, height: 210)
                            .shadow(color: .gold.opacity(0.3), radius: 4, x: 0, y: 2)
                            .overlay(
                                Image(systemName: "line.horizontal.3")
                                    .font(.caption)
                                    .foregroundColor(.inkBlack.opacity(0.5))
                            )
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newOffset = min(
                                            max(value.translation.width, 0),
                                            geometry.size.width - 80 - handleWidth
                                        )
                                        dragOffset = newOffset

                                        // Track trajectory for entropy
                                        let pos = value.location
                                        dragTrajectory.append(pos)

                                        if let last = lastDragPosition {
                                            totalDragDistance += hypot(pos.x - last.x, pos.y - last.y)
                                        }
                                        lastDragPosition = pos

                                        if dragStartTime == nil {
                                            dragStartTime = Date()
                                        }

                                        // Update split percentage
                                        let maxOffset = geometry.size.width - 80 - handleWidth
                                        let percentage = maxOffset > 0 ? Double(dragOffset / maxOffset) : 0.5

                                        viewModel.updateSplit(
                                            percentage: percentage,
                                            speed: 0,
                                            jitter: [],
                                            trajectory: dragTrajectory
                                        )
                                    }
                                    .onEnded { _ in
                                        let maxOffset = geometry.size.width - 80 - handleWidth
                                        let percentage = maxOffset > 0 ? Double(dragOffset / maxOffset) : 0.5

                                        // Calculate speed
                                        let duration = dragStartTime.map { Date().timeIntervalSince($0) } ?? 1
                                        let speed = duration > 0 ? Double(totalDragDistance) / duration : 0

                                        // Calculate jitter (variance of x-positions)
                                        let xPositions = dragTrajectory.map(\.x)
                                        let meanX = xPositions.reduce(0, +) / max(1, Double(xPositions.count))
                                        let variance = xPositions.reduce(0) { $0 + ($1 - meanX) * ($1 - meanX) }
                                        let jitter = xPositions.count > 0 ? [Double(variance) / Double(xPositions.count)] : [0.0]

                                        viewModel.completeSplit(
                                            percentage: percentage,
                                            speed: speed,
                                            jitter: jitter,
                                            trajectory: dragTrajectory
                                        )

                                        // Reset drag state
                                        dragOffset = 0
                                        dragTrajectory = []
                                        lastDragPosition = nil
                                        dragStartTime = nil
                                        totalDragDistance = 0
                                    }
                            )
                    }
                    .padding(.horizontal, 32)
                }
                .frame(height: 220)

                Spacer()

                // Completed splits indicator
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < viewModel.currentSplitIndex
                                ? Color.gold
                                : i == viewModel.currentSplitIndex
                                ? Color.gold.opacity(0.4)
                                : Color.gray.opacity(0.15))
                            .frame(width: 32, height: 4)
                    }
                }
                .padding(.bottom, 16)

                // Split percentage
                if viewModel.splitProgress[viewModel.currentSplitIndex] > 0 {
                    Text("\(Int(viewModel.splitProgress[viewModel.currentSplitIndex] * 100))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.inkBlack.opacity(0.4))
                }

                Spacer()
            }
        }
        .ritualBackground()
        .onAppear {
            dragOffset = 0
            dragTrajectory = []
        }
    }
}

// MARK: - Preview
struct SplitsView_Previews: PreviewProvider {
    static var previews: some View {
        SplitsView(viewModel: RitualViewModel.preview)
    }
}
