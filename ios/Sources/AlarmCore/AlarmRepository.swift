import Foundation

public struct AlarmChange: Codable, Equatable {
    public var target: [AlarmRecord]
    public var additions: [AlarmRecord]
    public var cancellations: Set<UUID>
}

public struct AlarmDocument: Codable, Equatable {
    public var version = 2
    public var records: [AlarmRecord] = []
    public var change: AlarmChange?
    public init(records: [AlarmRecord] = [], change: AlarmChange? = nil) {
        self.records = records
        self.change = change
    }

    public func validate() throws {
        guard version == 2 else { throw AlarmFailure.corruptStorage }
        for list in [records, change?.target ?? [], change?.additions ?? []] {
            guard Set(list.map(\.id)).count == list.count,
                Set(list.map(\.systemID)).count == list.count
            else { throw AlarmFailure.corruptStorage }
            for alarm in list { try alarm.validate() }
        }
    }
}

@MainActor public protocol AlarmPersistence {
    func load() throws -> AlarmDocument
    func save(_ document: AlarmDocument) throws
}

@MainActor public final class FileAlarmRepository: AlarmPersistence {
    public let url: URL
    public init(url: URL) { self.url = url }

    public func load() throws -> AlarmDocument {
        guard FileManager.default.fileExists(atPath: url.path) else { return AlarmDocument() }
        do {
            var document = try JSONDecoder().decode(AlarmDocument.self, from: Data(contentsOf: url))
            if document.version == 1 {
                // Migrate every journal snapshot as well as committed records before strict validation.
                // Reject corrupt values outside the old contract rather than disguising them by clamping.
                func migrate(_ records: [AlarmRecord]) throws -> [AlarmRecord] {
                    try records.map { record in
                        guard (1...30).contains(record.snoozeMinutes) else { throw AlarmFailure.corruptStorage }
                        var updated = record
                        updated.snoozeMinutes = min(15, max(2, record.snoozeMinutes))
                        return updated
                    }
                }
                document.records = try migrate(document.records)
                if var change = document.change {
                    change.target = try migrate(change.target)
                    change.additions = try migrate(change.additions)
                    document.change = change
                }
                document.version = 2
                try save(document)
            }
            try document.validate()
            return document
        } catch {
            throw AlarmFailure.corruptStorage
        }
    }

    public func save(_ document: AlarmDocument) throws {
        try document.validate()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(document)
        try data.write(to: url, options: .atomic)
    }
}
