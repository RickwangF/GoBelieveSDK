//
//  GroupMessageTests.swift
//  GobelieveTests
//
//  Created by Peter on 2022/2/28.
//

import XCTest
@testable import Gobelieve

/// 建表预计
let groupTable =
"""
CREATE TABLE IF NOT EXISTS group_message(
                                        id INTEGER NOT NULL PRIMARY KEY,
                                        group_id INTEGER NOT NULL,
                                        sender INTEGER NOT NULL DEFAULT 0,
                                        receiver INTEGER NOT NULL DEFAULT 0,
                                        timestamp INTEGER NOT NULL DEFAULT 0,
                                        flags INTEGER NOT NULL DEFAULT 0,
                                        content TEXT,
                                        cacheheight INTEGER NOT NULL DEFAULT 0,
                                        cachewidth INTEGER NOT NULL DEFAULT 0,
                                        lineheight INTEGER NOT NULL DEFAULT 0,
                                        readuuid TEXT,
                                        haveread INTEGER NOT NULL DEFAULT 0,
                                        callback INTEGER NOT NULL DEFAULT 0,
                                        deletetag INTEGER NOT NULL DEFAULT 0);
"""

class GroupMessageTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let database = try group()
        database.db = FMDatabase(path: ":memory:")
        database.db.open()
        database.db.executeStatements(groupTable)
        database.checkHaveManualColumn()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try group().db.close()
    }

    /// 测试已读当前聊天会话中非自己消息已读操作
    func testMarkAllReadByConversationID() throws {
        let database = try group()
        let conversationid: Int64 = 100001
        let myid: Int64 = 100000
        let orherid: Int64 = 100003
        let mys = random(sender: myid, recevier: conversationid, count: 6)
        let yours = random(sender: orherid, recevier: conversationid, count: 5)
        for item in mys + yours {
            guard database.insert(item, uid: conversationid) else {
                throw TestError.insertFalied
            }
        }
        
        let now = Int(Date().timeIntervalSince1970) * 1000 + 100000
        let iterator = database.forwardMessageIterator(conversationid, timeStamp: now)
        var list = [IMessage]()
        while let next = iterator?.next() {
            list.append(next)
        }
        
        XCTAssertEqual(list.count, (mys + yours).count)
        
        guard database.markAllMessagesRead(byConversationID: conversationid, senderUID: myid) else {
            throw TestError.markAllMessagesReadFailed
        }
        
        let messages = database.queryUnreadOnlyMessages(toUUID: nil, byTargetUID: conversationid, senderUID: myid)
        XCTAssertEqual(messages.count, 0)
    }
}

extension GroupMessageTests {
    func random(sender: Int64, recevier: Int64, count: Int) -> [IMessage] {
        IMessage.randomTextMessages(withCount: count).map { item -> IMessage in
            item.sender = sender
            item.receiver = recevier
            return item
        }
    }
    
    func group() throws -> SQLGroupMessageDB {
        let database: SQLGroupMessageDB? = SQLGroupMessageDB.instance()
        guard let database = database else {
            throw TestError.databaseNil
        }
        return database
    }
}

enum TestError: Error {
    case databaseNil
    case insertFalied
    case markAllMessagesReadFailed
}
