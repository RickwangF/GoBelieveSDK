//
//  PeerMessageTests.swift
//  GobelieveTests
//
//  Created by Peter on 2022/2/28.
//

import XCTest
@testable import Gobelieve
import SQLite3

let peerTable =
"""
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

CREATE TABLE "peer_message" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "peer" INTEGER NOT NULL,
  "secret" INTEGER DEFAULT 0,
  "sender" INTEGER NOT NULL,
  "receiver" INTEGER NOT NULL,
  "timestamp" INTEGER NOT NULL,
  "flags" INTEGER NOT NULL,
  "content" TEXT,
  "uuid" TEXT,
  "haveread" INTEGER,
  "readuuid" TEXT,
  "cacheheight" INTEGER,
  "cachewidth" INTEGER,
  "lineheight" INTEGER
, callback, deletetag);

COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
"""

class PeerMessageTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let database = try peer()
        database.db = FMDatabase(path: ":memory:")
        database.db.open()
        let state = database.db.executeStatements(peerTable)
        guard state else {
            throw TestError.databaseNil
        }
        database.checkHaveManualColumn()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try peer().db.close()
    }
    
    /// 测试已读当前聊天会话中非自己消息已读操作
    func testMarkAllReadByConversationID() throws {
        let database = try peer()
        let conversationid: Int64 = 100003
        let myid: Int64 = 100000
        let mys = random(sender: myid, recevier: conversationid, count: 6)
        let yours = random(sender: conversationid, recevier: myid, count: 5)
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

extension PeerMessageTests {
    func random(sender: Int64, recevier: Int64, count: Int) -> [IMessage] {
        IMessage.randomTextMessages(withCount: count).map { item -> IMessage in
            item.sender = sender
            item.receiver = recevier
            return item
        }
    }
    
    func peer() throws -> PeerMessageDB {
        let database: PeerMessageDB? = PeerMessageDB.instance()
        guard let database = database else {
            throw TestError.databaseNil
        }
        return database
    }
}
