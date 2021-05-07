//
//  SQLConversationDBTests.m
//  gobelieveSDKTests
//
//  Created by Nan Yang on 2021/5/6.
//

#import <XCTest/XCTest.h>
#import "Random.h"

//#define GOBELIEVE_TEST_PERFORMANCE 1

@import Gobelieve;

static NSString* kCreateTable = @"create table gb_conversation"
                                "("
                                "	id INTEGER not null"
                                "		primary key autoincrement,"
                                "	conversationid integer(256) not null,"
                                "	avatar TEXT(256),"
                                "	nickname TEXT(64),"
                                "	timestamp integer(256),"
                                "	content TEXT(256),"
                                "	msguuid text(256) not null,"
                                "	is_callback integer(32) not null,"
                                "	is_group integer(32) not null,"
                                "	is_delete integer(32) not null,"
                                "	is_top integer(32) not null,"
                                "	unreadcount integer(256) not null,"
                                "	member_type integer(256),"
                                "	member_level integer(256),"
                                "	member_img TEXT(256),"
                                "	draft text(256),"
                                "	unsend_tag integer(32),"
                                "	target_id text(256),"
                                "	is_self integer(32),"
                                "	area TEXT(256),"
                                "	remark_name TEXT(256)"
                                ");";

@interface SQLConversationDBTests : XCTestCase {
    SQLConversationDB* _db;
}
@end

@implementation SQLConversationDBTests

+ (void)setUp {
    randomSeed();
}

- (void)setUp {
    _db = [SQLConversationDB instance];
    _db.dbQueue = [SQLConversationDBTests memoryQueue];
}

- (void)tearDown {
    [_db.dbQueue close];
}

- (void)testConversationInsertSuccess {
    NSInteger count = [self countOfConversation];
    XCTAssertEqual(count, 0);
    Conversation* give = [[Conversation alloc] init];
    give.uid = 1024;
    give.name = randomString();
//    NSLog(@"give.name = %@", give.name);
    [_db addConversation:give];
    count = [self countOfConversation];
    XCTAssertEqual(count, 1);
    Conversation* result = [_db getConversationWithTargetUid:1024];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.uid, 1024);
    XCTAssertEqualObjects(result.name, give.name);
}

- (void)testConversationInsertCompleted {
    Conversation* give = [SQLConversationDBTests randomConversation];
    [_db addConversation:give];
    Conversation* result = [_db getConversationWithTargetUid:give.uid];
    XCTAssertNotNil(result);
    [self assertConversationEqual:result give:give];
}

- (void)testConversationUpdate {
    Conversation* give = [SQLConversationDBTests randomConversation];
    [_db addConversation:give];
    Conversation* next = [SQLConversationDBTests randomConversation];
    next.uid = give.uid;
    [_db replaceConversation:next];
    Conversation* result = [_db getConversationWithTargetUid:give.uid];
    XCTAssertNotNil(result);
    [self assertConversationEqual:result give:next];
}

- (void)testConversationDelete {
    Conversation* give = [SQLConversationDBTests randomConversation];
    [_db addConversation:give];
    [_db deleteConversationWithUid:give.uid];
    Conversation* result = [_db getConversationWithTargetUid:give.uid];
    XCTAssertNil(result);
}

- (void)testConversationChangeIsDelete {
    // NO => YES
    {
        Conversation* give = [SQLConversationDBTests randomConversation];
        give.isDelete = NO;
        [_db addConversation:give];
        [_db disposeConversationIsHide:YES uid:give.uid];
        Conversation* result = [_db getConversationWithTargetUid:give.uid];
        XCTAssertNotNil(result);
        XCTAssertEqual(result.isDelete, YES);
    }
    // YES => NO
    {
        Conversation* give = [SQLConversationDBTests randomConversation];
        give.isDelete = YES;
        [_db addConversation:give];
        [_db disposeConversationIsHide:NO uid:give.uid];
        give.isDelete = NO;
        Conversation* result = [_db getConversationWithTargetUid:give.uid];
        XCTAssertNotNil(result);
        XCTAssertEqual(result.isDelete, NO);
    }
}

- (void)testConversationChangeIsTop {
    // NO => YES
    {
        Conversation* give = [SQLConversationDBTests randomConversation];
        give.isTop = NO;
        [_db addConversation:give];
        [_db disposeConversationIsTop:YES uid:give.uid];
        give.isTop = YES;
        Conversation* result = [_db getConversationWithTargetUid:give.uid];
        XCTAssertNotNil(result);
        XCTAssertEqual(result.isTop, YES);
    }
    // YES => NO
    {
        Conversation* give = [SQLConversationDBTests randomConversation];
        give.isTop = YES;
        [_db addConversation:give];
        [_db disposeConversationIsTop:NO uid:give.uid];
        give.isTop = NO;
        Conversation* result = [_db getConversationWithTargetUid:give.uid];
        XCTAssertNotNil(result);
        XCTAssertEqual(result.isTop, NO);
    }
}

- (void)testConversationCleanUnreadCount {
    Conversation* give = [SQLConversationDBTests randomConversation];
    give.newMsgCount = 1233424324;
    [_db addConversation:give];
    [_db clearConversationMsgCountWithUid:give.uid];
    Conversation* result = [_db getConversationWithTargetUid:give.uid];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.newMsgCount, 0);
}

- (void)testConversationSaveDraft {
    Conversation* give = [SQLConversationDBTests randomConversation];
    give.draft = nil;
    [_db addConversation:give];
    NSString* draft = randomString();
    [_db saveDraftToConversationWithUid:give.uid draft:draft];
    Conversation* result = [_db getConversationWithTargetUid:give.uid];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.draft, draft);
}

