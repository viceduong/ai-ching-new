import Foundation

// MARK: - Local Persistence Service
/// Manages reading history using Codable + FileManager.
/// Fully offline, no network calls. Encrypted at rest via NSFileProtectionCompleteUntilFirstUserAuthentication.
/// iOS 15+ compatible (no SwiftData dependency).
final class StorageService: @unchecked Sendable {

    static let shared = StorageService()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    private var cachedReadings: [Reading]?
    private let readingsFileName = "readings.json"

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    // MARK: - File URL

    private var readingsURL: URL? {
        guard let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docsDir.appendingPathComponent(readingsFileName)
    }

    // MARK: - CRUD Operations

    /// Save a new reading to history.
    @discardableResult
    func saveReading(_ reading: Reading) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var readings = loadReadingsInternal()
        readings.insert(reading, at: 0) // newest first
        return saveReadingsInternal(readings)
    }

    /// Load all saved readings, newest first.
    func loadReadings() -> [Reading] {
        lock.lock()
        defer { lock.unlock() }
        return loadReadingsInternal()
    }

    /// Delete a specific reading by ID.
    @discardableResult
    func deleteReading(id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var readings = loadReadingsInternal()
        readings.removeAll { $0.id == id }
        return saveReadingsInternal(readings)
    }

    /// Update notes for a reading.
    @discardableResult
    func updateNotes(id: UUID, notes: String?) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var readings = loadReadingsInternal()
        guard let idx = readings.firstIndex(where: { $0.id == id }) else { return false }
        let old = readings[idx]
        readings[idx] = Reading(
            id: old.id,
            date: old.date,
            question: old.question,
            lineValues: old.lineValues,
            primaryHexagramIndex: old.primaryHexagramIndex,
            secondaryHexagramIndex: old.secondaryHexagramIndex,
            hashSeed: old.hashSeed,
            userNotes: notes
        )
        return saveReadingsInternal(readings)
    }

    /// Get a single reading by ID.
    func reading(id: UUID) -> Reading? {
        loadReadings().first { $0.id == id }
    }

    /// Search readings by question text.
    func search(query: String) -> [Reading] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return loadReadings()
        }
        return loadReadings().filter { reading in
            reading.question.localizedCaseInsensitiveContains(query)
        }
    }

    /// Total number of saved readings.
    var readingCount: Int {
        loadReadings().count
    }

    /// Delete all readings.
    @discardableResult
    func deleteAll() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        cachedReadings = []
        return saveReadingsInternal([])
    }

    // MARK: - Internal

    private func loadReadingsInternal() -> [Reading] {
        if let cached = cachedReadings { return cached }

        guard let url = readingsURL,
              let data = try? Data(contentsOf: url),
              let readings = try? decoder.decode([Reading].self, from: data)
        else {
            return []
        }
        cachedReadings = readings
        return readings
    }

    @discardableResult
    private func saveReadingsInternal(_ readings: [Reading]) -> Bool {
        guard let url = readingsURL else { return false }

        do {
            let data = try encoder.encode(readings)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            cachedReadings = readings
            return true
        } catch {
            print("Failed to save readings: \(error.localizedDescription)")
            return false
        }
    }

    /// Export all readings as JSON data (for share feature).
    func exportReadings() -> Data? {
        let readings = loadReadings()
        return try? encoder.encode(readings)
    }
}
