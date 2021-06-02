//
//  SQLGroupMessageDBTests.m
//  GobelieveTests
//
//  Created by Tingsong Xu on 2021/5/28.
//

#import <XCTest/XCTest.h>
#import <Gobelieve/Gobelieve.h>
#import "Random.h"
#import "IMessage+CreatorMode.h"

static NSString *kCreateGroupTable = @"CREATE TABLE IF NOT EXISTS group_message("
                                        "id INTEGER NOT NULL PRIMARY KEY,"
                                        "group_id INTEGER NOT NULL,"
                                        "sender INTEGER NOT NULL DEFAULT 0,"
                                        "receiver INTEGER NOT NULL DEFAULT 0,"
                                        "timestamp INTEGER NOT NULL DEFAULT 0,"
                                        "flags INTEGER NOT NULL DEFAULT 0,"
                                        "content TEXT,"
                                        "cacheheight INTEGER NOT NULL DEFAULT 0,"
                                        "cachewidth INTEGER NOT NULL DEFAULT 0,"
                                        "lineheight INTEGER NOT NULL DEFAULT 0,"
                                        "readuuid TEXT,"
                                        "haveread INTEGER NOT NULL DEFAULT 0,"
                                        "callback INTEGER NOT NULL DEFAULT 0,"
                                        "deletetag INTEGER NOT NULL DEFAULT 0"
                                     ");";

/// 群聊消息表名
static NSString *groupMessageTableName = @"group_message";

@interface SQLGroupMessageDBTests : XCTestCase

@end

@implementation SQLGroupMessageDBTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    SQLGroupMessageDB.instance.db = [[FMDatabase alloc] initWithPath:@":memory:"];
    [SQLGroupMessageDB.instance.db open];
    [SQLGroupMessageDB.instance.db executeStatements:kCreateGroupTable];
    [SQLGroupMessageDB.instance checkHaveManualColumn];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [SQLGroupMessageDB.instance.db close];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [SQLGroupMessageDB.instance checkHaveManualColumn];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

/// 测试文本消息插入
- (void)testMessageInsertSuccess {
    NSInteger count = [self countOfRecords];
    XCTAssertEqual(count, 0);
    IMessage *one = [IMessage randomTextMessagesWithCount:1].firstObject;
    int64_t groupid = one.receiver;
    [SQLGroupMessageDB.instance insertMessage:one uid:groupid];
    // 此字段暂不使用，清空
    one.msgId = 0;
    count = [self countOfRecords];
    XCTAssertEqual(count, 1);
    IMessage *result = [SQLGroupMessageDB.instance getLatestMessageWithTargetUid:groupid];
    XCTAssertNotNil(result);
    [self compare:one withOther:result];
}

/// 测试记录已读修改更新
- (void)testMessageHaveReadUpdate {
    IMessage *one = [IMessage randomTextMessagesWithCount:1].firstObject;
    int64_t groupid = one.receiver;
    [SQLGroupMessageDB.instance insertMessage:one uid:groupid];
    one.haveRead = YES;
    [SQLGroupMessageDB.instance markMesageHaveRead:one.readUUID];
    IMessage *result = [SQLGroupMessageDB.instance getMessage:one.readUUID];
    [self compare:result withOther:one];
}

/// 测试删除消息
- (void)testMessageDelete {
    IMessage *one = [IMessage randomTextMessagesWithCount:1].firstObject;
    int64_t groupid = one.receiver;
    [SQLGroupMessageDB.instance insertMessage:one uid:groupid];
    IMessage *result = [SQLGroupMessageDB.instance getLatestMessageWithTargetUid:groupid];
    // 插入后查出来是非空
    XCTAssertNotNil(result);
    [SQLGroupMessageDB.instance updateDeleteUUIDS:@[one.readUUID]];
    IMessage *deleteResult = [SQLGroupMessageDB.instance getLatestMessageWithTargetUid:groupid];
    // 删除后是空数据
    XCTAssertNil(deleteResult);
}

/// 当前表中的记录数
- (NSInteger)countOfRecords {
    NSInteger result = 0;
    FMResultSet* resultSet = [SQLGroupMessageDB.instance.db executeQuery:[NSString stringWithFormat:@"select count(0) from %@;", groupMessageTableName]];
    [resultSet next];
    result = [resultSet intForColumnIndex:0];
    [resultSet close];
    return result;
}

- (void)compare:(IMessage *)item withOther:(IMessage *)other {
    // 消息uuid一致
    XCTAssert([item.readUUID isEqualToString:other.readUUID]);
    // 消息接收者是群聊id
    XCTAssertEqual(item.receiver, other.receiver);
    // 消息发送者一致
    XCTAssertEqual(item.sender, other.sender);
    // 时间戳一致
    XCTAssertEqual(item.timestamp, other.timestamp);
    // 状态一致
    XCTAssertEqual(item.flags, other.flags);
    // 内容一致
    XCTAssert([item.rawContent isEqualToString:other.rawContent]);
    // 撤回状态一致
    XCTAssertEqual(item.callBack, other.callBack);
    // 删除状态一致
    XCTAssertEqual(item.deleteTag, other.deleteTag);
    // 消息缓存高度一致
    XCTAssertEqual(item.manualHeight, other.manualHeight);
    // 消息缓存宽度一致
    XCTAssertEqual(item.manualWidth, other.manualWidth);
    // 消息缓存高度一致
    XCTAssertEqual(item.lineHeight, other.lineHeight);
    // 已读状态一致
    XCTAssertEqual(item.haveRead, other.haveRead);
}

@end
