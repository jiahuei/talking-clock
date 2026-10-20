import Foundation

public struct AlarmChange: Codable, Equatable {
    public var target: [AlarmRecord]
    public var additions: [AlarmRecord]
    public var cancellations: Set<UUID>
}

public struct AlarmDocument: Codable, Equatable {
    public var version = 1
    public var records: [AlarmRecord] = []
    public var change: AlarmChange?
    public init(records: [AlarmRecord] = [], change: AlarmChange? = nil) {
        self.records = records
        self.change = change
    }

    public func validate() throws {
        guard version == 1 else { throw AlarmFailure.corruptStorage }
        for list in [records, change?.target ?? [], change?.additions ?? []] {
            guard Set(list.map(\.id)).count == list.count,
                  Set(list.map(\.systemID)).count == list.count else { throw AlarmFailure.corruptStorage }
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
            let document = try JSONDecoder().decode(AlarmDocument.self, from: Data(contentsOf: url))
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