- (void)testConversationUpdateTarget {
    Conversation* give = [SQLConversationDBTests randomConversation];
    [_db addConversation:give];
    NSString* targetId = randomString();
    NSString* nickname = randomString();
    NSString* avatar = randomString();
    [_db updateConversationTargetId:targetId nickname:nickname avatar:avatar uid:give.uid];
    Conversation* result = [_db getConversationWithTargetUid:give.uid];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.targetId, targetId);
    XCTAssertEqualObjects(result.name, nickname);
    XCTAssertEqualObjects(result.avatarURL, avatar);
}

#ifdef GOBELIEVE_TEST_PERFORMANCE

- (void)testPerformanceConversationInsert {
    // 换成文件数据库
    [_db.dbQueue close];
    _db.dbQueue = [SQLConversationDBTests queue];
    NSUInteger max = 1000;
    NSMutableArray<Conversation*>* data = [NSMutableArray arrayWithCapacity:max];
    NSUInteger i;
    for (i = 0; i < max; ++i) {
        [data addObject:[SQLConversationDBTests randomConversation]];
    }
    [self measureBlock:^{
        for (Conversation* item in data) {
            [self->_db addConversation:item];
        }
    }];
}

#endif // GOBELIEVE_TEST_PERFORMANCE

- (NSInteger)countOfConversation {
    __block NSInteger result;
    [_db.dbQueue inDatabase:^(FMDatabase* db) {
        FMResultSet* resultSet = [db executeQuery:@"select count(0) from gb_conversation;"];
        [resultSet next];
        result = [resultSet intForColumnIndex:0];
        [resultSet close];
    }];
    return result;
}

- (void)assertConversationEqual:(Conversation *)result give:(Conversation *)give {
    XCTAssertEqualObjects(result.name, give.name);
    XCTAssertEqualObjects(result.avatarURL, give.avatarURL);
    XCTAssertEqualObjects(result.content, give.content);
    XCTAssertEqualObjects(result.msguuid, give.msguuid);
    XCTAssertEqual(result.uid, give.uid);
    XCTAssertEqualObjects(result.targetId, give.targetId);
    XCTAssertEqual(result.isTop, give.isTop);
    XCTAssertEqual(result.isCallback, give.isCallback);
    XCTAssertEqual(result.isDelete, give.isDelete);
    XCTAssertEqual(result.isGroup, give.isGroup);
    XCTAssertEqualObjects(result.memberLevel, give.memberLevel);
    XCTAssertEqual(result.memberType, give.memberType);
    XCTAssertEqualObjects(result.memberImg, give.memberImg);
    XCTAssertEqualObjects(result.draft, give.draft);
    XCTAssertEqual(result.unsendTag, give.unsendTag);
    XCTAssertEqual(result.newMsgCount, give.newMsgCount);
    XCTAssertEqual(result.timestamp, give.timestamp);
    XCTAssertEqual(result.is_self, give.is_self);
    XCTAssertEqualObjects(result.area, give.area);
    XCTAssertEqualObjects(result.remarkName, give.remarkName);
}

+ (FMDatabaseQueue*)memoryQueue {
    FMDatabaseQueue* queue = [[FMDatabaseQueue alloc] initWithPath:@":memory:"];
    [queue inDatabase:^(FMDatabase* db) {
        [db executeStatements:kCreateTable];
    }];
    return queue;
}

+ (FMDatabaseQueue*)queue {
    NSString* path = [[NSBundle bundleForClass:self] pathForResource:@"ConversationTest_1000" ofType:@"db"];
    NSLog(@"%@", path);
    FMDatabaseQueue* queue = [[FMDatabaseQueue alloc] initWithPath:path];
    return queue;
}

//@property(nonatomic, copy) NSString *name;
//@property(nonatomic, copy) NSString *avatarURL;
//@property(nonatomic, copy) NSString *content;
//@property(nonatomic, copy) NSString *msguuid;
//@property(nonatomic, assign) int64_t uid;
//@property (nonatomic, copy) NSString *targetId;
//@property(nonatomic, assign) BOOL isTop;
//@property(nonatomic, assign) BOOL isCallback;
//@property(nonatomic, assign) BOOL isDelete;
//@property(nonatomic, assign) BOOL isGroup;
//@property(nonatomic, copy) NSString *memberLevel;
//@property(nonatomic, assign) NSInteger memberType;
//@property(nonatomic, copy) NSString *memberImg;
//@property(nonatomic, copy) NSString *draft;
//@property(nonatomic, assign) BOOL unsendTag;
//@property(nonatomic) int newMsgCount;
//@property(nonatomic) NSInteger timestamp;
//@property(nonatomic, assign) BOOL is_self;
//@property(nonatomic, copy) NSString *area;
//@property(nonatomic, copy) NSString *remarkName;

+ (Conversation*)randomConversation {
    Conversation* conversation = [[Conversation alloc] init];
    conversation.name = randomString();
    conversation.avatarURL = randomString();
    conversation.content = randomString();
    conversation.msguuid = randomString();
    conversation.uid = randomInt64();
    conversation.targetId = randomString();
    conversation.isTop = randomBool();
    conversation.isCallback = randomBool();
    conversation.isDelete = randomBool();
    conversation.isGroup = randomBool();
    conversation.memberLevel = randomString();
    conversation.memberType = randomInteger();
    conversation.memberImg = randomString();
    conversation.draft = randomString();
    conversation.unsendTag = randomBool();
    conversation.newMsgCount = randomInt();
    conversation.timestamp = randomInteger();
    conversation.is_self = randomBool();
    conversation.area = randomString();
    conversation.remarkName = randomString();
    return conversation;
}

@end
