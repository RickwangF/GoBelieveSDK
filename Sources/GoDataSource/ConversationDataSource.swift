//
// Created by Nan Yang on 2021/12/23.
//

import Foundation
import GRDB
import JiuFoundation

protocol DataSource {
    var database: DatabaseQueue { get }
    var queue: DispatchQueue { get }
}

extension DataSource {
    func run<T>(_ method: @escaping () -> Result<T, Error>) -> Future<T> {
        let promise = queue.makePromise(of: T.self)
        queue.async {
            promise.completeWith(method())
        }
        return promise.futureResult
    }

    func tryRun<T>(_ method: @escaping () throws -> T) -> Future<T> {
        let promise = queue.makePromise(of: T.self)
        queue.async {
            do {
                promise.succeed(try method())
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }

    func tryAsyncRead<T>(_ method: @escaping (Database) throws -> T) -> Future<T>  {
        let promise = queue.makePromise(of: T.self)
        database.asyncRead { result in
            switch result {
            case let .success(database):
                do {
                    promise.succeed(try method(database))
                } catch {
                    promise.fail(error)
                }
            case let .failure(error):
                promise.fail(error)
            }
        }
        return promise.futureResult
    }

    func tryAsyncWrite<T>(_ method: @escaping (Database) throws -> T) -> Future<T>  {
        let promise = queue.makePromise(of: T.self)
        database.asyncWrite(method) { (_, result) in
            promise.completeWith(result)
        }
        return promise.futureResult
    }
}

public struct ConversationDataSource: DataSource {
    public let database: DatabaseQueue
    public let queue: DispatchQueue

    init(database: DatabaseQueue, queue: DispatchQueue) {
        self.database = database
        self.queue = queue
    }

    public init(path: String, queue: DispatchQueue? = nil) throws {
        var configuration = Configuration()
        configuration.prepareDatabase(ConversationDataSource.prepareDatabase)
        let database = try DatabaseQueue(path: path, configuration: configuration)
        self.init(database: database, queue: queue ?? DispatchQueue.global(qos: .utility))
    }

    public func insert(record: ConversationRecord) -> Bool {
        do {
            try database.write { database -> Void in
                let exists = try Int.fetchOne(database, sql: ConversationRecord.selectCount, arguments: [
                    record.targetUid
                ])
                if exists.unwrap(or: 0) > 0 { // 有旧值，更新
                    try record.update(database)
                } else { // 不存在，插入
                    try record.insert(database)
                }
            }
            return true
        } catch {
#if DEBUG
            print(#fileID, #function, error)
#endif
            return false
        }
    }

    public func insertAsync(record: ConversationRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        database.asyncWrite { database -> Void in
            let exists = try Int.fetchOne(database, sql: ConversationRecord.selectCount, arguments: [
                record.targetUid
            ])
            if exists.unwrap(or: 0) > 0 { // 有旧值，更新
                try record.update(database)
            } else { // 不存在，插入
                try record.insert(database)
            }
        } completion: { (_: Database, result: Result<Void, Error>) in
            completion(result)
        }
    }

    public func sortedConversation(completion: @escaping (Result<[ConversationRecord], Error>) -> Void) {
        database.asyncWrite { database -> [ConversationRecord] in
            try ConversationRecord.fetchAll(database, sql: ConversationRecord.selectSortedAll)
        } completion: { (_: Database, result: Result<[ConversationRecord], Error>) in
            completion(result)
        }
    }

    public func remove(uid: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        database.asyncWrite { database -> Void in
            try ConversationRecord.deleteOne(database, key: [
                ConversationRecord.CodingKeys.targetUid.rawValue: uid
            ])
        } completion: { (_: Database, result: Result<Void, Error>) in
            completion(result)
        }
    }

    public func removeAll(completion: @escaping (Result<Void, Error>) -> Void) {
        database.asyncWrite { database -> Void in
            try ConversationRecord.deleteAll(database)
        } completion: { (_: Database, result: Result<Void, Error>) in
            completion(result)
        }
    }

    func sumAllNewMessageCount() -> Result<Int, Error> {
        do {
            let value = try database.read { database -> Int? in
                try Int.fetchOne(database, sql: ConversationRecord.sumAllNewMessageCount)
            }
            return .success(value ?? 0)
        } catch {
            return .failure(error)
        }
    }

    func setAllIsRevoked(uuids: [String]) -> Future<Void> {
        tryAsyncWrite { database -> Void in
            let uuid = uuids.map { "'\($0)'" }
                .joined(separator: ",")
            try database.execute(sql: "UPDATE gb_conversation SET is_callback= 1 WHERE msguuid IN (\(uuid))")
        }
    }

    /// 根据 uid 查询数据，如果查询不到则返回 `nil`。
    ///
    /// - Parameter uid: 要查询的 uid。
    /// - Returns: 异步从查询结果。
    public func selectOne(uid: Int64) -> Future<ConversationRecord?> {
        tryAsyncRead { database -> ConversationRecord? in
            try ConversationRecord.fetchOne(database, key: [
                ConversationRecord.CodingKeys.targetUid.rawValue: uid
            ])
        }
    }

    // 该方法存在的意义仅为兼容旧版 API，因此不是 public 的。
    // 所有 API 均不能吞异常，除非因为兼容性问题。
    func selectOnSync(uid: Int64) -> Result<ConversationRecord?, Error> {
        do {
            let value = try database.read { database -> ConversationRecord? in
                try ConversationRecord.fetchOne(database, key: [
                    ConversationRecord.CodingKeys.targetUid.rawValue: uid
                ])
            }
            return .success(value)
        } catch {
            return .failure(error)
        }
    }

    /// 插入或者更新 `uid` 对应的数据条目。
    /// 如果根据 `uid` 查询不到，则会调用 `insert` 方法。反之则调用 `update` 方法。
    ///
    /// - Parameters:
    ///   - uid: 要更新数据的 targetUid 。
    ///   - insert: 插入数据的方法。
    ///   - update: 更新数据的方法。
    /// - Returns: 异步的更新结果，`nil` 表示查询不到。
    public func insertOne(uid: Int64, insert: @escaping () -> ConversationRecord,
        update: @escaping (inout ConversationRecord) -> [String]) -> Future<ConversationRecord?> {
        tryAsyncWrite { database -> ConversationRecord? in
            let old = try ConversationRecord.fetchOne(database, key: [
                ConversationRecord.CodingKeys.targetUid.rawValue: uid
            ])
            if var item = old {
                let columns = update(&item)
                if columns.isEmpty {
                    try item.update(database)
                } else {
                    try item.update(database, columns: Set(columns))
                }
                return item
            } else {
                let next = insert()
                return try next.inserted(database)
            }
        }
    }

    /// 更新 `uid` 对应的数据条目。如果根据 `uid` 查询不到，则 `update` 方法不会调用。
    ///
    /// - Parameters:
    ///   - uid: 要更新数据的 targetUid 。
    ///   - update: 更新数据的方法。
    /// - Returns: 异步的更新结果，`nil` 表示查询不到。
    public func updateOne(uid: Int64,
        update: @escaping (inout ConversationRecord) -> [String]) -> Future<ConversationRecord?> {
        tryAsyncWrite { database -> ConversationRecord? in
            let old = try ConversationRecord.fetchOne(database, key: [
                ConversationRecord.CodingKeys.targetUid.rawValue: uid
            ])
            if var item = old {
                let columns = update(&item)
                if columns.isEmpty {
                    try item.update(database)
                } else {
                    try item.update(database, columns: Set(columns))
                }
                return item
            } else {
                return old
            }
        }
    }

    /// GRDB 准备数据库的方法，可以用于新建数据库，或者对表结构做操作。
    /// **不要手动调用。**
    ///
    /// - Parameter database: 要修改的数据库，由 GRDB 传进来。
    /// - Throws: `DatabaseError`，数据库操作异常。
    static func prepareDatabase(_ database: Database) throws {
        let columns = try database.columns(in: ConversationRecord.databaseTableName)
        var exists = columns.contains { info in
            info.name == "conversation_type"
        }
        if !exists {
            try database.execute(sql: ConversationRecord.mergeSchemeV1)
#if DEBUG
            print(#fileID, #function, "ConversationRecord 表结构 V1 变更成功")
#endif
        }
        let indexes = try database.indexes(on: ConversationRecord.databaseTableName)
        exists = indexes.contains { info in
            info.name == "conversation_index"
        }
        if !exists {
            try database.execute(sql: ConversationRecord.mergeSchemeV2)
#if DEBUG
            print(#fileID, #function, "ConversationRecord 表结构 V2 变更成功")
#endif
        }
    }
}
