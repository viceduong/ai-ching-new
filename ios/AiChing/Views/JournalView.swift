import SwiftUI

// MARK: - Journal / Reading History
/// Displays all saved readings in a scrollable list with search.
struct JournalView: View {
    @ObservedObject var viewModel: RitualViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedReading: Reading?
    @State private var showDeleteAlert = false
    @State private var deleteTarget: Reading?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                if #available(iOS 15.0, *) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.inkBlack.opacity(0.3))
                        TextField("Search readings...", text: $viewModel.searchQuery)
                            .font(.system(.body, design: .serif))
                            .onChange(of: viewModel.searchQuery) { _ in
                                viewModel.searchJournal()
                            }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ricePaper)
                            .shadow(color: .black.opacity(0.03), radius: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                if viewModel.savedReadings.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()

                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.inkBlack.opacity(0.15))

                        Text("No readings yet")
                            .font(.system(.title3, design: .serif))
                            .foregroundColor(.inkBlack.opacity(0.4))

                        Text("Complete a divination ritual\nto see your history here.")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(.inkBlack.opacity(0.3))
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                } else {
                    // Reading list
                    List {
                        ForEach(viewModel.savedReadings) { reading in
                            HistoryRowView(reading: reading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedReading = reading
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTarget = reading
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.loadJournal()
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
                .font(.system(.body, design: .serif))
                .foregroundColor(.inkBlack.opacity(0.6)),
                trailing: Group {
                    if !viewModel.savedReadings.isEmpty {
                        Button(action: {
                            viewModel.loadJournal()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.gold)
                        }
                    }
                }
            )
        }
        .accentColor(.gold)
        .sheet(item: $selectedReading) { reading in
            ReadingDetailView(reading: reading, viewModel: viewModel)
        }
        .alert("Delete Reading", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    viewModel.deleteReading(id: target.id)
                }
            }
        } message: {
            Text("This reading will be permanently deleted. This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadJournal()
        }
    }
}

// MARK: - History Row
struct HistoryRowView: View {
    let reading: Reading

    private let hexagramService = HexagramService.shared

    var body: some View {
        HStack(spacing: 12) {
            // Hexagram number
            VStack(spacing: 2) {
                Text("\(reading.primaryHexagramIndex + 1)")
                    .font(.system(.title3, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundColor(.gold)

                if let _ = reading.secondaryHexagramIndex {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(.gold.opacity(0.5))
                }
            }
            .frame(width: 36)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(hexagramService.name(for: reading.primaryHexagramIndex))
                    .font(.system(.subheadline, design: .serif))
                    .fontWeight(.medium)
                    .foregroundColor(.inkBlack)
                    .lineLimit(1)

                Text(reading.question)
                    .font(.system(.caption, design: .serif))
                    .foregroundColor(.inkBlack.opacity(0.5))
                    .lineLimit(1)

                Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.inkBlack.opacity(0.3))
            }

            Spacer()

            // Lines preview
            HStack(spacing: 2) {
                ForEach(reading.lineValues, id: \.self) { val in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(val == 7 || val == 9 ? Color.inkBlack : Color.inkBlack.opacity(0.3))
                        .frame(width: 3, height: 12)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reading Detail View
struct ReadingDetailView: View {
    let reading: Reading
    @ObservedObject var viewModel: RitualViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showShareSheet = false

    private let hexagramService = HexagramService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Date
                    Text(reading.date.formatted(date: .long, time: .shortened))
                        .font(.system(.caption, design: .serif))
                        .foregroundColor(.inkBlack.opacity(0.4))
                        .padding(.top, 16)

                    // Question
                    VStack(spacing: 4) {
                        Text("Question")
                            .font(.system(.caption, design: .serif))
                            .foregroundColor(.inkBlack.opacity(0.4))
                        Text("\"\(reading.question)\"")
                            .font(.system(.body, design: .serif))
                            .italic()
                            .foregroundColor(.inkBlack.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    RitualDivider()

                    // Primary hexagram
                    VStack(spacing: 8) {
                        if let hex = hexagramService.hexagram(at: reading.primaryHexagramIndex) {
                            Text(hex.chineseName)
                                .font(.system(.title, design: .serif))
                                .fontWeight(.light)
                                .foregroundColor(.inkBlack.opacity(0.6))
                            Text(hex.displayName)
                                .font(.system(.title3, design: .serif))
                                .foregroundColor(.inkBlack)
                        }

                        // Lines
                        let lineValues = reading.lineValues.compactMap { LineValue(rawValue: $0) }
                        VStack(spacing: 6) {
                            ForEach((0..<6).reversed(), id: \.self) { i in
                                let val = lineValues[safe: i] ?? .youngYin
                                HexagramLineView(
                                    isYang: val == .youngYang || val == .oldYang,
                                    isMoving: val == .oldYin || val == .oldYang,
                                    color: .inkBlack,
                                    animated: false,
                                    width: 80
                                )
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.ricePaper.opacity(0.3))
                        )
                    }

                    // Secondary hexagram
                    if let secondaryIdx = reading.secondaryHexagramIndex {
                        RitualDivider()

                        VStack(spacing: 4) {
                            Text("Changes to")
                                .font(.system(.caption, design: .serif))
                                .foregroundColor(.gold.opacity(0.6))
                            if let hex = hexagramService.hexagram(at: secondaryIdx) {
                                Text(hex.displayName)
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundColor(.inkBlack.opacity(0.7))
                            }
                        }
                    }

                    // Hash seed
                    Text("Seed: \(reading.hashSeed.prefix(24))...")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.inkBlack.opacity(0.2))
                        .padding(.top, 8)

                    // Share
                    Button(action: { showShareSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Reading")
                        }
                        .font(.system(.subheadline, design: .serif))
                        .foregroundColor(.gold)
                    }
                    .padding(.top, 8)
                }
            }
            .ritualBackground()
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.inkBlack.opacity(0.6))
                }
            }
        }
        .accentColor(.gold)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [viewModel.shareReading(reading)])
        }
    }
}

// MARK: - Preview
struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView(viewModel: RitualViewModel.preview)
    }
}
